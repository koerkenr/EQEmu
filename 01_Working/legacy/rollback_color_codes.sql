-- ============================================================================
-- Rollback Color Codes from Tier Item Names
-- ============================================================================
-- This script removes color codes from tier item names
-- ============================================================================

SET @start_time = NOW();

SELECT '============================================================================' AS '';
SELECT 'REMOVING COLOR CODES FROM TIER ITEM NAMES...' AS '';
SELECT '============================================================================' AS '';

-- Remove color codes from T1 (Enhanced) items
UPDATE items
SET Name = REPLACE(REPLACE(Name, CHAR(0x12), ''), '  ', ' ')
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 1
)
AND Name LIKE CONCAT('%', CHAR(0x12), '%');

SELECT CONCAT('✓ Cleaned ', ROW_COUNT(), ' T1 items') AS status;

-- Remove color codes from T2 (Exalted) items
UPDATE items
SET Name = REPLACE(REPLACE(REPLACE(Name, CHAR(0x1A), ''), CHAR(0x12), ''), '  ', ' ')
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 2
)
AND (Name LIKE CONCAT('%', CHAR(0x1A), '%') OR Name LIKE CONCAT('%', CHAR(0x12), '%'));

SELECT CONCAT('✓ Cleaned ', ROW_COUNT(), ' T2 items') AS status;

-- Remove color codes from T3 (Ascendant) items
UPDATE items
SET Name = REPLACE(REPLACE(REPLACE(Name, CHAR(0x0A), ''), CHAR(0x12), ''), '  ', ' ')
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 3
)
AND (Name LIKE CONCAT('%', CHAR(0x0A), '%') OR Name LIKE CONCAT('%', CHAR(0x12), '%'));

SELECT CONCAT('✓ Cleaned ', ROW_COUNT(), ' T3 items') AS status;

SELECT '============================================================================' AS '';
SELECT '✓ COLOR CODES REMOVED FROM ALL TIERS' AS '';
SELECT CONCAT('Execution time: ', TIMESTAMPDIFF(SECOND, @start_time, NOW()), ' seconds') AS timing;
SELECT '============================================================================' AS '';
