-- ============================================================================
-- EQEmu Item Tiering - Tier 1 (Enhanced) with Selective Injection
-- ============================================================================
-- Strategy:
-- - Multiply existing stats (AC ×1.10, HP/Mana/Endur ×1.18, Stats ×1.10)
-- - Selectively inject 2-3 missing stats based on role
-- - NO premium stats at T1 (accuracy, strikethrough, avoidance, etc.)
-- - Use pseudo-random (MOD on item ID) for variety but deterministic
-- ============================================================================

-- Reuse setup from PRODUCTION_fixed.sql (lines 1-240)
-- This includes: table creation, class masks, eligibility views, power score function

-- Modified power score cache with is_zero_stat flag
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

-- ============================================================================
-- SELECTIVE STAT INJECTION LOGIC
-- ============================================================================
-- For missing stats, inject based on role:
-- - Tanks: STA +1 always, pick 1-2 from (STR, AGI, resist)
-- - Melee DPS: STA +1 always, pick 1-2 from (STR, DEX, AGI, resist)
-- - INT Casters: STA +1 always, pick 1-2 from (INT, CHA, resist)
-- - WIS Casters: STA +1 always, pick 1-2 from (WIS, CHA, resist)
-- 
-- Use MOD(item_id, N) for pseudo-random but deterministic selection
-- ============================================================================

-- Stat injection formulas (to be used in SELECT):
-- 
-- AGI: existing * 1.10, OR if zero and melee DPS: +1
-- AC: existing * 1.10, OR if zero and tank: +2, melee: +1
-- CHA: existing * 1.10, OR if zero and caster: +1
-- DEX: existing * 1.10, OR if zero and melee DPS: +1
-- INT: existing * 1.10, OR if zero and INT caster: +1
-- WIS: existing * 1.10, OR if zero and WIS caster: +1
-- STA: existing * 1.10, OR if zero: +1 (everyone)
-- STR: existing * 1.10, OR if zero and tank/melee: +1
-- 
-- Resists: existing * 1.10, OR if zero: one random resist +2 (via MOD(id,5))
-- HP: existing * 1.18, OR if zero and has other stats: +10-15
-- Mana: existing * 1.18, OR if zero and caster: +12
-- Endur: existing * 1.18, OR if zero and tank/melee: +10

-- This will be implemented in the INSERT SELECT below

