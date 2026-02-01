# How to Add Selective Injection to T1 Generation

You already rolled back T1. Now modify `item_tier_generation_PRODUCTION_fixed.sql` with these changes:

## Change 1: Add is_zero_stat to power score cache (around line 245)

**Find:**
```sql
CREATE TEMPORARY TABLE item_power_scores (
    item_id INT PRIMARY KEY,
    power_score FLOAT,
    is_tank BOOLEAN,
    is_melee_dps BOOLEAN,
    is_int_caster BOOLEAN,
    is_wis_caster BOOLEAN,
    has_mana BOOLEAN,
    KEY idx_power (power_score)
) ENGINE=InnoDB;
```

**Change to:**
```sql
CREATE TEMPORARY TABLE item_power_scores (
    item_id INT PRIMARY KEY,
    power_score FLOAT,
    is_tank BOOLEAN,
    is_melee_dps BOOLEAN,
    is_int_caster BOOLEAN,
    is_wis_caster BOOLEAN,
    has_mana BOOLEAN,
    is_zero_stat BOOLEAN,
    KEY idx_power (power_score),
    KEY idx_zero (is_zero_stat)
) ENGINE=InnoDB;
```

## Change 2: Add is_zero_stat calculation (around line 270)

**Find:**
```sql
    i.mana > 30 AS has_mana
FROM eligible_gear i;
```

**Change to:**
```sql
    i.mana > 30 AS has_mana,
    (i.ac = 0 AND i.hp = 0 AND i.mana = 0 AND i.endur = 0 AND 
     (i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha) = 0) AS is_zero_stat
FROM eligible_gear i;
```

## Change 3: Add breakdown query (around line 280)

**Find:**
```sql
-- Show power score distribution
SELECT
    'Power score percentiles' AS metric,
```

**Add BEFORE it:**
```sql
-- Show breakdown
SELECT 
    'Items with stats' AS category,
    COUNT(*) AS count
FROM item_power_scores WHERE is_zero_stat = 0
UNION ALL
SELECT 
    'Zero-stat items' AS category,
    COUNT(*) AS count
FROM item_power_scores WHERE is_zero_stat = 1;

```

## Change 4: Filter first gear INSERT (around line 470)

**Find the end of the first gear INSERT, around:**
```sql
WHERE NOT EXISTS (
    SELECT 1 FROM item_tier_map
    WHERE base_item_id = i.id AND tier_code = 1
)
AND NOT EXISTS (
    SELECT 1 FROM items WHERE id = i.id + 10000000
);
```

**Change to:**
```sql
WHERE ps.is_zero_stat = 0  -- Only items WITH stats
AND NOT EXISTS (
    SELECT 1 FROM item_tier_map
    WHERE base_item_id = i.id AND tier_code = 1
)
AND NOT EXISTS (
    SELECT 1 FROM items WHERE id = i.id + 10000000
);
```

## Change 5: Add second gear INSERT for zero-stat items

**After the first gear INSERT completes (around line 475), ADD this entire new section:**

