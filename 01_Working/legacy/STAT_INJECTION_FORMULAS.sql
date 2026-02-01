-- ============================================================================
-- T1 Selective Stat Injection Formulas
-- ============================================================================
-- These replace the uniform +1 all stats approach
-- Use in the INSERT SELECT for T1 gear generation
-- ============================================================================

-- AGI: Multiply existing, OR inject +1 for melee DPS only
GREATEST(FLOOR(COALESCE(i.aagi,0) * 1.10),
    CASE WHEN COALESCE(i.aagi,0) = 0 AND ps.is_melee_dps AND MOD(i.id, 3) IN (0,1) THEN 1 ELSE 0 END) AS aagi,

-- AC: Multiply existing, OR inject for tanks/melee (no AC on pure casters)
GREATEST(FLOOR(COALESCE(i.ac,0) * 1.10),
    CASE 
        WHEN COALESCE(i.ac,0) = 0 AND ps.is_tank THEN 2
        WHEN COALESCE(i.ac,0) = 0 AND ps.is_melee_dps THEN 1
        ELSE 0 
    END) AS ac,

-- Accuracy: Multiply existing, NO injection at T1
FLOOR(COALESCE(i.accuracy,0) * 1.10) AS accuracy,

-- CHA: Multiply existing, OR inject +1 for casters only
GREATEST(FLOOR(COALESCE(i.acha,0) * 1.10),
    CASE WHEN COALESCE(i.acha,0) = 0 AND (ps.is_int_caster OR ps.is_wis_caster) AND MOD(i.id, 3) IN (0,1) THEN 1 ELSE 0 END) AS acha,

-- DEX: Multiply existing, OR inject +1 for melee DPS only
GREATEST(FLOOR(COALESCE(i.adex,0) * 1.10),
    CASE WHEN COALESCE(i.adex,0) = 0 AND ps.is_melee_dps AND MOD(i.id, 3) IN (1,2) THEN 1 ELSE 0 END) AS adex,

-- INT: Multiply existing, OR inject +1 for INT casters only
GREATEST(FLOOR(COALESCE(i.aint,0) * 1.10),
    CASE WHEN COALESCE(i.aint,0) = 0 AND ps.is_int_caster AND MOD(i.id, 3) IN (0,1) THEN 1 ELSE 0 END) AS aint,

-- STA: Multiply existing, OR inject +1 for everyone (universal stat)
GREATEST(FLOOR(COALESCE(i.asta,0) * 1.10),
    CASE WHEN COALESCE(i.asta,0) = 0 AND ps.is_zero_stat = 0 THEN 1 ELSE 0 END) AS asta,

-- STR: Multiply existing, OR inject +1 for tanks/melee only
GREATEST(FLOOR(COALESCE(i.astr,0) * 1.10),
    CASE WHEN COALESCE(i.astr,0) = 0 AND (ps.is_tank OR ps.is_melee_dps) AND MOD(i.id, 3) IN (0,2) THEN 1 ELSE 0 END) AS astr,

-- WIS: Multiply existing, OR inject +1 for WIS casters only
GREATEST(FLOOR(COALESCE(i.awis,0) * 1.10),
    CASE WHEN COALESCE(i.awis,0) = 0 AND ps.is_wis_caster AND MOD(i.id, 3) IN (0,1) THEN 1 ELSE 0 END) AS awis,

-- Attack: Multiply existing, NO injection at T1
FLOOR(COALESCE(i.attack,0) * 1.10) AS attack,

-- Resists: Multiply existing, OR inject ONE random resist +2 for items with other stats
GREATEST(FLOOR(COALESCE(i.cr,0) * 1.10),
    CASE WHEN COALESCE(i.cr,0) = 0 AND ps.is_zero_stat = 0 AND MOD(i.id, 5) = 0 THEN 2 ELSE 0 END) AS cr,
GREATEST(FLOOR(COALESCE(i.dr,0) * 1.10),
    CASE WHEN COALESCE(i.dr,0) = 0 AND ps.is_zero_stat = 0 AND MOD(i.id, 5) = 1 THEN 2 ELSE 0 END) AS dr,
GREATEST(FLOOR(COALESCE(i.fr,0) * 1.10),
    CASE WHEN COALESCE(i.fr,0) = 0 AND ps.is_zero_stat = 0 AND MOD(i.id, 5) = 2 THEN 2 ELSE 0 END) AS fr,
