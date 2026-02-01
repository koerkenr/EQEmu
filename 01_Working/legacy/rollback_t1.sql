-- ============================================================================
-- Rollback Tier 1 Generation
-- ============================================================================
-- This will delete all T1 variants and mappings
-- Run this before regenerating T1 with the new selective injection logic
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'ROLLING BACK TIER 1 GENERATION...' AS '';
SELECT '============================================================================' AS '';

-- Show what will be deleted
SELECT 
    'Items to delete' AS action,
    COUNT(*) AS count
FROM items
WHERE id >= 10000000 AND id < 20000000;

SELECT 
    'Mappings to delete' AS action,
    COUNT(*) AS count
FROM item_tier_map
WHERE tier_code = 1;

-- Confirm before proceeding
SELECT '⚠ WARNING: About to delete all T1 variants!' AS '';
SELECT 'Press F9 to continue or stop here to cancel' AS '';

-- Delete T1 item variants
DELETE FROM items 
WHERE id >= 10000000 AND id < 20000000;

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T1 item variants') AS status;

-- Delete T1 mappings
DELETE FROM item_tier_map 
WHERE tier_code = 1;

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' T1 mappings') AS status;

-- Verify cleanup
SELECT 
    'Remaining T1 items' AS check_name,
    COUNT(*) AS count
FROM items
WHERE id >= 10000000 AND id < 20000000;

SELECT 
    'Remaining T1 mappings' AS check_name,
    COUNT(*) AS count
FROM item_tier_map
WHERE tier_code = 1;

SELECT '============================================================================' AS '';
SELECT '✓ ROLLBACK COMPLETE - Ready to regenerate T1' AS '';
SELECT '============================================================================' AS '';
