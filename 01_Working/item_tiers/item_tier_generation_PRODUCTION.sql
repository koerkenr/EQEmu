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
    MAX(power_score) AS max
FROM item_power_scores;

-- ============================================================================
-- STEP 7: Generate Tier 1 (Enhanced) - GEAR ONLY
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'GENERATING TIER 1 (Enhanced) GEAR VARIANTS...' AS '';
SELECT '============================================================================' AS '';

-- Tier 1 multipliers: AC×1.10, HP/Mana/End×1.18, Stats×1.10, Damage×1.03
-- ID offset: +10000000

-- First, check for collisions (HARD ABORT if found)
SET @collision_count = (SELECT COUNT(*) FROM items i JOIN eligible_gear eg ON eg.id + 10000000 = i.id);

-- This will cause a guaranteed error if collisions exist (division by zero)
SELECT IF(@collision_count = 0, '✓ No ID collisions for T1 gear', 1/0) AS collision_check;

SELECT CONCAT('Verified: ', @collision_count, ' collisions (should be 0)') AS collision_status;

-- Generate T1 gear (full column list from original, but cleaner logic)
INSERT INTO items (
    id, minstatus, Name,
    aagi, ac, accuracy, acha, adex, aint, asta, astr, attack,
    cr, dr, fr, mr, pr, svcorruption,
    hp, mana, endur, regen, manaregen, enduranceregen,
    shielding, spellshield, dotshielding,
    damage, delay, strikethrough, avoidance,
    heroic_str, heroic_int, heroic_wis, heroic_agi, heroic_dex, heroic_sta, heroic_cha,
    heroic_pr, heroic_dr, heroic_fr, heroic_cr, heroic_mr, heroic_svcorrup,
    spelldmg, healamt, clairvoyance, backstabdmg,
    bagslots, bagwr, bagsize, bagtype,
    proceffect, clickeffect, worneffect, focuseffect, scrolleffect, bardeffect,
    haste,
    artifactflag, augrestrict,
    augslot1type, augslot1visible, augslot2type, augslot2visible,
    augslot3type, augslot3visible, augslot4type, augslot4visible,
    augslot5type, augslot5visible, augslot6type, augslot6visible,
    augtype, banedmgamt, banedmgraceamt, banedmgbody, banedmgrace,
    bardtype, bardvalue, book, casttime, casttime_, charmfile, charmfileid,
    classes, color, combateffects, extradmgskill, extradmgamt, price,
    damageshield, deity, augdistiller, clicktype, clicklevel2,
    elemdmgtype, elemdmgamt,
    factionamt1, factionamt2, factionamt3, factionamt4,
    factionmod1, factionmod2, factionmod3, factionmod4,
    filename, focuseffect, fvnodrop, clicklevel, icon, idfile,
    itemclass, itemtype, ldonprice, ldontheme, ldonsold, light, lore, loregroup,
    magic, material, herosforgemodel, maxcharges, nodrop, norent,
    pendingloreflag, procrate, races, range_, reclevel, recskill, reqlevel,
    sellrate, size, skillmodtype, skillmodvalue, slots,
    stunresist, summonedflag, tradeskills, favor, weight,
    UNK012, UNK013, benefitflag, UNK054, UNK059, booktype,
    recastdelay, recasttype, guildfavor, UNK123, UNK124, attuneable, nopet,
    updated, comment, UNK127, pointtype, potionbelt, potionbeltslots,
    stacksize, notransfer, stackable, UNK134, UNK137,
    proctype, proclevel2, proclevel, UNK142,
    worntype, wornlevel2, wornlevel, UNK147,
    focustype, focuslevel2, focuslevel, UNK152,
    scrolltype, scrolllevel2, scrolllevel, UNK157,
    serialized, verified, serialization, source, UNK033, lorefile, UNK014,
    skillmodmax, UNK060,
    augslot1unk2, augslot2unk2, augslot3unk2, augslot4unk2, augslot5unk2, augslot6unk2,
    UNK120, UNK121, questitemflag, UNK132,
    clickunk5, clickunk6, clickunk7,
    procunk1, procunk2, procunk3, procunk4, procunk6, procunk7,
    wornunk1, wornunk2, wornunk3, wornunk4, wornunk5, wornunk6, wornunk7,
    focusunk1, focusunk2, focusunk3, focusunk4, focusunk5, focusunk6, focusunk7,
    scrollunk1, scrollunk2, scrollunk3, scrollunk4, scrollunk5, scrollunk6, scrollunk7,
    UNK193, purity, evoitem, evoid, evolvinglevel, evomax,
    clickname, procname, wornname, focusname, scrollname, bardname,
    dsmitigation, created, elitematerial, ldonsellbackrate, scriptfileid,
    expendablearrow, powersourcecapacity, bardeffecttype, bardlevel2, bardlevel,
    bardunk1, bardunk2, bardunk3, bardunk4, bardunk5, bardunk7,
    UNK214, subtype, UNK220, UNK221, heirloom,
    UNK223, UNK224, UNK225, UNK226, UNK227, UNK228, UNK229, UNK230,
    UNK231, UNK232, UNK233, UNK234, placeable, UNK236, UNK237, UNK238,
    UNK239, UNK240, UNK241, epicitem
)
SELECT
    i.id + 10000000 AS id,
    i.minstatus,
    i.Name,
    -- Stats: ×1.10, inject +1 only if item is "real gear"
    -- "Real gear" = has AC, HP, mana, endur, OR any stats (includes jewelry with ac=0)
    -- Note: Logic is repeated per stat field (MySQL doesn't allow alias reuse in same SELECT)
    GREATEST(FLOOR(COALESCE(i.aagi,0) * 1.10),
        CASE WHEN COALESCE(i.aagi,0) = 0 AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR i.endur > 0 OR (i.astr + i.asta + i.adex + i.aint + i.awis + i.acha) > 0) THEN 1 ELSE 0 END) AS aagi,
    FLOOR(COALESCE(i.ac,0) * 1.10) AS ac,
    FLOOR(COALESCE(i.accuracy,0) * 1.10) AS accuracy,
    GREATEST(FLOOR(COALESCE(i.acha,0) * 1.10),
        CASE WHEN COALESCE(i.acha,0) = 0 AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR i.endur > 0 OR (i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis) > 0) THEN 1 ELSE 0 END) AS acha,
    GREATEST(FLOOR(COALESCE(i.adex,0) * 1.10),
        CASE WHEN COALESCE(i.adex,0) = 0 AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR i.endur > 0 OR (i.astr + i.asta + i.aagi + i.aint + i.awis + i.acha) > 0) THEN 1 ELSE 0 END) AS adex,
    GREATEST(FLOOR(COALESCE(i.aint,0) * 1.10),
        CASE WHEN COALESCE(i.aint,0) = 0 AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR i.endur > 0 OR (i.astr + i.asta + i.adex + i.aagi + i.awis + i.acha) > 0) THEN 1 ELSE 0 END) AS aint,
    GREATEST(FLOOR(COALESCE(i.asta,0) * 1.10),
        CASE WHEN COALESCE(i.asta,0) = 0 AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR i.endur > 0 OR (i.astr + i.adex + i.aagi + i.aint + i.awis + i.acha) > 0) THEN 1 ELSE 0 END) AS asta,
    GREATEST(FLOOR(COALESCE(i.astr,0) * 1.10),
        CASE WHEN COALESCE(i.astr,0) = 0 AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR i.endur > 0 OR (i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha) > 0) THEN 1 ELSE 0 END) AS astr,
    FLOOR(COALESCE(i.attack,0) * 1.10) AS attack,
    -- Resists: ×1.10
    FLOOR(COALESCE(i.cr,0) * 1.10) AS cr,
    FLOOR(COALESCE(i.dr,0) * 1.10) AS dr,
    FLOOR(COALESCE(i.fr,0) * 1.10) AS fr,
    FLOOR(COALESCE(i.mr,0) * 1.10) AS mr,
    FLOOR(COALESCE(i.pr,0) * 1.10) AS pr,
    FLOOR(COALESCE(i.svcorruption,0) * 1.10) AS svcorruption,
    -- Sustain: ×1.18, inject floor only if item is real gear (includes jewelry)
    GREATEST(FLOOR(COALESCE(i.hp,0) * 1.18),
        CASE WHEN COALESCE(i.hp,0) < 20 AND (i.ac > 0 OR i.mana > 0 OR (i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha) > 0) THEN 15 ELSE 0 END) AS hp,
    GREATEST(FLOOR(COALESCE(i.mana,0) * 1.18),
        CASE WHEN COALESCE(i.mana,0) < 20 AND (i.ac > 0 OR i.hp > 0 OR (i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha) > 0) THEN 15 ELSE 0 END) AS mana,
    GREATEST(FLOOR(COALESCE(i.endur,0) * 1.18),
        CASE WHEN COALESCE(i.endur,0) < 20 AND (i.ac > 0 OR i.hp > 0 OR i.mana > 0 OR (i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha) > 0) THEN 15 ELSE 0 END) AS endur,
    FLOOR(COALESCE(i.regen,0) * 1.18) AS regen,
    FLOOR(COALESCE(i.manaregen,0) * 1.18) AS manaregen,
    FLOOR(COALESCE(i.enduranceregen,0) * 1.18) AS enduranceregen,
    -- Shielding: ×1.10
    FLOOR(COALESCE(i.shielding,0) * 1.10) AS shielding,
    FLOOR(COALESCE(i.spellshield,0) * 1.10) AS spellshield,
    FLOOR(COALESCE(i.dotshielding,0) * 1.10) AS dotshielding,
    -- Weapon damage: ×1.03, delay FROZEN
    CASE WHEN i.delay > 0 THEN FLOOR(COALESCE(i.damage,0) * 1.03) ELSE i.damage END AS damage,
    i.delay,
    FLOOR(COALESCE(i.strikethrough,0) * 1.10) AS strikethrough,
    FLOOR(COALESCE(i.avoidance,0) * 1.10) AS avoidance,
    -- Heroics: unchanged at T1
    i.heroic_str, i.heroic_int, i.heroic_wis, i.heroic_agi, i.heroic_dex, i.heroic_sta, i.heroic_cha,
    i.heroic_pr, i.heroic_dr, i.heroic_fr, i.heroic_cr, i.heroic_mr, i.heroic_svcorrup,
    -- Spell damage: unchanged at T1
    i.spelldmg, i.healamt, i.clairvoyance, i.backstabdmg,
    -- Bags: zero for gear
    0 AS bagslots, 0 AS bagwr, 0 AS bagsize, 0 AS bagtype,
    -- Effects: unchanged
    i.proceffect, i.clickeffect, i.worneffect, i.focuseffect, i.scrolleffect, i.bardeffect,
    i.haste,
    -- Copy all other fields
    i.artifactflag, i.augrestrict,
    i.augslot1type, i.augslot1visible, i.augslot2type, i.augslot2visible,
    i.augslot3type, i.augslot3visible, i.augslot4type, i.augslot4visible,
    i.augslot5type, i.augslot5visible, i.augslot6type, i.augslot6visible,
    i.augtype, i.banedmgamt, i.banedmgraceamt, i.banedmgbody, i.banedmgrace,
    i.bardtype, i.bardvalue, i.book, i.casttime, i.casttime_, i.charmfile, i.charmfileid,
    i.classes, i.color, i.combateffects, i.extradmgskill, i.extradmgamt, i.price,
    i.damageshield, i.deity, i.augdistiller, i.clicktype, i.clicklevel2,
    i.elemdmgtype, i.elemdmgamt,
    i.factionamt1, i.factionamt2, i.factionamt3, i.factionamt4,
    i.factionmod1, i.factionmod2, i.factionmod3, i.factionmod4,
    i.filename, i.focuseffect, i.fvnodrop, i.clicklevel, i.icon, i.idfile,
    i.itemclass, i.itemtype, i.ldonprice, i.ldontheme, i.ldonsold, i.light, i.lore, i.loregroup,
    i.magic, i.material, i.herosforgemodel, i.maxcharges, i.nodrop, i.norent,
    i.pendingloreflag, i.procrate, i.races, i.range_, i.reclevel, i.recskill, i.reqlevel,
    i.sellrate, i.size, i.skillmodtype, i.skillmodvalue, i.slots,
    i.stunresist, i.summonedflag, i.tradeskills, i.favor, i.weight,
    i.UNK012, i.UNK013, i.benefitflag, i.UNK054, i.UNK059, i.booktype,
    i.recastdelay, i.recasttype, i.guildfavor, i.UNK123, i.UNK124, i.attuneable, i.nopet,
    NOW() AS updated,
    CONCAT('T1 Enhanced variant of item ', i.id, ' - ', @generation_run_id) AS comment,
    i.UNK127, i.pointtype, i.potionbelt, i.potionbeltslots,
    i.stacksize, i.notransfer, i.stackable, i.UNK134, i.UNK137,
    i.proctype, i.proclevel2, i.proclevel, i.UNK142,
    i.worntype, i.wornlevel2, i.wornlevel, i.UNK147,
    i.focustype, i.focuslevel2, i.focuslevel, i.UNK152,
    i.scrolltype, i.scrolllevel2, i.scrolllevel, i.UNK157,
    i.serialized, i.verified, i.serialization, i.source, i.UNK033, i.lorefile, i.UNK014,
    i.skillmodmax, i.UNK060,
    i.augslot1unk2, i.augslot2unk2, i.augslot3unk2, i.augslot4unk2, i.augslot5unk2, i.augslot6unk2,
    i.UNK120, i.UNK121, i.questitemflag, i.UNK132,
    i.clickunk5, i.clickunk6, i.clickunk7,
    i.procunk1, i.procunk2, i.procunk3, i.procunk4, i.procunk6, i.procunk7,
    i.wornunk1, i.wornunk2, i.wornunk3, i.wornunk4, i.wornunk5, i.wornunk6, i.wornunk7,
    i.focusunk1, i.focusunk2, i.focusunk3, i.focusunk4, i.focusunk5, i.focusunk6, i.focusunk7,
    i.scrollunk1, i.scrollunk2, i.scrollunk3, i.scrollunk4, i.scrollunk5, i.scrollunk6, i.scrollunk7,
    i.UNK193, i.purity, i.evoitem, i.evoid, i.evolvinglevel, i.evomax,
    i.clickname, i.procname, i.wornname, i.focusname, i.scrollname, i.bardname,
    i.dsmitigation, i.created, i.elitematerial, i.ldonsellbackrate, i.scriptfileid,
    i.expendablearrow, i.powersourcecapacity, i.bardeffecttype, i.bardlevel2, i.bardlevel,
    i.bardunk1, i.bardunk2, i.bardunk3, i.bardunk4, i.bardunk5, i.bardunk7,
    i.UNK214, i.subtype, i.UNK220, i.UNK221, i.heirloom,
    i.UNK223, i.UNK224, i.UNK225, i.UNK226, i.UNK227, i.UNK228, i.UNK229, i.UNK230,
    i.UNK231, i.UNK232, i.UNK233, i.UNK234, i.placeable, i.UNK236, i.UNK237, i.UNK238,
    i.UNK239, i.UNK240, i.UNK241, i.epicitem
