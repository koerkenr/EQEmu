# global_player.pl - Player commands for tier loot testing
#
# Drop in: quests/global/global_player.pl

use strict;
use warnings;

our ($client, $text, $status);

sub _get_dbh {
  return plugin::LoadMysql() if defined &plugin::LoadMysql;
  return undef;
}

sub EVENT_SAY {
  # #testtier command - check targeted NPC's loot for tier variants
  if ($text =~ /^#testtier$/i && $status >= 200) {
    
    my $target = $client->GetTarget();
    
    unless ($target && $target->IsNPC()) {
      $client->Message(15, "You must target an NPC to use this command.");
      return;
    }
    
    my $npc = $target->CastToNPC();
    my $loottable_id = $npc->GetLoottableID();
    
    if ($loottable_id == 0) {
      $client->Message(15, "This NPC has no loot table.");
      return;
    }
    
    my $dbh = _get_dbh();
    unless ($dbh) {
      $client->Message(13, "Error: DB handle unavailable.");
      return;
    }
    
    my $sql = q{
      SELECT
        lde.item_id AS base_item_id,
        i.Name AS item_name,
        MAX(CASE WHEN itm.tier_code = 1 THEN itm.variant_item_id END) AS t1,
        MAX(CASE WHEN itm.tier_code = 2 THEN itm.variant_item_id END) AS t2,
        MAX(CASE WHEN itm.tier_code = 3 THEN itm.variant_item_id END) AS t3
      FROM loottable_entries lte
      JOIN lootdrop_entries lde
        ON lte.lootdrop_id = lde.lootdrop_id
      JOIN items i
        ON i.id = lde.item_id
      JOIN item_tier_map itm
        ON itm.base_item_id = lde.item_id
      WHERE lte.loottable_id = ?
        AND lde.item_id > 0
      GROUP BY lde.item_id, i.Name
      LIMIT 20
    };
    
    my $sth = $dbh->prepare($sql);
    $sth->execute($loottable_id);
    
    $client->Message(15, "=== Tier Loot Test ===");
    $client->Message(15, "NPC: " . $npc->GetCleanName() . " (ID: " . $npc->GetNPCTypeID() . ")");
    $client->Message(15, "Loottable: $loottable_id");
    $client->Message(15, "Items with tier variants (showing up to 20):");
    
    my $found = 0;
    while (my $r = $sth->fetchrow_hashref()) {
      my @tiers;
      push @tiers, "T1=$r->{t1}" if $r->{t1};
      push @tiers, "T2=$r->{t2}" if $r->{t2};
      push @tiers, "T3=$r->{t3}" if $r->{t3};
      next unless @tiers;
      
      $found++;
      $client->Message(15, " - [$r->{base_item_id}] $r->{item_name} :: " . join(", ", @tiers));
    }
    
    $sth->finish();
    
    if (!$found) {
      $client->Message(13, "No tier-variant items found on this NPC's loottable.");
      $client->Message(13, "This NPC will not drop tier items.");
    } else {
      $client->Message(10, "Found $found items with tier variants!");
      $client->Message(10, "Kill this NPC to test tier drops (20% T1, 2% T2, 1.33% T3)");
    }
  }
}

1;
