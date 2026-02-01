# global_npc.pl - Tier Loot Randomization + Halloween cosmetics
#
# Drop in: quests/global/global_npc.pl   (or quests/global_npc.pl depending on your setup)
#
# Tier randomization:
# - T1 (Enhanced): 20%  (1 in 5)
# - T2 (Exalted):  2%   (1 in 50)
# - T3 (Ascendant):1.33%(1 in 75)

use strict;
use warnings;

# EQEmu-provided globals (required when using 'use strict')
our (
  $npc,
  $client,
  $zoneid,
  $text,
  $status,
  $timer,
  $popupid
);


# -----------------------------
# Helpers
# -----------------------------

sub _get_dbh {
  return plugin::LoadMysql() if defined &plugin::LoadMysql;
  return undef;
}

sub _add_loot_always {
  my ($item_id) = @_;
  return unless $item_id;

  # Try plugin::AddLoot first
  if (defined &plugin::AddLoot) {
    plugin::AddLoot(1, 10000, $item_id);  # 100% chance
    return;
  }

  # Fallback: native NPC method (charges 1)
  if ($npc && $npc->can('AddItem')) {
    $npc->AddItem($item_id, 1);
    return;
  }
}

sub EVENT_SPAWN {

  # -----------------------------
  # Halloween event handling
  # -----------------------------
  if (defined &quest::is_content_flag_enabled && quest::is_content_flag_enabled("peq_halloween")) {

    my $clean_name = $npc->GetCleanName();

    # Exclude mounts and pets
    my $is_pet = 0;
    $is_pet = $npc->IsPet() if ($npc && $npc->can('IsPet'));

    unless ($clean_name =~ /mount/i || $is_pet) {

      # Soulbinders and Priest of Discord
      if ($clean_name =~ /soulbinder/i || $clean_name =~ /priest of discord/i) {
        my @races = (14, 60, 82, 85);
        $npc->ChangeRace($races[int(rand(@races))]);
        $npc->ChangeSize(6);
        $npc->ChangeTexture(1);
        $npc->ChangeGender(2);
      }

      # Halloween zones: Shadow Haven (202), The Bazaar (150), Plane of Knowledge (151), Guild Lobby (344)
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
  # Store tier replacements in NPC entity variable for use in EVENT_DEATH

  # Only process if NPC has loot
  return unless ($npc && $npc->GetLoottableID() && $npc->GetLoottableID() > 0);

  my $loottable_id = $npc->GetLoottableID();

  my $dbh = _get_dbh();
  return unless $dbh;

  # One query to get all base items on this loottable that have tier variants
  my $sql = q{
    SELECT
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
    GROUP BY lde.item_id
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute($loottable_id);

  my %tier_replacements;

  while (my $row = $sth->fetchrow_hashref()) {
    my $base_item_id = $row->{base_item_id};
    next unless $base_item_id;

    # Determine which tier to use based on rarity rolls
    my $selected_tier    = 0;
    my $selected_item_id = $base_item_id;

    # Roll for T3 first (most rare) - 1.33% chance (1 in 75)
    if ($row->{t3} && int(rand(75)) == 0) {
      $selected_tier    = 3;
      $selected_item_id = $row->{t3};
    }
    # Roll for T2 - 2% chance (1 in 50)
    elsif ($row->{t2} && int(rand(50)) == 0) {
      $selected_tier    = 2;
      $selected_item_id = $row->{t2};
    }
    # Roll for T1 - 20% chance (1 in 5)
    elsif ($row->{t1} && int(rand(5)) == 0) {
      $selected_tier    = 1;
      $selected_item_id = $row->{t1};
    }

    # Store replacement if tier was selected
    if ($selected_tier > 0 && $selected_item_id != $base_item_id) {
      $tier_replacements{$base_item_id} = $selected_item_id;
      quest::debug("TierLoot: NPC=".$npc->GetCleanName()." (".$npc->GetNPCTypeID().") will replace base=$base_item_id with T$selected_tier item=$selected_item_id");
    }
  }

  $sth->finish();

  # Store replacements in NPC entity variable for EVENT_DEATH
  if (%tier_replacements) {
    $npc->SetEntityVariable("tier_replacements", join(",", map { "$_:$tier_replacements{$_}" } keys %tier_replacements));
  }
}

sub EVENT_DEATH {
  # Replace base items with tier variants in the corpse
  my $tier_data = $npc->GetEntityVariable("tier_replacements");
  return unless $tier_data;

  my %replacements;
  foreach my $pair (split(/,/, $tier_data)) {
    my ($base, $tier) = split(/:/, $pair);
    $replacements{$base} = $tier if $base && $tier;
  }

  return unless %replacements;

  # Get the corpse
  my $corpse = $entity_list->GetCorpseByID($npc->GetID());
  return unless $corpse;

  # Replace items in corpse
  foreach my $base_id (keys %replacements) {
    my $tier_id = $replacements{$base_id};

    # Remove base item and add tier item
    if ($corpse->HasItem($base_id)) {
      $corpse->RemoveItem($base_id);
      $corpse->AddItem($tier_id, 1);
      quest::debug("TierLoot: Replaced item $base_id with $tier_id in corpse");
    }
  }
}

# Test command - say "testtier" to an NPC (not #testtier)
sub EVENT_SAY {
  if ($text =~ /testtier/i) {

    return unless ($npc && $npc->GetLoottableID() && $npc->GetLoottableID() > 0);
    my $loottable_id = $npc->GetLoottableID();

    my $dbh = _get_dbh();
    unless ($dbh) {
      quest::say("DB handle unavailable.");
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
      LIMIT 15
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($loottable_id);

    quest::say("Loottable $loottable_id items with tier variants (showing up to 15):");

    my $found = 0;
    while (my $r = $sth->fetchrow_hashref()) {
      my @tiers;
      push @tiers, "T1=$r->{t1}" if $r->{t1};
      push @tiers, "T2=$r->{t2}" if $r->{t2};
      push @tiers, "T3=$r->{t3}" if $r->{t3};
      next unless @tiers;

      $found++;
      quest::say(" - [$r->{base_item_id}] $r->{item_name} :: " . join(", ", @tiers));
    }

    $sth->finish();

    quest::say("No tier-variant items found on this loottable.") if !$found;
  }
}

1;
