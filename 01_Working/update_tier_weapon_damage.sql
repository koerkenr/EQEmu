-- Update weapon damage for tier items
-- T1: +5% damage (min +1)
-- T2: +8% from T1 (min +2 from T1)
-- T3: +12% from T2 (min +3 from T2)

-- Update T1 weapons (300K offset)
UPDATE items i
JOIN item_tier_map itm ON itm.variant_item_id = i.id AND itm.tier_code = 1
JOIN items base ON base.id = itm.base_item_id
SET i.damage = CASE 
    WHEN i.delay > 0 THEN GREATEST(base.damage + FLOOR(base.damage * 0.05), base.damage + 1)
    ELSE i.damage 
END
WHERE i.delay > 0 AND base.damage > 0;

SELECT CONCAT('Updated ', ROW_COUNT(), ' T1 weapons') AS result;

-- Update T2 weapons (500K offset)
UPDATE items i
JOIN item_tier_map itm ON itm.variant_item_id = i.id AND itm.tier_code = 2
JOIN item_tier_map itm_t1 ON itm_t1.base_item_id = itm.base_item_id AND itm_t1.tier_code = 1
JOIN items t1 ON t1.id = itm_t1.variant_item_id
SET i.damage = CASE 
    WHEN i.delay > 0 THEN GREATEST(t1.damage + FLOOR(t1.damage * 0.08), t1.damage + 2)
    ELSE i.damage 
END
WHERE i.delay > 0 AND t1.damage > 0;

SELECT CONCAT('Updated ', ROW_COUNT(), ' T2 weapons') AS result;

-- Update T3 weapons (700K offset)
UPDATE items i
JOIN item_tier_map itm ON itm.variant_item_id = i.id AND itm.tier_code = 3
JOIN item_tier_map itm_t2 ON itm_t2.base_item_id = itm.base_item_id AND itm_t2.tier_code = 2
JOIN items t2 ON t2.id = itm_t2.variant_item_id
SET i.damage = CASE 
    WHEN i.delay > 0 THEN GREATEST(t2.damage + FLOOR(t2.damage * 0.12), t2.damage + 3)
    ELSE i.damage 
END
WHERE i.delay > 0 AND t2.damage > 0;

SELECT CONCAT('Updated ', ROW_COUNT(), ' T3 weapons') AS result;

-- Show some examples of updated weapons
SELECT 
    base.id AS base_id,
    base.Name AS base_name,
    base.damage AS base_dmg,
    t1.id AS t1_id,
    t1.damage AS t1_dmg,
    t2.id AS t2_id,
    t2.damage AS t2_dmg,
    t3.id AS t3_id,
    t3.damage AS t3_dmg
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
