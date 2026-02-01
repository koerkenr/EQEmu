# global_npc.pl - Tier Loot Randomization + Halloween cosmetics
#
# This version uses RemoveLootTable/AddLootTable to swap items before loot generation

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

  # Get all base items that have tier variants
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
      quest::debug("TierLoot SPAWN: NPC=".$npc->GetCleanName()." will replace base=$base_item_id with T$selected_tier item=$selected_item_id");
    }
  }

  $sth->finish();
  
  # Store replacements for EVENT_DEATH
  if (%tier_replacements) {
    $npc->SetEntityVariable("tier_replacements", join(",", map { "$_:$tier_replacements{$_}" } keys %tier_replacements));
  }
}

sub EVENT_DEATH {
  # Get tier replacements
  my $tier_data = $npc->GetEntityVariable("tier_replacements");
  return unless $tier_data;
  
  my %replacements;
  foreach my $pair (split(/,/, $tier_data)) {
    my ($base, $tier) = split(/:/, $pair);
    $replacements{$base} = $tier if $base && $tier;
  }
  
  return unless %replacements;
  
  quest::debug("TierLoot DEATH: Processing " . scalar(keys %replacements) . " tier replacements");
  
  # Try to get corpse and manipulate loot
  # Method 1: Try using quest::addloot to add tier items
  foreach my $base_id (keys %replacements) {
    my $tier_id = $replacements{$base_id};
    
    # Add tier item to corpse (100% chance, 1 charge)
    if (defined &quest::addloot) {
      quest::addloot($tier_id, 0, 1, 1);
      quest::debug("TierLoot DEATH: Added tier item $tier_id to replace base $base_id");
    }
  }
}

1;
