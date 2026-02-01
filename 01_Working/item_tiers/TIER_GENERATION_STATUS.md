# Item Tier Generation - Status & Fixes

## Critical Bugs Fixed in `item_tier_generation_FIXED.sql`

### ✅ **1. Class Bitmask Logic (CRITICAL)**
**Problem**: Original used `(i.classes & 1) > 0` which only checks WAR class
**Fix**: Defined proper role masks:
```sql
SET @CLS_TANK = 1 + 4 + 16;  -- WAR, PAL, SHD
SET @CLS_MELEE_DPS = 8 + 64 + 128 + 256 + 16384 + 32768;
SET @CLS_INT_CASTER = 1024 + 2048 + 4096 + 8192;
SET @CLS_WIS_CASTER = 2 + 32 + 512;
```

### ✅ **2. Power Score Performance (CRITICAL)**
**Problem**: Called `calculate_power_score()` 10+ times per row in T2/T3
**Fix**: Created `item_power_scores` temporary table with pre-calculated scores and role flags

### ✅ **3. Gear/Bag Separation**
**Problem**: Mixed gear and bag generation in same INSERT with conditional logic
**Fix**: Separate INSERTs for gear and bags with appropriate field handling

### ✅ **4. Collision Checks**
**Problem**: No validation that variant IDs don't already exist
**Fix**: Added explicit collision checks before each tier generation

### ✅ **5. Generation Run Tracking**
**Problem**: No way to identify or rollback specific generation runs
**Fix**: Added `generation_run_id` column with timestamp-based tracking

### ✅ **6. Stat Injection Gating**
**Problem**: Injected stats on all zero-stat items indiscriminately
**Fix**: Only inject stats if item already has some stats OR has AC (is actual gear)

## Issues Still Need Fixing (T2/T3 generation)

### ⚠️ **7. T2 Heroics Don't Increment**
**Problem**: Lines like `COALESCE(i.heroic_str,0)` without `+1`
**Status**: Need to add `+ 1` to all T2 heroic awards

### ⚠️ **8. T3 Caps Same as T2**
**Problem**: Regen capped at 5 in both T2 and T3, shielding at 10 in both
**Status**: Need progressive caps (T2: 5, T3: 7 for regen; T2: 10, T3: 15 for shielding)

### ⚠️ **9. QA Queries Reference tier_code=0**
**Problem**: Queries look for tier_code=0 but we only store 1/2/3
**Status**: Need to fix QA section to not reference non-existent tier 0

### ⚠️ **10. Spell Damage Gating**
**Problem**: Spell damage can appear on non-caster items due to injection floors
**Status**: Need to gate spell damage to items with existing mana OR caster class masks

## Files Created

1. **`item_tier_generation.sql`** - Original (has bugs, don't use)
2. **`item_tier_generation_part2.sql`** - Original T2/T3 (has bugs, don't use)
3. **`item_tier_generation_FIXED.sql`** - Corrected through T1 ✅

## Still TODO

- [ ] Create `item_tier_generation_FIXED_part2.sql` with corrected T2/T3 generation
- [ ] Fix T2 heroics increment logic
- [ ] Make T3 caps progressive
- [ ] Fix spell damage gating
- [ ] Fix QA queries
- [ ] Test on small dataset

## Execution Plan (Once Complete)

1. **Backup database**: `mysqldump -u root -p eqemu > backup_pre_tiers.sql`
2. **Execute FIXED.sql**: Generates T1 for all items
3. **Execute FIXED_part2.sql**: Generates T2 and T3
4. **Review QA output**: Verify integrity checks pass
5. **Test in-game**: Spawn sample items from each tier
6. **Add to loot tables**: Separate script (not yet created)

## Recommendations from Review

### High Priority
- [x] Fix class bitmasks
- [x] Cache power scores
- [x] Split gear/bag generation
- [x] Add collision checks
- [ ] Fix T2 heroics
- [ ] Make caps progressive
- [ ] Fix QA queries

### Medium Priority
- [x] Add generation_run_id
- [x] Gate stat injection
- [ ] Gate spell damage to casters
- [ ] Add itemclass distribution sampling

### Nice to Have
- [ ] Store tier_code=0 mappings for base items (makes QA easier)
- [ ] Add rollback script by generation_run_id
- [ ] Create loot table integration script
- [ ] Add power score percentile thresholds tuning

## Notes

- Original spec multipliers are good, implementation had bugs
- Solo/duo context means aggressive T3 multipliers (×1.95 HP) are appropriate
- Base item power naturally gates tier power (design is sound)
- No blacklists needed - FBSS T3 won't break game in solo/duo context

