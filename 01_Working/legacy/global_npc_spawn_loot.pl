# global_npc.pl - Tier Loot Randomization + Halloween cosmetics
#
# Modifies NPC loot directly at spawn time

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
  # Tier loot randomization - Check what NPC actually has and upgrade it
  # -----------------------------

  return unless $npc;

  my $dbh = _get_dbh();
  return unless $dbh;

  # Get the NPC's loot list (items it actually spawned with)
  # GetLootList() returns a hash reference with item data
  my $loot_list = $npc->GetLootList();
  return unless $loot_list && ref($loot_list) eq 'HASH';

  # Extract item IDs from loot list hash
  my @item_ids = keys %{$loot_list};
  return unless @item_ids;

  # For each item the NPC has, check if it has tier variants
  foreach my $base_item_id (@item_ids) {
    next unless $base_item_id && $base_item_id > 0 && $base_item_id =~ /^\d+$/;

    # Query for tier variants of this specific item
    my $sql = q{
      SELECT
        tier_code,
        variant_item_id
      FROM item_tier_map
      WHERE base_item_id = ?
      ORDER BY tier_code ASC
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute($base_item_id);

    my %tier_variants;
    while (my ($tier_code, $variant_id) = $sth->fetchrow_array()) {
      $tier_variants{$tier_code} = $variant_id if $tier_code && $variant_id;
    }
    $sth->finish();

    next unless %tier_variants;

    # Roll for tier upgrade
    my $selected_tier = 0;
    my $selected_item_id = $base_item_id;

    # Roll for T3 first (most rare) - 1.33% chance (1 in 75)
    if (exists $tier_variants{3} && int(rand(75)) == 0) {
      $selected_tier = 3;
      $selected_item_id = $tier_variants{3};
    }
    # Roll for T2 - 2% chance (1 in 50)
    elsif (exists $tier_variants{2} && int(rand(50)) == 0) {
      $selected_tier = 2;
      $selected_item_id = $tier_variants{2};
    }
    # Roll for T1 - 20% chance (1 in 5)
    elsif (exists $tier_variants{1} && int(rand(5)) == 0) {
      $selected_tier = 1;
      $selected_item_id = $tier_variants{1};
    }

    # Replace item if tier was selected
    if ($selected_tier > 0 && $selected_item_id != $base_item_id) {
      # Remove base item from NPC's loot
      $npc->RemoveItem($base_item_id);

      # Add tier item to NPC's loot
      $npc->AddItem($selected_item_id, 1);

      quest::debug("TierLoot: NPC=".$npc->GetCleanName()." (".$npc->GetNPCTypeID().") replaced base=$base_item_id with T$selected_tier item=$selected_item_id");
    }
  }
}

1;
