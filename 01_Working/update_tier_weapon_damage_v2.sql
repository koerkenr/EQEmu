-- Update weapon damage for tier items (Improved Version)
-- T1: +5% damage (min +1) from base
-- T2: +8% damage (min +2) from T1
-- T3: +12% damage (min +3) from T2
--
-- Improvements:
-- - Cleaner GREATEST formula (no double-counting)
-- - Better safety checks (delay > 0 AND damage > 0)
-- - Idempotent (safe to rerun)
-- - Chains properly (T2 from T1, T3 from T2)

-- Update T1 weapons: base + max(5% of base, 1)
UPDATE items i
JOIN item_tier_map itm ON itm.variant_item_id = i.id AND itm.tier_code = 1
JOIN items base ON base.id = itm.base_item_id
SET i.damage = 
  CASE WHEN base.delay > 0 AND base.damage > 0
       THEN base.damage + GREATEST(FLOOR(base.damage * 0.05), 1)
       ELSE i.damage
  END
WHERE base.delay > 0 AND base.damage > 0;

SELECT CONCAT('Updated ', ROW_COUNT(), ' T1 weapons') AS result;

-- Update T2 weapons: T1 + max(8% of T1, 2)
UPDATE items i
JOIN item_tier_map itm ON itm.variant_item_id = i.id AND itm.tier_code = 2
JOIN item_tier_map itm_t1 ON itm_t1.base_item_id = itm.base_item_id AND itm_t1.tier_code = 1
JOIN items t1 ON t1.id = itm_t1.variant_item_id
SET i.damage = 
  CASE WHEN t1.delay > 0 AND t1.damage > 0
       THEN t1.damage + GREATEST(FLOOR(t1.damage * 0.08), 2)
       ELSE i.damage
  END
WHERE t1.delay > 0 AND t1.damage > 0;

SELECT CONCAT('Updated ', ROW_COUNT(), ' T2 weapons') AS result;

-- Update T3 weapons: T2 + max(12% of T2, 3)
UPDATE items i
JOIN item_tier_map itm ON itm.variant_item_id = i.id AND itm.tier_code = 3
JOIN item_tier_map itm_t2 ON itm_t2.base_item_id = itm.base_item_id AND itm_t2.tier_code = 2
JOIN items t2 ON t2.id = itm_t2.variant_item_id
SET i.damage = 
  CASE WHEN t2.delay > 0 AND t2.damage > 0
       THEN t2.damage + GREATEST(FLOOR(t2.damage * 0.12), 3)
       ELSE i.damage
  END
WHERE t2.delay > 0 AND t2.damage > 0;

SELECT CONCAT('Updated ', ROW_COUNT(), ' T3 weapons') AS result;

-- Show damage progression examples (top 20 by base damage)
SELECT 
    base.id AS base_id,
    base.Name AS base_name,
    base.damage AS base_dmg,
    base.delay AS delay,
    ROUND(base.damage / (base.delay / 10), 2) AS base_dps,
    t1.id AS t1_id,
    t1.damage AS t1_dmg,
    ROUND(t1.damage / (t1.delay / 10), 2) AS t1_dps,
    t2.id AS t2_id,
    t2.damage AS t2_dmg,
    ROUND(t2.damage / (t2.delay / 10), 2) AS t2_dps,
    t3.id AS t3_id,
    t3.damage AS t3_dmg,
    ROUND(t3.damage / (t3.delay / 10), 2) AS t3_dps,
    CONCAT('+', t1.damage - base.damage) AS t1_gain,
    CONCAT('+', t2.damage - t1.damage) AS t2_gain,
    CONCAT('+', t3.damage - t2.damage) AS t3_gain
FROM items base
JOIN item_tier_map itm1 ON itm1.base_item_id = base.id AND itm1.tier_code = 1
JOIN items t1 ON t1.id = itm1.variant_item_id
LEFT JOIN item_tier_map itm2 ON itm2.base_item_id = base.id AND itm2.tier_code = 2
LEFT JOIN items t2 ON t2.id = itm2.variant_item_id
LEFT JOIN item_tier_map itm3 ON itm3.base_item_id = base.id AND itm3.tier_code = 3
LEFT JOIN items t3 ON t3.id = itm3.variant_item_id
WHERE base.delay > 0 AND base.damage > 0
ORDER BY base.damage DESC
LIMIT 20;

-- Show damage progression examples (low damage weapons)
SELECT 
    base.id AS base_id,
    base.Name AS base_name,
    base.damage AS base_dmg,
    base.delay AS delay,
    t1.damage AS t1_dmg,
    t2.damage AS t2_dmg,
    t3.damage AS t3_dmg,
    CONCAT('+', t1.damage - base.damage) AS t1_gain,
    CONCAT('+', t2.damage - t1.damage) AS t2_gain,
    CONCAT('+', t3.damage - t2.damage) AS t3_gain
FROM items base
JOIN item_tier_map itm1 ON itm1.base_item_id = base.id AND itm1.tier_code = 1
JOIN items t1 ON t1.id = itm1.variant_item_id
LEFT JOIN item_tier_map itm2 ON itm2.base_item_id = base.id AND itm2.tier_code = 2
LEFT JOIN items t2 ON t2.id = itm2.variant_item_id
LEFT JOIN item_tier_map itm3 ON itm3.base_item_id = base.id AND itm3.tier_code = 3
LEFT JOIN items t3 ON t3.id = itm3.variant_item_id
WHERE base.delay > 0 AND base.damage > 0 AND base.damage <= 20
ORDER BY base.damage ASC
LIMIT 20;

-- Summary statistics
SELECT 
    'Damage Scaling Summary' AS info,
    MIN(base.damage) AS min_base_dmg,
    MAX(base.damage) AS max_base_dmg,
    AVG(base.damage) AS avg_base_dmg,
    AVG(t1.damage - base.damage) AS avg_t1_gain,
    AVG(t2.damage - t1.damage) AS avg_t2_gain,
    AVG(t3.damage - t2.damage) AS avg_t3_gain,
    MAX(t3.damage) AS max_t3_dmg
FROM items base
JOIN item_tier_map itm1 ON itm1.base_item_id = base.id AND itm1.tier_code = 1
JOIN items t1 ON t1.id = itm1.variant_item_id
LEFT JOIN item_tier_map itm2 ON itm2.base_item_id = base.id AND itm2.tier_code = 2
LEFT JOIN items t2 ON t2.id = itm2.variant_item_id
LEFT JOIN item_tier_map itm3 ON itm3.base_item_id = base.id AND itm3.tier_code = 3
LEFT JOIN items t3 ON t3.id = itm3.variant_item_id
WHERE base.delay > 0 AND base.damage > 0;
