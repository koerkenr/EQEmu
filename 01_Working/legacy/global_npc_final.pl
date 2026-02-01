# global_npc.pl - Tier Loot Randomization + Halloween cosmetics
#
# Uses temporary loot table modification approach

use strict;
use warnings;

our (
  $npc,
  $client,
  $zoneid,
  $text,
  $status,
  $entity_list
);

sub _get_dbh {
  return plugin::LoadMysql() if defined &plugin::LoadMysql;
  return undef;
}

sub EVENT_SPAWN {

  # -----------------------------
  # Halloween event handling
  # -----------------------------
  if (defined &quest::is_content_flag_enabled && quest::is_content_flag_enabled("peq_halloween")) {

    my $clean_name = $npc->GetCleanName();

    my $is_pet = 0;
    $is_pet = $npc->IsPet() if ($npc && $npc->can('IsPet'));

    unless ($clean_name =~ /mount/i || $is_pet) {

      if ($clean_name =~ /soulbinder/i || $clean_name =~ /priest of discord/i) {
        my @races = (14, 60, 82, 85);
        $npc->ChangeRace($races[int(rand(@races))]);
        $npc->ChangeSize(6);
        $npc->ChangeTexture(1);
        $npc->ChangeGender(2);
      }

      my %halloween_zones       = (202 => 1, 150 => 1, 151 => 1, 344 => 1);
      my %not_allowed_bodytypes = (11  => 1, 60  => 1, 66  => 1, 67  => 1);

      if (exists $halloween_zones{$zoneid} && !exists $not_allowed_bodytypes{$npc->GetBodyType()}) {
        my @races = (14, 60, 82, 85);
        $npc->ChangeRace($races[int(rand(@races))]);
        $npc->ChangeSize(6);
        $npc->ChangeTexture(1);
        $npc->ChangeGender(2);
      }
    }
  }

  # -----------------------------
  # Tier loot randomization
  # -----------------------------

  return unless ($npc && $npc->GetLoottableID() && $npc->GetLoottableID() > 0);

  my $loottable_id = $npc->GetLoottableID();

  my $dbh = _get_dbh();
  return unless $dbh;

  # Get all lootdrop entries that have tier variants
  my $sql = q{
    SELECT DISTINCT
      lte.lootdrop_id,
      lde.lootdrop_entry_id,
      lde.item_id AS base_item_id,
      MAX(CASE WHEN itm.tier_code = 1 THEN itm.variant_item_id END) AS t1,
      MAX(CASE WHEN itm.tier_code = 2 THEN itm.variant_item_id END) AS t2,
      MAX(CASE WHEN itm.tier_code = 3 THEN itm.variant_item_id END) AS t3
    FROM loottable_entries lte
    JOIN lootdrop_entries lde
      ON lte.lootdrop_id = lde.lootdrop_id
    JOIN item_tier_map itm
      ON itm.base_item_id = lde.item_id
    WHERE lte.loottable_id = ?
      AND lde.item_id > 0
    GROUP BY lte.lootdrop_id, lde.lootdrop_entry_id, lde.item_id
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute($loottable_id);

  my @modifications;
  
  while (my $row = $sth->fetchrow_hashref()) {
    my $base_item_id = $row->{base_item_id};
    my $entry_id = $row->{lootdrop_entry_id};
    next unless $base_item_id && $entry_id;

    my $selected_tier = 0;
    my $selected_item_id = $base_item_id;

    # Roll for T3 first (most rare) - 1.33% chance (1 in 75)
    if ($row->{t3} && int(rand(75)) == 0) {
      $selected_tier = 3;
      $selected_item_id = $row->{t3};
    }
    # Roll for T2 - 2% chance (1 in 50)
    elsif ($row->{t2} && int(rand(50)) == 0) {
      $selected_tier = 2;
      $selected_item_id = $row->{t2};
    }
    # Roll for T1 - 20% chance (1 in 5)
    elsif ($row->{t1} && int(rand(5)) == 0) {
      $selected_tier = 1;
      $selected_item_id = $row->{t1};
    }

    # Store modification if tier was selected
    if ($selected_tier > 0 && $selected_item_id != $base_item_id) {
      push @modifications, {
        entry_id => $entry_id,
        base_id => $base_item_id,
        tier_id => $selected_item_id,
        tier => $selected_tier
      };
      quest::debug("TierLoot: NPC=".$npc->GetCleanName()." entry=$entry_id base=$base_item_id -> T$selected_tier item=$selected_item_id");
    }
  }

  $sth->finish();
  
  # Apply modifications to loot table temporarily
  if (@modifications) {
    foreach my $mod (@modifications) {
      # Update the lootdrop_entry to use tier item instead of base item
      my $update_sql = "UPDATE lootdrop_entries SET item_id = ? WHERE lootdrop_entry_id = ?";
      my $update_sth = $dbh->prepare($update_sql);
      $update_sth->execute($mod->{tier_id}, $mod->{entry_id});
      $update_sth->finish();
    }
    
    # Store original values to restore later
    my $restore_data = join(",", map { "$_->{entry_id}:$_->{base_id}" } @modifications);
    $npc->SetEntityVariable("tier_restore", $restore_data);
  }
}

sub EVENT_DEATH {
  # Restore original loot table entries after death
  my $restore_data = $npc->GetEntityVariable("tier_restore");
  return unless $restore_data;
  
  my $dbh = _get_dbh();
  return unless $dbh;
  
  foreach my $pair (split(/,/, $restore_data)) {
    my ($entry_id, $base_id) = split(/:/, $pair);
    next unless $entry_id && $base_id;
    
    # Restore original item_id
    my $restore_sql = "UPDATE lootdrop_entries SET item_id = ? WHERE lootdrop_entry_id = ?";
    my $restore_sth = $dbh->prepare($restore_sql);
    $restore_sth->execute($base_id, $entry_id);
    $restore_sth->finish();
  }
  
  quest::debug("TierLoot: Restored original loot table entries");
}

1;
