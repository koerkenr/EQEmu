-- ============================================================================
-- Rollback Tier 2 (Exalted) and Tier 3 (Ascendant) Items
-- ============================================================================
-- This script safely deletes all T2 and T3 item variants and their mappings
-- Use this if T2/T3 generation fails partway through
-- ============================================================================

SET @start_time = NOW();

SELECT '============================================================================' AS '';
SELECT 'ROLLING BACK TIER 2 AND TIER 3 ITEMS...' AS '';
SELECT '============================================================================' AS '';

-- Show what will be deleted
SELECT 
    tier_code,
    CASE tier_code
        WHEN 2 THEN 'Exalted (T2)'
        WHEN 3 THEN 'Ascendant (T3)'
    END AS tier_name,
    COUNT(*) AS count
FROM item_tier_map
WHERE tier_code IN (2, 3)
GROUP BY tier_code;

-- Delete T3 items first (highest tier)
DELETE FROM items
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 3
);

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T3 items from items table') AS status;

-- Delete T3 mappings
DELETE FROM item_tier_map
WHERE tier_code = 3;

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T3 mappings from item_tier_map') AS status;

-- Delete T2 items
DELETE FROM items
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 2
);

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T2 items from items table') AS status;

-- Delete T2 mappings
DELETE FROM item_tier_map
WHERE tier_code = 2;

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T2 mappings from item_tier_map') AS status;

-- Verify cleanup
SELECT 
    'Verification' AS check_name,
    tier_code,
    COUNT(*) AS remaining_items
FROM item_tier_map
WHERE tier_code IN (2, 3)
GROUP BY tier_code;

-- Check ID ranges
SELECT 
    'T2 ID range (500K-700K)' AS check_name,
    COUNT(*) AS items_remaining
FROM items
WHERE id >= 500000 AND id < 700000
UNION ALL
SELECT 
    'T3 ID range (700K-1M)' AS check_name,
    COUNT(*) AS items_remaining
FROM items
WHERE id >= 700000 AND id < 1000000;

SELECT '============================================================================' AS '';
SELECT '✓ TIER 2 AND TIER 3 ROLLBACK COMPLETE' AS '';
SELECT CONCAT('Execution time: ', TIMESTAMPDIFF(SECOND, @start_time, NOW()), ' seconds') AS timing;
SELECT '============================================================================' AS '';
SELECT 'Ready to regenerate T2/T3 with generate_all_tiers.sql' AS next_step;
