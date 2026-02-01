-- ============================================================================
-- Add Color Codes to Existing Tier Item Names
-- ============================================================================
-- This script updates existing tier items to add color codes without regenerating
-- T1 (Enhanced): Blue - CHAR(0x12)
-- T2 (Exalted): Orange - CHAR(0x1A)
-- T3 (Ascendant): Gold - CHAR(0x0A)
-- ============================================================================

SET @start_time = NOW();

SELECT '============================================================================' AS '';
SELECT 'ADDING COLOR CODES TO TIER ITEM NAMES...' AS '';
SELECT '============================================================================' AS '';

-- Show what will be updated
SELECT 
    tier_code,
    CASE tier_code
        WHEN 1 THEN 'Enhanced (T1) - Blue'
        WHEN 2 THEN 'Exalted (T2) - Orange'
        WHEN 3 THEN 'Ascendant (T3) - Gold'
    END AS tier_name,
    COUNT(*) AS item_count
FROM item_tier_map
WHERE tier_code IN (1, 2, 3)
GROUP BY tier_code;

-- Update T1 (Enhanced) items to blue
UPDATE items
SET Name = CONCAT(
    REPLACE(Name, ' (Enhanced)', ''),
    ' ',
    CHAR(0x12),
    '(Enhanced)',
    CHAR(0x12)
)
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 1
)
AND Name LIKE '%(Enhanced)%'
AND Name NOT LIKE CONCAT('%', CHAR(0x12), '%');

SELECT CONCAT('✓ Updated ', ROW_COUNT(), ' T1 items to blue (Enhanced)') AS status;

-- Update T2 (Exalted) items to orange
UPDATE items
SET Name = CONCAT(
    REPLACE(Name, ' (Exalted)', ''),
    ' ',
    CHAR(0x1A),
    '(Exalted)',
    CHAR(0x12)
)
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 2
)
AND Name LIKE '%(Exalted)%'
AND Name NOT LIKE CONCAT('%', CHAR(0x1A), '%');

SELECT CONCAT('✓ Updated ', ROW_COUNT(), ' T2 items to orange (Exalted)') AS status;

-- Update T3 (Ascendant) items to gold
UPDATE items
SET Name = CONCAT(
    REPLACE(Name, ' (Ascendant)', ''),
    ' ',
    CHAR(0x0A),
    '(Ascendant)',
    CHAR(0x12)
)
WHERE id IN (
    SELECT variant_item_id 
    FROM item_tier_map 
    WHERE tier_code = 3
)
AND Name LIKE '%(Ascendant)%'
AND Name NOT LIKE CONCAT('%', CHAR(0x0A), '%');

SELECT CONCAT('✓ Updated ', ROW_COUNT(), ' T3 items to gold (Ascendant)') AS status;

-- Verify updates
SELECT 
    'T1 items with color codes' AS check_name,
    COUNT(*) AS count
FROM items
WHERE id IN (SELECT variant_item_id FROM item_tier_map WHERE tier_code = 1)
AND Name LIKE CONCAT('%', CHAR(0x12), '%')
UNION ALL
SELECT 
    'T2 items with color codes' AS check_name,
    COUNT(*) AS count
FROM items
WHERE id IN (SELECT variant_item_id FROM item_tier_map WHERE tier_code = 2)
AND Name LIKE CONCAT('%', CHAR(0x1A), '%')
UNION ALL
SELECT 
    'T3 items with color codes' AS check_name,
    COUNT(*) AS count
FROM items
WHERE id IN (SELECT variant_item_id FROM item_tier_map WHERE tier_code = 3)
AND Name LIKE CONCAT('%', CHAR(0x0A), '%');

SELECT '============================================================================' AS '';
SELECT '✓ COLOR CODES ADDED TO ALL TIERS' AS '';
SELECT CONCAT('Execution time: ', TIMESTAMPDIFF(SECOND, @start_time, NOW()), ' seconds') AS timing;
SELECT '============================================================================' AS '';
SELECT 'Reload items in-game to see color-coded names!' AS next_step;