```sql
SELECT CONCAT('✓ T1 gear with stats generated: ', ROW_COUNT(), ' items') AS status;

-- ============================================================================
-- Generate T1 for ZERO-STAT items (Selective Injection)
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'GENERATING TIER 1 (Enhanced) - ZERO-STAT ITEMS...' AS '';
SELECT 'Using role-based selective stat injection' AS '';
SELECT '============================================================================' AS '';

-- This INSERT is identical to the first one, but with different stat calculations
-- Copy the entire INSERT structure from above, but replace the stat calculations with:

INSERT INTO items (
    id, minstatus, Name,
    aagi, ac, accuracy, acha, adex, aint, asta, astr, attack,
    cr, dr, fr, mr, pr, svcorruption,
    hp, mana, endur, regen, manaregen, enduranceregen,
    shielding, spellshield, dotshielding,
    damage, delay, strikethrough, avoidance, stunresist,
    heroic_str, heroic_int, heroic_wis, heroic_agi, heroic_dex, heroic_sta, heroic_cha,
    heroic_pr, heroic_dr, heroic_fr, heroic_cr, heroic_mr, heroic_svcorrup,
    spelldmg, healamt, clairvoyance, backstabdmg,
    bagslots, bagwr, bagsize, bagtype,
    proceffect, clickeffect, worneffect, focuseffect, scrolleffect, bardeffect,
    haste,
    -- [copy all remaining column names from first INSERT]
)
SELECT
    i.id + 10000000 AS id,
    i.minstatus,
    i.Name,
    -- SELECTIVE INJECTION STATS:
    CASE WHEN ps.is_melee_dps THEN 1 ELSE 0 END AS aagi,
    CASE WHEN ps.is_tank THEN 3 WHEN ps.is_melee_dps THEN 1 ELSE 0 END AS ac,
    CASE WHEN ps.is_melee_dps OR ps.is_tank THEN 2 ELSE 0 END AS accuracy,
    CASE WHEN ps.is_int_caster OR ps.is_wis_caster THEN 1 ELSE 0 END AS acha,
    CASE WHEN ps.is_melee_dps THEN 1 ELSE 0 END AS adex,
    CASE WHEN ps.is_int_caster THEN 1 ELSE 0 END AS aint,
    1 AS asta,
    CASE WHEN ps.is_tank OR ps.is_melee_dps THEN 1 ELSE 0 END AS astr,
    CASE WHEN ps.is_melee_dps OR ps.is_tank THEN 2 ELSE 0 END AS attack,
    CASE WHEN MOD(i.id, 5) = 0 THEN 2 ELSE 0 END AS cr,
    CASE WHEN MOD(i.id, 5) = 1 THEN 2 ELSE 0 END AS dr,
    CASE WHEN MOD(i.id, 5) = 2 THEN 2 ELSE 0 END AS fr,
    CASE WHEN MOD(i.id, 5) = 3 THEN 2 ELSE 0 END AS mr,
    CASE WHEN MOD(i.id, 5) = 4 THEN 2 ELSE 0 END AS pr,
    0 AS svcorruption,
    CASE WHEN ps.is_tank THEN 15 ELSE 10 END AS hp,
    CASE WHEN ps.is_int_caster OR ps.is_wis_caster THEN 12 ELSE 0 END AS mana,
    CASE WHEN ps.is_tank OR ps.is_melee_dps THEN 10 ELSE 0 END AS endur,
    0 AS regen,
    0 AS manaregen,
    0 AS enduranceregen,
    0 AS shielding,
    0 AS spellshield,
    0 AS dotshielding,
    i.damage,
    i.delay,
    0 AS strikethrough,
    CASE WHEN ps.is_tank THEN 1 ELSE 0 END AS avoidance,
    CASE WHEN ps.is_tank THEN 2 ELSE 0 END AS stunresist,
    0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    -- [copy all remaining fields from first INSERT exactly as-is]
FROM eligible_gear eg
JOIN items i ON eg.id = i.id
JOIN item_power_scores ps ON i.id = ps.item_id
WHERE ps.is_zero_stat = 1  -- Only zero-stat items
AND NOT EXISTS (
    SELECT 1 FROM item_tier_map
    WHERE base_item_id = i.id AND tier_code = 1
)
AND NOT EXISTS (
    SELECT 1 FROM items WHERE id = i.id + 10000000
);

SELECT CONCAT('✓ T1 zero-stat items generated: ', ROW_COUNT(), ' items') AS status;
```

## Easier Alternative

Since this is complex, I can create a complete new file for you. Would you prefer that?

Or you can:
1. Run the original PRODUCTION_fixed.sql to regenerate with multiplicative scaling
2. Then run `update_zero_stat_t1_items.sql` to update zero-stat items after

The UPDATE approach is simpler and achieves the same result!
