# Item Tier Generation v2 - Critical Fixes Applied

## All High-Impact Fixes Implemented ✅

### 1. NOT IN → NOT EXISTS (Critical SQL Performance/Correctness)
**Problem**: `NOT IN (subquery)` fails with NULLs and performs poorly
**Fixed**: Both eligibility views now use `NOT EXISTS` pattern
```sql
AND NOT EXISTS (
  SELECT 1 FROM item_tier_map m
  WHERE m.variant_item_id = items.id
)
```

### 2. MEMORY → InnoDB (Stability)
**Problem**: MEMORY tables limited by heap size, can crash on large datasets
**Fixed**: `item_power_scores` now uses InnoDB with proper indexing
```sql
CREATE TEMPORARY TABLE item_power_scores (
  ...
  KEY idx_power (power_score)
) ENGINE=InnoDB;
```

### 3. Manual Continue Gate (Safety)
**Problem**: "Press F9" doesn't actually pause SQL execution
**Fixed**: Added explicit variable gate that requires manual setting
```sql
SET @continue_generation = 0;
-- User must execute: SET @continue_generation = 1; to proceed
```

### 4. ItemClass/ItemType Validation (QA)
**Problem**: No way to verify eligibility filters are correct for your DB
**Fixed**: Added detailed distribution query showing top 200 items by class/type
```sql
SELECT itemclass, itemtype, COUNT(*), sample_items
FROM eligible_gear
GROUP BY itemclass, itemtype;
```

### 5. Injection Logic Improved (Jewelry Support)
**Problem**: `ac > 0` check excluded jewelry (which often has ac=0 but stats)
**Fixed**: Now checks for "real gear" more comprehensively
```sql
CASE WHEN ... AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR stats > 0) THEN 1 ...
```

## Still TODO (For T2/T3 Generation)

### Critical
- [ ] **Expand bag INSERT to full column list** - Current bag generation only copies subset of columns, may fail on NOT NULL constraints
- [ ] **Fix T2 heroics increment** - T2 heroics don't actually add +1 (missing increment)
- [ ] **Progressive caps for T3** - T3 regen/shielding caps same as T2 (no progression)
- [ ] **Gate spell damage to casters** - Spell damage can appear on non-caster items due to injection

### Important
- [ ] **Document tier naming strategy** - Clarify whether Name field changes or relies on item_tier_map
- [ ] **Consider itemclass filter refinement** - Current exclusion list may be DB-specific

## Files

- **`item_tier_generation_FIXED_v2.sql`** - Production-ready through T1 generation ✅
- **`item_tier_generation_FIXED.sql`** - Previous version (superseded)
- **`item_tier_generation.sql`** - Original (has bugs, don't use)
- **`item_tier_generation_part2.sql`** - Original T2/T3 (has bugs, don't use)

## Execution Instructions

1. **Review eligibility**: Execute through the itemclass/itemtype validation query
2. **Verify filters**: Check that eligible items match expectations
3. **Set continue gate**: `SET @continue_generation = 1;`
4. **Execute T1 generation**: Runs gear and bag tier 1 variants
5. **Wait for T2/T3**: Need corrected part 2 script with remaining fixes

## What Makes v2 Production-Ready

✅ No NULL-related NOT IN bugs  
✅ Stable InnoDB temp tables  
✅ Explicit execution gates  
✅ Comprehensive QA validation  
✅ Jewelry-aware injection logic  
✅ Run tracking for rollback  
✅ Collision detection  
✅ Separate gear/bag generation  
✅ Correct class role masks  
✅ Power score caching (no redundant calculations)  

## Next: T2/T3 Generation

Need to create `item_tier_generation_FIXED_v2_part2.sql` with:
- Full-column bag generation
- Corrected T2 heroics (actually increment)
- Progressive T3 caps (regen: 7, shielding: 15)
- Spell damage gated to caster items only
- Fixed QA queries (don't reference tier_code=0)