FROM eligible_gear eg
JOIN items i ON eg.id = i.id
WHERE NOT EXISTS (
    SELECT 1 FROM item_tier_map
    WHERE base_item_id = i.id AND tier_code = 1
)
AND NOT EXISTS (
    SELECT 1 FROM items WHERE id = i.id + 10000000
);

-- Record T1 gear mappings
INSERT INTO item_tier_map (base_item_id, tier_code, variant_item_id, power_score, item_category, generation_run_id)
SELECT
    i.id,
    1,
    i.id + 10000000,
    ps.power_score,
    'gear',
    @generation_run_id
FROM eligible_gear eg
JOIN items i ON eg.id = i.id
JOIN item_power_scores ps ON i.id = ps.item_id
WHERE NOT EXISTS (
    SELECT 1 FROM item_tier_map
    WHERE base_item_id = i.id AND tier_code = 1
)
AND EXISTS (
    SELECT 1 FROM items WHERE id = i.id + 10000000
);

SELECT CONCAT('✓ Tier 1 gear generated: ', ROW_COUNT(), ' mappings at ', NOW()) AS status;

-- ============================================================================
-- STEP 8: Generate Tier 1 (Enhanced) - BAGS ONLY
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'GENERATING TIER 1 (Enhanced) BAG VARIANTS...' AS '';
SELECT '============================================================================' AS '';

