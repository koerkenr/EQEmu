# EQEmu Tier Loot System - Quick Start

## What This Is
A complete tier-based loot randomization system that upgrades NPC drops with Enhanced (T1), Exalted (T2), and Ascendant (T3) variants.

## Quick Install

### 1. Database Setup (One Time)
```bash
cd /opt/akk-stack/code/working
mysql -u root -p your_database < item_tier_generation_T1_SELECTIVE_FINAL.sql
mysql -u root -p your_database < generate_all_tiers.sql
mysql -u root -p your_database < generate_t2_t3_bags.sql
mysql -u root -p your_database < add_color_codes_to_tiers.sql
mysql -u root -p your_database < update_tier_weapon_damage.sql
```

### 2. Install Quest Scripts
```bash
cp global_npc_spawn_iterate.pl /path/to/quests/global/global_npc.pl
cp global_player.pl /path/to/quests/global/global_player.pl
```

### 3. Reload Quests In-Game
```
#reloadquest
```

## Testing
1. Target an NPC and type: `#testtier`
2. Kill NPCs and check for color-coded tier items
3. Check server logs for: `TierLoot: NPC X replaced base=Y with T1/T2/T3 item=Z`

## Drop Rates
- **T1 (Blue)**: 20% chance (1 in 5)
- **T2 (Orange)**: 2% chance (1 in 50) - Max 1 per NPC
- **T3 (Gold)**: 1.33% chance (1 in 75) - Max 1 per NPC

## Files
- **TIER_LOOT_PROJECT_STATUS.md** - Complete documentation
- **SQL scripts** - Database generation and maintenance
- **Perl scripts** - Quest handlers for tier loot

## Support
See TIER_LOOT_PROJECT_STATUS.md for full documentation, troubleshooting, and technical details.