GREATEST(FLOOR(COALESCE(i.mr,0) * 1.10),
    CASE WHEN COALESCE(i.mr,0) = 0 AND ps.is_zero_stat = 0 AND MOD(i.id, 5) = 3 THEN 2 ELSE 0 END) AS mr,
GREATEST(FLOOR(COALESCE(i.pr,0) * 1.10),
    CASE WHEN COALESCE(i.pr,0) = 0 AND ps.is_zero_stat = 0 AND MOD(i.id, 5) = 4 THEN 2 ELSE 0 END) AS pr,
FLOOR(COALESCE(i.svcorruption,0) * 1.10) AS svcorruption,

-- HP: Multiply existing, OR inject based on role for items with other stats
GREATEST(FLOOR(COALESCE(i.hp,0) * 1.18),
    CASE 
        WHEN COALESCE(i.hp,0) = 0 AND ps.is_zero_stat = 0 AND ps.is_tank THEN 15
        WHEN COALESCE(i.hp,0) = 0 AND ps.is_zero_stat = 0 THEN 10
        ELSE 0 
    END) AS hp,

-- Mana: Multiply existing, OR inject ONLY for casters with other stats
GREATEST(FLOOR(COALESCE(i.mana,0) * 1.18),
    CASE WHEN COALESCE(i.mana,0) = 0 AND ps.is_zero_stat = 0 AND (ps.is_int_caster OR ps.is_wis_caster) THEN 12 ELSE 0 END) AS mana,

-- Endur: Multiply existing, OR inject for tanks/melee with other stats
GREATEST(FLOOR(COALESCE(i.endur,0) * 1.18),
    CASE WHEN COALESCE(i.endur,0) = 0 AND ps.is_zero_stat = 0 AND (ps.is_tank OR ps.is_melee_dps) THEN 10 ELSE 0 END) AS endur,

-- Regen/Mana Regen/Endur Regen: Multiply existing, NO injection at T1
FLOOR(COALESCE(i.regen,0) * 1.18) AS regen,
FLOOR(COALESCE(i.manaregen,0) * 1.18) AS manaregen,
FLOOR(COALESCE(i.enduranceregen,0) * 1.18) AS enduranceregen,

-- Shielding: Multiply existing, NO injection at T1
FLOOR(COALESCE(i.shielding,0) * 1.10) AS shielding,
FLOOR(COALESCE(i.spellshield,0) * 1.10) AS spellshield,
FLOOR(COALESCE(i.dotshielding,0) * 1.10) AS dotshielding,

-- Strikethrough: Multiply existing, NO injection at T1
FLOOR(COALESCE(i.strikethrough,0) * 1.10) AS strikethrough,

-- Avoidance: Multiply existing, NO injection at T1
FLOOR(COALESCE(i.avoidance,0) * 1.10) AS avoidance,

-- Stun Resist: Multiply existing, NO injection at T1
FLOOR(COALESCE(i.stunresist,0) * 1.10) AS stunresist,

-- Heroics: NO injection at T1, multiply existing only
0 AS heroic_str,
0 AS heroic_int,
0 AS heroic_wis,
0 AS heroic_agi,
0 AS heroic_dex,
0 AS heroic_sta,
0 AS heroic_cha,
0 AS heroic_pr,
0 AS heroic_dr,
0 AS heroic_fr,
0 AS heroic_cr,
0 AS heroic_mr,
0 AS heroic_svcorrup,

-- Spell damage: NO injection at T1
0 AS spelldmg,
0 AS healamt,
0 AS clairvoyance,
0 AS backstabdmg

-- ============================================================================
-- Key Points:
-- - MOD(i.id, 3) gives 0, 1, or 2 - used to select which 2 of 3 stats to inject
-- - MOD(i.id, 5) gives 0-4 - used to select which resist to inject
-- - is_zero_stat = 0 means item has SOME stats (not cosmetic)
-- - Role flags (is_tank, is_melee_dps, etc.) determine which stats are appropriate
-- - Premium stats (accuracy, attack, strikethrough, avoidance, stun resist) are NOT injected at T1
-- - This creates variety while respecting class identity
-- ============================================================================
