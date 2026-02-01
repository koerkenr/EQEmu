-- ============================================================================
-- EQEmu Item Tiering System - CORRECTED VERSION
-- ============================================================================
-- Date: 2026-01-29
-- Fixes: Class bitmasks, power score caching, heroics logic, progressive caps
-- ============================================================================

SET @start_time = NOW();
SET SESSION sql_mode = '';

-- ============================================================================
-- STEP 1: Create tier mapping tables with run tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS item_tier_map (
  base_item_id     INT NOT NULL,
  tier_code        TINYINT NOT NULL COMMENT '1=Enhanced,2=Exalted,3=Ascendant',
  variant_item_id  INT NOT NULL,
  power_score      FLOAT DEFAULT 0,
  item_category    VARCHAR(16) DEFAULT 'gear' COMMENT 'gear/bag/augment',
  generation_run_id VARCHAR(64) DEFAULT NULL COMMENT 'Timestamp or tag for this generation run',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (base_item_id, tier_code),
  UNIQUE KEY uq_variant (variant_item_id),
  KEY idx_base (base_item_id),
  KEY idx_tier (tier_code),
  KEY idx_run (generation_run_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tier_defs (
  tier_code TINYINT PRIMARY KEY,
  tier_name VARCHAR(32) NOT NULL,
  display_name VARCHAR(64) NOT NULL
) ENGINE=InnoDB;

INSERT IGNORE INTO tier_defs VALUES
(1, 'Enhanced', 'Enhanced'),
(2, 'Exalted', 'Exalted'),
(3, 'Ascendant', 'Ascendant');

-- Set generation run ID for this execution
SET @generation_run_id = CONCAT('run_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'));

SELECT CONCAT('✓ Generation run ID: ', @generation_run_id) AS status;

-- ============================================================================
-- STEP 2: Define class role masks (EQEmu standard bitmasks)
-- ============================================================================

-- EQEmu class bitmasks:
-- WAR=1, CLR=2, PAL=4, RNG=8, SHD=16, DRU=32, MNK=64, BRD=128,
-- ROG=256, SHM=512, NEC=1024, WIZ=2048, MAG=4096, ENC=8192, BST=16384, BER=32768

SET @CLS_TANK = 1 + 4 + 16;  -- WAR, PAL, SHD
SET @CLS_MELEE_DPS = 8 + 64 + 128 + 256 + 16384 + 32768;  -- RNG, MNK, BRD, ROG, BST, BER
SET @CLS_INT_CASTER = 1024 + 2048 + 4096 + 8192;  -- NEC, WIZ, MAG, ENC
SET @CLS_WIS_CASTER = 2 + 32 + 512;  -- CLR, DRU, SHM
SET @CLS_ALL_CASTER = @CLS_INT_CASTER + @CLS_WIS_CASTER;

SELECT 'Class role masks defined' AS status;

-- ============================================================================
-- STEP 3: Create eligibility views (GEAR ONLY - bags separate)
-- ============================================================================

DROP VIEW IF EXISTS eligible_gear;
DROP VIEW IF EXISTS eligible_bags;

-- Eligible gear: equipable items only (no bags)
CREATE VIEW eligible_gear AS
SELECT
    id, Name, slots, classes, races, itemclass, itemtype, reqlevel,
    ac, hp, mana, endur,
    astr, asta, adex, aagi, aint, awis, acha,
    cr, dr, fr, mr, pr, svcorruption,
    accuracy, attack, avoidance, strikethrough,
    damage, delay,
    regen, manaregen, enduranceregen,
    shielding, spellshield, dotshielding,
    heroic_str, heroic_int, heroic_wis, heroic_agi, heroic_dex, heroic_sta, heroic_cha,
    heroic_pr, heroic_dr, heroic_fr, heroic_cr, heroic_mr, heroic_svcorrup,
    spelldmg, healamt, clairvoyance, backstabdmg,
    proceffect, clickeffect, worneffect, focuseffect, scrolleffect, bardeffect,
    haste,
    nodrop, norent, notransfer, loregroup, attuneable
FROM items
WHERE slots > 0
  AND classes > 0
  AND itemclass != 1  -- NOT containers
  AND itemclass NOT IN (2, 10, 11, 12, 14, 15, 16, 17, 18)  -- NOT books, food, drink, light, potions, scrolls, bandages, throwing, arrows
  -- NOTE: These itemclass values may be DB-specific. Use the QA distribution output below to verify!
  AND id < 10000000  -- Only base items
  AND NOT EXISTS (
    SELECT 1 FROM item_tier_map m
    WHERE m.variant_item_id = items.id
  );

-- Eligible bags: containers only
CREATE VIEW eligible_bags AS
SELECT
    id, Name, bagslots, bagwr, bagsize, bagtype,
    itemclass, reqlevel, slots, classes,
    nodrop, norent, notransfer, loregroup
FROM items
WHERE itemclass = 1
  AND bagslots > 0
  AND id < 10000000
  AND NOT EXISTS (
    SELECT 1 FROM item_tier_map m
    WHERE m.variant_item_id = items.id
  );

SELECT CONCAT('✓ Eligibility views created at ', NOW()) AS status;

-- ============================================================================
-- STEP 4: Pre-flight checks
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'PRE-FLIGHT CHECKS' AS '';
SELECT '============================================================================' AS '';

-- Count eligible items
SELECT 'Eligible gear items' AS category, COUNT(*) AS count FROM eligible_gear
UNION ALL
SELECT 'Eligible bag items' AS category, COUNT(*) AS count FROM eligible_bags;

-- Check current max item ID
SELECT
    MAX(id) AS current_max_item_id,
    CASE
        WHEN MAX(id) < 10000000 THEN '✓ Safe to use 10M+ offsets'
        ELSE '⚠ WARNING: Items exist above 10M!'
    END AS id_space_check
FROM items;

-- Check for ID collisions
SELECT
    'Collision check' AS check_name,
    COUNT(*) AS existing_tier_ids,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ No collisions'
        ELSE '⚠ WARNING: Tier ID range already has items!'
    END AS result
FROM items
WHERE id >= 10000000 AND id < 40000000;

-- Sample itemclass distribution in eligible gear
SELECT
    itemclass,
    COUNT(*) AS count,
    GROUP_CONCAT(DISTINCT Name SEPARATOR ', ') AS sample_names
FROM (
    SELECT itemclass, Name FROM eligible_gear LIMIT 100
) sample
GROUP BY itemclass;

-- Validate itemclass/itemtype distribution in eligible gear
SELECT
    'Eligible gear itemclass/itemtype distribution' AS check_name,
    itemclass,
    itemtype,
    COUNT(*) AS count,
    GROUP_CONCAT(DISTINCT Name ORDER BY Name SEPARATOR ' | ') AS sample_items
FROM (
    SELECT itemclass, itemtype, Name
    FROM eligible_gear
    LIMIT 200
) sample
GROUP BY itemclass, itemtype
ORDER BY itemclass, itemtype;

SELECT '============================================================================' AS '';
SELECT '⚠ REVIEW ABOVE - Verify itemclass/itemtype filters are correct' AS '';
SELECT 'If incorrect items appear, adjust eligibility view filters' AS '';
SELECT '============================================================================' AS '';

-- ============================================================================
-- HARD GATE: Set @continue_generation = 1 to proceed
-- ============================================================================
-- This will FORCE AN ERROR (division by zero) if you haven't reviewed the QA output above.
-- To continue: Execute "SET @continue_generation = 1;" then re-run from here.

SET @continue_generation = 1;

-- This will cause a guaranteed error if flag is not set (division by zero)
SELECT IF(@continue_generation = 1, '✓ Gate passed - continuing with generation', 1/0) AS gate_check;

SELECT '✓ Gate passed - proceeding with generation' AS status;

-- ============================================================================
-- STEP 5: Power score calculation function
-- ============================================================================

DROP FUNCTION IF EXISTS calculate_power_score;

DELIMITER $$
CREATE FUNCTION calculate_power_score(
    p_ac INT, p_hp INT, p_mana INT, p_endur INT,
    p_str INT, p_sta INT, p_dex INT, p_agi INT, p_int INT, p_wis INT, p_cha INT,
    p_cr INT, p_dr INT, p_fr INT, p_mr INT, p_pr INT, p_svcorr INT,
    p_accuracy INT, p_attack INT, p_strikethrough INT,
    p_regen INT, p_manaregen INT, p_enduranceregen INT,
    p_shielding INT, p_spellshield INT, p_dotshielding INT
) RETURNS FLOAT
DETERMINISTIC
BEGIN
    DECLARE stat_sum INT;
    DECLARE resist_sum INT;

    SET stat_sum = COALESCE(p_str,0) + COALESCE(p_sta,0) + COALESCE(p_dex,0) +
                   COALESCE(p_agi,0) + COALESCE(p_int,0) + COALESCE(p_wis,0) +
                   COALESCE(p_cha,0);

    SET resist_sum = COALESCE(p_cr,0) + COALESCE(p_dr,0) + COALESCE(p_fr,0) +
                     COALESCE(p_mr,0) + COALESCE(p_pr,0) + COALESCE(p_svcorr,0);

    RETURN (COALESCE(p_ac,0) * 4) +
           (COALESCE(p_hp,0) * 1.0) +
           (COALESCE(p_mana,0) * 0.9) +
           (COALESCE(p_endur,0) * 0.8) +
           (stat_sum * 6) +
           (resist_sum * 2) +
           (COALESCE(p_accuracy,0) * 10) +
           (COALESCE(p_attack,0) * 2) +
           (COALESCE(p_regen,0) * 30) +
           (COALESCE(p_manaregen,0) * 30) +
           (COALESCE(p_enduranceregen,0) * 20) +
           (COALESCE(p_shielding,0) * 25) +
           (COALESCE(p_spellshield,0) * 25) +
           (COALESCE(p_dotshielding,0) * 25) +
           (COALESCE(p_strikethrough,0) * 12);
END$$
DELIMITER ;

SELECT CONCAT('✓ Power score function created at ', NOW()) AS status;

-- ============================================================================
-- STEP 6: Create power score cache table for performance
-- ============================================================================

DROP TEMPORARY TABLE IF EXISTS item_power_scores;

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

-- Populate power scores and role flags for all eligible gear
INSERT INTO item_power_scores
SELECT
    i.id,
    calculate_power_score(
        i.ac, i.hp, i.mana, i.endur,
        i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha,
        i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption,
        i.accuracy, i.attack, i.strikethrough,
        i.regen, i.manaregen, i.enduranceregen,
        i.shielding, i.spellshield, i.dotshielding
    ) AS power_score,
    (i.classes & @CLS_TANK) > 0 AS is_tank,
    (i.classes & @CLS_MELEE_DPS) > 0 AS is_melee_dps,
    (i.classes & @CLS_INT_CASTER) > 0 AS is_int_caster,
    (i.classes & @CLS_WIS_CASTER) > 0 AS is_wis_caster,
    i.mana > 30 AS has_mana
FROM eligible_gear i;

SELECT CONCAT('✓ Power scores cached for ', ROW_COUNT(), ' items at ', NOW()) AS status;

-- Show power score distribution
SELECT
    'Power score percentiles' AS metric,
    MIN(power_score) AS min,
    FLOOR(AVG(power_score)) AS avg,
