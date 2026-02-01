-- ============================================================================
-- Rollback Tier 1 (Enhanced) Items - ALL OFFSETS
-- ============================================================================
-- This script safely deletes all T1 item variants and their mappings
-- Works for both 10M offset (old) and 300K offset (new)
-- Use this before regenerating T1 with updated logic
-- ============================================================================

SET @start_time = NOW();

SELECT '============================================================================' AS '';
SELECT 'ROLLING BACK TIER 1 (Enhanced) ITEMS...' AS '';
SELECT '============================================================================' AS '';

-- Show what will be deleted
SELECT
    'T1 items to delete' AS action,
    COUNT(*) AS count
FROM item_tier_map
WHERE tier_code = 1;

-- Show ID ranges being deleted
SELECT
    'ID ranges' AS info,
    MIN(variant_item_id) AS min_id,
    MAX(variant_item_id) AS max_id,
    COUNT(*) AS count
FROM item_tier_map
WHERE tier_code = 1;

-- Delete T1 items from items table (handles both 10M and 300K offsets)
DELETE FROM items
WHERE id IN (
    SELECT variant_item_id
    FROM item_tier_map
    WHERE tier_code = 1
);

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T1 items from items table') AS status;

-- Delete T1 mappings from item_tier_map
DELETE FROM item_tier_map
WHERE tier_code = 1;

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T1 mappings from item_tier_map') AS status;

-- Verify cleanup
SELECT
    'Verification' AS check_name,
    COUNT(*) AS remaining_t1_items
FROM item_tier_map
WHERE tier_code = 1;

-- Check both ID ranges
SELECT
    'Old 10M range check' AS check_name,
    COUNT(*) AS items_remaining
FROM items
WHERE id >= 10000000 AND id < 20000000
UNION ALL
SELECT
    'New 300K range check' AS check_name,
    COUNT(*) AS items_remaining
FROM items
WHERE id >= 300000 AND id < 500000;

SELECT '============================================================================' AS '';
SELECT '✓ TIER 1 ROLLBACK COMPLETE' AS '';
SELECT CONCAT('Execution time: ', TIMESTAMPDIFF(SECOND, @start_time, NOW()), ' seconds') AS timing;
SELECT '============================================================================' AS '';
SELECT 'Ready to regenerate T1 with item_tier_generation_T1_SELECTIVE_FINAL.sql' AS next_step;
