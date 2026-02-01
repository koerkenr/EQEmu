# global_npc.pl - Tier Loot Randomization System
#
# This script randomly upgrades NPC loot to tier variants on spawn
# Rarity rates:
# - T1 (Enhanced): 20% chance (1 in 5)
# - T2 (Exalted): 2% chance (1 in 50)
# - T3 (Ascendant): 1.33% chance (1 in 75)
#
# Place this file in your quests/global/ directory

sub EVENT_SPAWN {
    # Halloween event handling
    if (quest::is_content_flag_enabled("peq_halloween")) {
        # Exclude mounts and pets
        my $clean_name = $npc->GetCleanName();
        unless ($clean_name =~ /mount/i || $npc->IsPet()) {
            # Soulbinders and Priest of Discord
            if ($clean_name =~ /soulbinder/i || $clean_name =~ /priest of discord/i) {
                my @races = (14, 60, 82, 85);
                $npc->ChangeRace($races[int(rand(@races))]);
                $npc->ChangeSize(6);
                $npc->ChangeTexture(1);
                $npc->ChangeGender(2);
            }

            # Halloween zones: Shadow Haven (202), The Bazaar (150), Plane of Knowledge (151), Guild Lobby (344)
            my %halloween_zones = (202 => 1, 150 => 1, 151 => 1, 344 => 1);
            my %not_allowed_bodytypes = (11 => 1, 60 => 1, 66 => 1, 67 => 1);

            if (exists $halloween_zones{$zone_id} && !exists $not_allowed_bodytypes{$npc->GetBodyType()}) {
                my @races = (14, 60, 82, 85);
                $npc->ChangeRace($races[int(rand(@races))]);
                $npc->ChangeSize(6);
                $npc->ChangeTexture(1);
                $npc->ChangeGender(2);
            }
        }
    }

    # Tier loot randomization
    # Only process if NPC has loot
    return unless $npc->GetLoottableID() > 0;

    # Get NPC's loot table
    my $loottable_id = $npc->GetLoottableID();

    # Query to get all items from this NPC's loot table
    my $query = "
        SELECT DISTINCT lde.item_id
        FROM loottable_entries lte
        JOIN lootdrop_entries lde ON lte.lootdrop_id = lde.lootdrop_id
        WHERE lte.loottable_id = $loottable_id
        AND lde.item_id > 0
    ";

    my $dbh = plugin::GetMysql();
    return unless $dbh;

    my $sth = $dbh->prepare($query);
    $sth->execute();

    my @items_to_upgrade;
    while (my ($item_id) = $sth->fetchrow_array()) {
        push @items_to_upgrade, $item_id if $item_id;
    }
    $sth->finish();

    return unless @items_to_upgrade;

    # For each item, check if tier variants exist and randomly upgrade
    foreach my $base_item_id (@items_to_upgrade) {
        # Check if this item has tier variants
        my $tier_query = "
            SELECT tier_code, variant_item_id
            FROM item_tier_map
            WHERE base_item_id = $base_item_id
            ORDER BY tier_code ASC
        ";

        my $dbh = plugin::GetMysql();
        next unless $dbh;

        my $tier_sth = $dbh->prepare($tier_query);
        $tier_sth->execute();

        my %tier_variants;
        while (my ($tier_code, $variant_id) = $tier_sth->fetchrow_array()) {
            $tier_variants{$tier_code} = $variant_id if $tier_code && $variant_id;
        }
        $tier_sth->finish();

        next unless %tier_variants;

        # Determine which tier to use based on rarity rolls
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

        # If we selected a tier variant, add it to the NPC's loot
        if ($selected_tier > 0) {
            # Add the tier item to NPC's temporary loot
            quest::addloot($selected_item_id, 0, 1, 1);

            # Optional: Log tier loot for debugging
            # quest::debug("NPC " . $npc->GetCleanName() . " (" . $npc->GetNPCTypeID() . ") got T$selected_tier item $selected_item_id (base: $base_item_id)");
        }
    }
}

# Optional: Add a command to test tier loot on a specific NPC
sub EVENT_SAY {
    if ($text =~ /^#testtier$/i && $status >= 200) {
        my $loottable_id = $npc->GetLoottableID();

        if ($loottable_id == 0) {
            quest::say("This NPC has no loot table.");
            return;
        }

        # Get items from loot table
        my $query = "
            SELECT DISTINCT lde.item_id, i.Name
            FROM loottable_entries lte
            JOIN lootdrop_entries lde ON lte.lootdrop_id = lde.lootdrop_id
            JOIN items i ON lde.item_id = i.id
            WHERE lte.loottable_id = $loottable_id
            AND lde.item_id > 0
            LIMIT 10
        ";

        my $dbh = plugin::GetMysql();
        return unless $dbh;

        my $sth = $dbh->prepare($query);
        $sth->execute();

        quest::say("Loot table $loottable_id items with tier variants:");

        my $count = 0;
        while (my ($item_id, $item_name) = $sth->fetchrow_array()) {
            # Check for tier variants
            my $tier_query = "
                SELECT COUNT(*)
                FROM item_tier_map
                WHERE base_item_id = $item_id
            ";

            my $tier_sth = $dbh->prepare($tier_query);
            $tier_sth->execute();

            if (my ($tier_count) = $tier_sth->fetchrow_array()) {
                if ($tier_count > 0) {
                    quest::say("- [$item_id] $item_name ($tier_count tiers)");
                    $count++;
                }
            }
            $tier_sth->finish();
        }
        $sth->finish();

        if ($count == 0) {
            quest::say("No items with tier variants found in this NPC's loot table.");
        }
    }
}

1; # Required for Perl modules
