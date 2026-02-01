-- ============================================================================
-- EQEmu Item Tiering System - SELECTIVE INJECTION VERSION
-- ============================================================================
-- This script splits T1 generation into:
-- 1. Items WITH stats: multiplicative scaling (existing logic)
-- 2. Zero-stat items: role-based selective injection (new logic)
-- ============================================================================

SET @start_time = NOW();
SET SESSION sql_mode = '';

-- Reuse existing table setup and class masks from previous script
-- (Lines 1-60 from PRODUCTION_fixed.sql)

SET @generation_run_id = CONCAT('run_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'));

-- ============================================================================
-- Modified power score cache: Add is_zero_stat flag
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
    is_zero_stat BOOLEAN,
    KEY idx_power (power_score),
    KEY idx_zero (is_zero_stat)
) ENGINE=InnoDB;

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
    i.mana > 30 AS has_mana,
    (i.ac = 0 AND i.hp = 0 AND i.mana = 0 AND i.endur = 0 AND 
     (i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha) = 0) AS is_zero_stat
FROM eligible_gear i;

SELECT 
    'Items with stats' AS category,
    COUNT(*) AS count
FROM item_power_scores WHERE is_zero_stat = 0
UNION ALL
SELECT 
    'Zero-stat items' AS category,
    COUNT(*) AS count
FROM item_power_scores WHERE is_zero_stat = 1;