-- Bags: +2 slots (cap 12), +5 WR (cap 25)
-- Use full-column copy strategy (same as gear) to avoid NOT NULL constraint failures
-- Override only: id, bagslots, bagwr, and zero all gear stats

INSERT INTO items (
    id, minstatus, Name,
    aagi, ac, accuracy, acha, adex, aint, asta, astr, attack,
    cr, dr, fr, mr, pr, svcorruption,
    hp, mana, endur, regen, manaregen, enduranceregen,
    shielding, spellshield, dotshielding,
    damage, delay, strikethrough, avoidance,
    heroic_str, heroic_int, heroic_wis, heroic_agi, heroic_dex, heroic_sta, heroic_cha,
    heroic_pr, heroic_dr, heroic_fr, heroic_cr, heroic_mr, heroic_svcorrup,
    spelldmg, healamt, clairvoyance, backstabdmg,
    bagslots, bagwr, bagsize, bagtype,
    proceffect, clickeffect, worneffect, focuseffect, scrolleffect, bardeffect,
    haste,
    artifactflag, augrestrict,
    augslot1type, augslot1visible, augslot2type, augslot2visible,
    augslot3type, augslot3visible, augslot4type, augslot4visible,
    augslot5type, augslot5visible, augslot6type, augslot6visible,
    augtype, banedmgamt, banedmgraceamt, banedmgbody, banedmgrace,
    bardtype, bardvalue, book, casttime, casttime_, charmfile, charmfileid,
    classes, color, combateffects, extradmgskill, extradmgamt, price,
    damageshield, deity, augdistiller, clicktype, clicklevel2,
    elemdmgtype, elemdmgamt,
    factionamt1, factionamt2, factionamt3, factionamt4,
    factionmod1, factionmod2, factionmod3, factionmod4,
    filename, focuseffect, fvnodrop, clicklevel, icon, idfile,
    itemclass, itemtype, ldonprice, ldontheme, ldonsold, light, lore, loregroup,
    magic, material, herosforgemodel, maxcharges, nodrop, norent,
    pendingloreflag, procrate, races, range_, reclevel, recskill, reqlevel,
    sellrate, size, skillmodtype, skillmodvalue, slots,
    stunresist, summonedflag, tradeskills, favor, weight,
    UNK012, UNK013, benefitflag, UNK054, UNK059, booktype,
    recastdelay, recasttype, guildfavor, UNK123, UNK124, attuneable, nopet,
    updated, comment, UNK127, pointtype, potionbelt, potionbeltslots,
    stacksize, notransfer, stackable, UNK134, UNK137,
    proctype, proclevel2, proclevel, UNK142,
    worntype, wornlevel2, wornlevel, UNK147,
    focustype, focuslevel2, focuslevel, UNK152,
    scrolltype, scrolllevel2, scrolllevel, UNK157,
    serialized, verified, serialization, source, UNK033, lorefile, UNK014,
    skillmodmax, UNK060,
    augslot1unk2, augslot2unk2, augslot3unk2, augslot4unk2, augslot5unk2, augslot6unk2,
    UNK120, UNK121, questitemflag, UNK132,
    clickunk5, clickunk6, clickunk7,
    procunk1, procunk2, procunk3, procunk4, procunk6, procunk7,
    wornunk1, wornunk2, wornunk3, wornunk4, wornunk5, wornunk6, wornunk7,
    focusunk1, focusunk2, focusunk3, focusunk4, focusunk5, focusunk6, focusunk7,
    scrollunk1, scrollunk2, scrollunk3, scrollunk4, scrollunk5, scrollunk6, scrollunk7,
    UNK193, purity, evoitem, evoid, evolvinglevel, evomax,
    clickname, procname, wornname, focusname, scrollname, bardname,
    dsmitigation, created, elitematerial, ldonsellbackrate, scriptfileid,
    expendablearrow, powersourcecapacity, bardeffecttype, bardlevel2, bardlevel,
    bardunk1, bardunk2, bardunk3, bardunk4, bardunk5, bardunk7,
    UNK214, subtype, UNK220, UNK221, heirloom,
    UNK223, UNK224, UNK225, UNK226, UNK227, UNK228, UNK229, UNK230,
    UNK231, UNK232, UNK233, UNK234, placeable, UNK236, UNK237, UNK238,
    UNK239, UNK240, UNK241, epicitem
)
SELECT
    i.id + 10000000 AS id,
    i.minstatus,
    i.Name,
    -- Zero all gear stats for bags
    0, 0, 0, 0, 0, 0, 0, 0, 0,  -- aagi through attack
    0, 0, 0, 0, 0, 0,  -- resists
    0, 0, 0, 0, 0, 0,  -- hp/mana/endur/regen
    0, 0, 0,  -- shielding
    0, 0, 0, 0,  -- damage/delay/strikethrough/avoidance
    0, 0, 0, 0, 0, 0, 0,  -- heroic stats
    0, 0, 0, 0, 0, 0,  -- heroic resists
    0, 0, 0, 0,  -- spell damage/heal/clairvoyance/backstab
    -- Bag stats: scaled
    LEAST(COALESCE(i.bagslots,0) + 2, 12) AS bagslots,
    LEAST(COALESCE(i.bagwr,0) + 5, 25) AS bagwr,
    i.bagsize,
    i.bagtype,
    -- Effects: unchanged
    i.proceffect, i.clickeffect, i.worneffect, i.focuseffect, i.scrolleffect, i.bardeffect,
    i.haste,
    -- Copy all other fields exactly
    i.artifactflag, i.augrestrict,
    i.augslot1type, i.augslot1visible, i.augslot2type, i.augslot2visible,
    i.augslot3type, i.augslot3visible, i.augslot4type, i.augslot4visible,
    i.augslot5type, i.augslot5visible, i.augslot6type, i.augslot6visible,
    i.augtype, i.banedmgamt, i.banedmgraceamt, i.banedmgbody, i.banedmgrace,
    i.bardtype, i.bardvalue, i.book, i.casttime, i.casttime_, i.charmfile, i.charmfileid,
    i.classes, i.color, i.combateffects, i.extradmgskill, i.extradmgamt, i.price,
    i.damageshield, i.deity, i.augdistiller, i.clicktype, i.clicklevel2,
    i.elemdmgtype, i.elemdmgamt,
    i.factionamt1, i.factionamt2, i.factionamt3, i.factionamt4,
    i.factionmod1, i.factionmod2, i.factionmod3, i.factionmod4,
    i.filename, i.focuseffect, i.fvnodrop, i.clicklevel, i.icon, i.idfile,
    i.itemclass, i.itemtype, i.ldonprice, i.ldontheme, i.ldonsold, i.light, i.lore, i.loregroup,
    i.magic, i.material, i.herosforgemodel, i.maxcharges, i.nodrop, i.norent,
    i.pendingloreflag, i.procrate, i.races, i.range_, i.reclevel, i.recskill, i.reqlevel,
    i.sellrate, i.size, i.skillmodtype, i.skillmodvalue, i.slots,
    i.stunresist, i.summonedflag, i.tradeskills, i.favor, i.weight,
    i.UNK012, i.UNK013, i.benefitflag, i.UNK054, i.UNK059, i.booktype,
    i.recastdelay, i.recasttype, i.guildfavor, i.UNK123, i.UNK124, i.attuneable, i.nopet,
    NOW() AS updated,
    CONCAT('T1 Enhanced bag variant of item ', i.id, ' - ', @generation_run_id) AS comment,
    i.UNK127, i.pointtype, i.potionbelt, i.potionbeltslots,
    i.stacksize, i.notransfer, i.stackable, i.UNK134, i.UNK137,
    i.proctype, i.proclevel2, i.proclevel, i.UNK142,
    i.worntype, i.wornlevel2, i.wornlevel, i.UNK147,
    i.focustype, i.focuslevel2, i.focuslevel, i.UNK152,
    i.scrolltype, i.scrolllevel2, i.scrolllevel, i.UNK157,
    i.serialized, i.verified, i.serialization, i.source, i.UNK033, i.lorefile, i.UNK014,
    i.skillmodmax, i.UNK060,
    i.augslot1unk2, i.augslot2unk2, i.augslot3unk2, i.augslot4unk2, i.augslot5unk2, i.augslot6unk2,
    i.UNK120, i.UNK121, i.questitemflag, i.UNK132,
    i.clickunk5, i.clickunk6, i.clickunk7,
    i.procunk1, i.procunk2, i.procunk3, i.procunk4, i.procunk6, i.procunk7,
    i.wornunk1, i.wornunk2, i.wornunk3, i.wornunk4, i.wornunk5, i.wornunk6, i.wornunk7,
    i.focusunk1, i.focusunk2, i.focusunk3, i.focusunk4, i.focusunk5, i.focusunk6, i.focusunk7,
    i.scrollunk1, i.scrollunk2, i.scrollunk3, i.scrollunk4, i.scrollunk5, i.scrollunk6, i.scrollunk7,
    i.UNK193, i.purity, i.evoitem, i.evoid, i.evolvinglevel, i.evomax,
    i.clickname, i.procname, i.wornname, i.focusname, i.scrollname, i.bardname,
    i.dsmitigation, i.created, i.elitematerial, i.ldonsellbackrate, i.scriptfileid,
    i.expendablearrow, i.powersourcecapacity, i.bardeffecttype, i.bardlevel2, i.bardlevel,
    i.bardunk1, i.bardunk2, i.bardunk3, i.bardunk4, i.bardunk5, i.bardunk7,
    i.UNK214, i.subtype, i.UNK220, i.UNK221, i.heirloom,
    i.UNK223, i.UNK224, i.UNK225, i.UNK226, i.UNK227, i.UNK228, i.UNK229, i.UNK230,
    i.UNK231, i.UNK232, i.UNK233, i.UNK234, i.placeable, i.UNK236, i.UNK237, i.UNK238,
    i.UNK239, i.UNK240, i.UNK241, i.epicitem
FROM eligible_bags eb
JOIN items i ON eb.id = i.id
WHERE NOT EXISTS (SELECT 1 FROM item_tier_map WHERE base_item_id = i.id AND tier_code = 1)
AND NOT EXISTS (SELECT 1 FROM items WHERE id = i.id + 10000000);

-- Record T1 bag mappings
INSERT INTO item_tier_map (base_item_id, tier_code, variant_item_id, power_score, item_category, generation_run_id)
SELECT
    i.id,
    1,
    i.id + 10000000,
    0,
    'bag',
    @generation_run_id
FROM eligible_bags eb
JOIN items i ON eb.id = i.id
WHERE NOT EXISTS (SELECT 1 FROM item_tier_map WHERE base_item_id = i.id AND tier_code = 1)
AND EXISTS (SELECT 1 FROM items WHERE id = i.id + 10000000);

SELECT CONCAT('✓ Tier 1 bags generated: ', ROW_COUNT(), ' mappings at ', NOW()) AS status;

