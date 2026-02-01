# global_npc.pl - Tier Loot Randomization + Halloween cosmetics
#
# Uses EVENT_LOOT_ADDED to replace items as they're added to NPC loot

use strict;
use warnings;

our (
  $npc,
  $client,
  $zoneid,
  $text,
  $status,
  $entity_list,
  $item,
  $item_id,
  $item_name,
  $item_charges,
  $augment_one,
  $augment_two,
  $augment_three,
  $augment_four,
  $augment_five,
  $augment_six
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
}

sub EVENT_LOOT_ADDED {
  # This fires every time an item is added to the NPC's loot
  # We can check if the item has tier variants and replace it

  # Prevent infinite loop - if we're adding a tier item, don't process it
  my $processing_tier = $npc->GetEntityVariable("processing_tier_loot");
  return if $processing_tier;

  return unless $item_id && $item_id > 0;

  my $dbh = _get_dbh();
  return unless $dbh;

  # Query for tier variants of this item
  my $sql = q{
    SELECT
      tier_code,
      variant_item_id
    FROM item_tier_map
    WHERE base_item_id = ?
    ORDER BY tier_code ASC
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute($item_id);

  my %tier_variants;
  while (my ($tier_code, $variant_id) = $sth->fetchrow_array()) {
    $tier_variants{$tier_code} = $variant_id if $tier_code && $variant_id;
  }
  $sth->finish();

  return unless %tier_variants;

  # Roll for tier upgrade
  my $selected_tier = 0;
  my $selected_item_id = $item_id;

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
  if ($selected_tier > 0 && $selected_item_id != $item_id) {
    # Set flag to prevent infinite loop
    $npc->SetEntityVariable("processing_tier_loot", "1");

    # Remove the base item that was just added
    $npc->RemoveItem($item_id, 1);

    # Add the tier item instead
    $npc->AddItem(
      $selected_item_id,
      $item_charges || 1,
      1,  # equip_item
      $augment_one || 0,
      $augment_two || 0,
      $augment_three || 0,
      $augment_four || 0,
      $augment_five || 0,
      $augment_six || 0
    );

    # Clear flag
    $npc->SetEntityVariable("processing_tier_loot", "0");

    quest::debug("TierLoot: NPC " . $npc->GetCleanName() . " replaced base=$item_id ($item_name) with T$selected_tier item=$selected_item_id");
  }
}

1;
