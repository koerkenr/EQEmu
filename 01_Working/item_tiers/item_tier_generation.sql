-- ============================================================================
-- EQEmu Item Tiering System - Generation Script
-- ============================================================================
-- Date: 2026-01-29
-- Purpose: Generate 3 tier variants (T1/T2/T3) for all eligible items
-- Strategy: Base-item multiplicative scaling with injection floors
-- Target: Solo/duo focused server with natural power curve
--
-- IMPORTANT: Backup your database before running this script!
-- Estimated runtime: 5-15 minutes depending on item count
-- ============================================================================

SET @start_time = NOW();
SET SESSION sql_mode = '';

-- ============================================================================
-- STEP 1: Create tier mapping tables
-- ============================================================================

CREATE TABLE IF NOT EXISTS item_tier_map (
  base_item_id     INT NOT NULL,
  tier_code        TINYINT NOT NULL COMMENT '0=Normal,1=Enhanced,2=Exalted,3=Ascendant',
  variant_item_id  INT NOT NULL,
  power_score      FLOAT DEFAULT 0 COMMENT 'Calculated power score for reference',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (base_item_id, tier_code),
  UNIQUE KEY uq_variant (variant_item_id),
  KEY idx_base (base_item_id),
  KEY idx_tier (tier_code)
) ENGINE=InnoDB COMMENT='Maps base items to their tier variants';

CREATE TABLE IF NOT EXISTS tier_defs (
  tier_code TINYINT PRIMARY KEY,
  tier_name VARCHAR(32) NOT NULL,
  display_name VARCHAR(64) NOT NULL COMMENT 'Display name for UI/loot messages'
) ENGINE=InnoDB COMMENT='Tier definitions';

INSERT IGNORE INTO tier_defs VALUES
(0, 'Normal', 'Normal'),
(1, 'Enhanced', 'Enhanced'),
(2, 'Exalted', 'Exalted'),
(3, 'Ascendant', 'Ascendant');

SELECT CONCAT('✓ Tier tables created at ', NOW()) AS status;

-- ============================================================================
-- STEP 2: Create eligibility views
-- ============================================================================

-- Drop existing views if they exist
DROP VIEW IF EXISTS eligible_gear;
DROP VIEW IF EXISTS eligible_bags;
DROP VIEW IF EXISTS eligible_all_items;

-- Eligible gear: equipable items (armor, weapons, jewelry, etc.)
CREATE VIEW eligible_gear AS
SELECT
    id,
    Name,
    slots,
    classes,
    races,
    itemclass,
    itemtype,
    reqlevel,
    -- Core stats
    ac, hp, mana, endur,
    astr, asta, adex, aagi, aint, awis, acha,
    -- Resists
    cr, dr, fr, mr, pr, svcorruption,
    -- Combat stats
    accuracy, attack, avoidance, strikethrough,
    damage, delay,
    -- Regen
    regen, manaregen, enduranceregen,
    -- Shielding
    shielding, spellshield, dotshielding,
    -- Heroics
    heroic_str, heroic_int, heroic_wis, heroic_agi,
    heroic_dex, heroic_sta, heroic_cha,
    heroic_pr, heroic_dr, heroic_fr, heroic_cr, heroic_mr, heroic_svcorrup,
    -- Spell damage
    spelldmg, healamt, clairvoyance,
    -- Effects
    proceffect, clickeffect, worneffect, focuseffect,
    haste,
    -- Flags
    nodrop, norent, notransfer, loregroup, attuneable
FROM items
WHERE slots > 0                    -- Has equipment slots
  AND classes > 0                  -- Has class restrictions
  AND itemclass NOT IN (
      1,   -- Container (handled separately)
      2,   -- Book
      10,  -- Food
      11,  -- Drink
      12,  -- Light source
      14,  -- Potion
      15,  -- Scroll (spell scroll)
      16,  -- Bandage
      17,  -- Throwing
      18,  -- Arrow
      19,  -- Augment (handle separately)
      20,  -- Augment solvent
      21,  -- Augment distiller
      22,  -- Perfected augment distiller
      23,  -- Purity augment distiller
      24,  -- Ornamentation
      25,  -- Evolving item (handle separately)
      26,  -- Mercenary equipment
      27,  -- Mount
      28,  -- Illusion
      29,  -- Familiar
      30,  -- Teleport item
      31,  -- Recipe
      32,  -- Alternate currency
      33,  -- Collectible
      34,  -- Parcel
      35,  -- Housing
      36,  -- Real estate
      37,  -- Placeable
      38,  -- Bait
      39,  -- Fishing pole
      40,  -- Fishing lure
      41,  -- Fishing tackle
      42,  -- Fishing reel
      43,  -- Fishing line
      44,  -- Fishing hook
      45,  -- Fishing sinker
      46,  -- Fishing bobber
      47,  -- Fishing net
      48,  -- Fishing trap
      49,  -- Fishing spear
      50,  -- Fishing bait container
      51,  -- Fishing tackle box
      52,  -- Fishing rod holder
      53,  -- Fishing cooler
      54   -- Fishing creel
  )
  AND id NOT IN (SELECT variant_item_id FROM item_tier_map WHERE variant_item_id IS NOT NULL)
  AND id < 10000000;  -- Only base items (variants will be 10M+)

-- Eligible bags: containers with separate scaling rules
CREATE VIEW eligible_bags AS
SELECT
    id,
    Name,
    bagslots,
    bagwr,
    bagsize,
    bagtype,
    itemclass,
    reqlevel,
    slots,
    classes
FROM items
WHERE itemclass = 1               -- Container
  AND bagslots > 0
  AND id NOT IN (SELECT variant_item_id FROM item_tier_map WHERE variant_item_id IS NOT NULL)
  AND id < 10000000;

-- Combined view for counting
CREATE VIEW eligible_all_items AS
SELECT id, Name, 'gear' AS item_category FROM eligible_gear
UNION ALL
SELECT id, Name, 'bag' AS item_category FROM eligible_bags;

SELECT CONCAT('✓ Eligibility views created at ', NOW()) AS status;

-- ============================================================================
-- STEP 3: Pre-flight checks and statistics
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'PRE-FLIGHT CHECKS' AS '';
SELECT '============================================================================' AS '';

-- Count eligible items
SELECT
    item_category,
    COUNT(*) AS eligible_count
FROM eligible_all_items
GROUP BY item_category
WITH ROLLUP;

-- Check current max item ID
SELECT
    MAX(id) AS current_max_item_id,
    CASE
        WHEN MAX(id) < 10000000 THEN '✓ Safe to use 10M+ offsets'
        ELSE '⚠ WARNING: Items exist above 10M - adjust offsets!'
    END AS id_space_check
FROM items;

-- Check for existing tier mappings
SELECT
    COUNT(*) AS existing_tier_mappings,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ No existing mappings - clean slate'
        ELSE '⚠ Existing mappings found - will skip duplicates'
    END AS mapping_check
FROM item_tier_map;

SELECT '============================================================================' AS '';
SELECT 'Ready to generate tiers. Press any key to continue or Ctrl+C to abort...' AS '';
SELECT '============================================================================' AS '';

-- Pause point - user can review before continuing
-- In HeidiSQL, you can execute up to here first, review, then continue

-- ============================================================================
-- STEP 4: Helper function - Calculate power score
-- ============================================================================

-- Power score calculation for determining scaling behavior
-- P_wear = (AC*4) + (HP*1.0) + (Mana*0.9) + (End*0.8) + (StatSum*6) +
--          (ResistSum*2) + (Accuracy*10) + (Attack*2) + (HPRegen*30) +
--          (ManaRegen*30) + (EndRegen*20) + (Shielding*25) + (SpellShield*25) +
--          (DotShielding*25) + (Strikethrough*12)

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
    DECLARE power_score FLOAT;

    SET stat_sum = COALESCE(p_str,0) + COALESCE(p_sta,0) + COALESCE(p_dex,0) +
                   COALESCE(p_agi,0) + COALESCE(p_int,0) + COALESCE(p_wis,0) +
                   COALESCE(p_cha,0);

    SET resist_sum = COALESCE(p_cr,0) + COALESCE(p_dr,0) + COALESCE(p_fr,0) +
                     COALESCE(p_mr,0) + COALESCE(p_pr,0) + COALESCE(p_svcorr,0);

    SET power_score =
        (COALESCE(p_ac,0) * 4) +
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

    RETURN power_score;
END$$
DELIMITER ;

SELECT CONCAT('✓ Power score function created at ', NOW()) AS status;

-- ============================================================================
-- STEP 5: Generate Tier 1 (Enhanced) variants
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'GENERATING TIER 1 (Enhanced) VARIANTS...' AS '';
SELECT '============================================================================' AS '';

-- Tier 1 multipliers: AC×1.10, HP/Mana/End×1.18, Stats×1.10, Damage×1.03
-- ID offset: +10000000

INSERT INTO items (
    id, minstatus, Name,
    -- Stats
    aagi, ac, accuracy, acha, adex, aint, asta, astr, attack,
    -- Resists
    cr, dr, fr, mr, pr, svcorruption,
    -- Sustain
    hp, mana, endur, regen, manaregen, enduranceregen,
    -- Shielding
    shielding, spellshield, dotshielding,
    -- Combat
    damage, delay, strikethrough, avoidance,
    -- Heroics (unchanged at T1)
    heroic_str, heroic_int, heroic_wis, heroic_agi, heroic_dex, heroic_sta, heroic_cha,
    heroic_pr, heroic_dr, heroic_fr, heroic_cr, heroic_mr, heroic_svcorrup,
    -- Spell damage (unchanged at T1)
    spelldmg, healamt, clairvoyance, backstabdmg,
    -- Bags (separate scaling)
    bagslots, bagwr, bagsize, bagtype,
    -- Effects (unchanged)
    proceffect, clickeffect, worneffect, focuseffect, scrolleffect, bardeffect,
    haste, -- FROZEN to base value
    -- All other fields copied exactly
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
    i.Name, -- Keep original name, tier shown via metadata
    -- Stats: ×1.10 with injection floor
    GREATEST(FLOOR(COALESCE(i.aagi,0) * 1.10), CASE WHEN COALESCE(i.aagi,0) = 0 AND i.itemclass != 1 THEN 1 ELSE 0 END) AS aagi,
    FLOOR(COALESCE(i.ac,0) * 1.10) AS ac,
    FLOOR(COALESCE(i.accuracy,0) * 1.10) AS accuracy,
    GREATEST(FLOOR(COALESCE(i.acha,0) * 1.10), CASE WHEN COALESCE(i.acha,0) = 0 AND i.itemclass != 1 THEN 1 ELSE 0 END) AS acha,
    GREATEST(FLOOR(COALESCE(i.adex,0) * 1.10), CASE WHEN COALESCE(i.adex,0) = 0 AND i.itemclass != 1 THEN 1 ELSE 0 END) AS adex,
    GREATEST(FLOOR(COALESCE(i.aint,0) * 1.10), CASE WHEN COALESCE(i.aint,0) = 0 AND i.itemclass != 1 THEN 1 ELSE 0 END) AS aint,
    GREATEST(FLOOR(COALESCE(i.asta,0) * 1.10), CASE WHEN COALESCE(i.asta,0) = 0 AND i.itemclass != 1 THEN 1 ELSE 0 END) AS asta,
    GREATEST(FLOOR(COALESCE(i.astr,0) * 1.10), CASE WHEN COALESCE(i.astr,0) = 0 AND i.itemclass != 1 THEN 1 ELSE 0 END) AS astr,
    FLOOR(COALESCE(i.attack,0) * 1.10) AS attack,
    -- Resists: ×1.10
    FLOOR(COALESCE(i.cr,0) * 1.10) AS cr,
    FLOOR(COALESCE(i.dr,0) * 1.10) AS dr,
    FLOOR(COALESCE(i.fr,0) * 1.10) AS fr,
    FLOOR(COALESCE(i.mr,0) * 1.10) AS mr,
    FLOOR(COALESCE(i.pr,0) * 1.10) AS pr,
    FLOOR(COALESCE(i.svcorruption,0) * 1.10) AS svcorruption,
    -- Sustain: ×1.18 with injection floor
    GREATEST(FLOOR(COALESCE(i.hp,0) * 1.18), CASE WHEN COALESCE(i.hp,0) < 20 AND i.itemclass != 1 THEN 15 ELSE 0 END) AS hp,
    GREATEST(FLOOR(COALESCE(i.mana,0) * 1.18), CASE WHEN COALESCE(i.mana,0) < 20 AND i.itemclass != 1 THEN 15 ELSE 0 END) AS mana,
    GREATEST(FLOOR(COALESCE(i.endur,0) * 1.18), CASE WHEN COALESCE(i.endur,0) < 20 AND i.itemclass != 1 THEN 15 ELSE 0 END) AS endur,
    FLOOR(COALESCE(i.regen,0) * 1.18) AS regen,
    FLOOR(COALESCE(i.manaregen,0) * 1.18) AS manaregen,
    FLOOR(COALESCE(i.enduranceregen,0) * 1.18) AS enduranceregen,
    -- Shielding: ×1.10
    FLOOR(COALESCE(i.shielding,0) * 1.10) AS shielding,
    FLOOR(COALESCE(i.spellshield,0) * 1.10) AS spellshield,
    FLOOR(COALESCE(i.dotshielding,0) * 1.10) AS dotshielding,
    -- Weapon damage: ×1.03 (small increase), delay FROZEN
    CASE WHEN i.delay > 0 THEN FLOOR(COALESCE(i.damage,0) * 1.03) ELSE i.damage END AS damage,
    i.delay, -- NEVER CHANGE DELAY
    FLOOR(COALESCE(i.strikethrough,0) * 1.10) AS strikethrough,
    FLOOR(COALESCE(i.avoidance,0) * 1.10) AS avoidance,
    -- Heroics: unchanged at T1
    i.heroic_str, i.heroic_int, i.heroic_wis, i.heroic_agi, i.heroic_dex, i.heroic_sta, i.heroic_cha,
    i.heroic_pr, i.heroic_dr, i.heroic_fr, i.heroic_cr, i.heroic_mr, i.heroic_svcorrup,
    -- Spell damage: unchanged at T1
    i.spelldmg, i.healamt, i.clairvoyance, i.backstabdmg,
    -- Bags: +2 slots (cap 12), +5 WR (cap 25)
    CASE WHEN i.itemclass = 1 THEN LEAST(COALESCE(i.bagslots,0) + 2, 12) ELSE i.bagslots END AS bagslots,
    CASE WHEN i.itemclass = 1 THEN LEAST(COALESCE(i.bagwr,0) + 5, 25) ELSE i.bagwr END AS bagwr,
    i.bagsize, i.bagtype,
    -- Effects: unchanged
    i.proceffect, i.clickeffect, i.worneffect, i.focuseffect, i.scrolleffect, i.bardeffect,
    i.haste, -- FROZEN
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
    CONCAT('T1 Enhanced variant of item ', i.id) AS comment,
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
FROM eligible_all_items e
JOIN items i ON e.id = i.id
WHERE NOT EXISTS (
    SELECT 1 FROM item_tier_map
    WHERE base_item_id = i.id AND tier_code = 1
);

-- Record T1 mappings
INSERT INTO item_tier_map (base_item_id, tier_code, variant_item_id, power_score)
SELECT
    i.id,
    1 AS tier_code,
    i.id + 10000000 AS variant_item_id,
    calculate_power_score(
        i.ac, i.hp, i.mana, i.endur,
        i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha,
        i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption,
        i.accuracy, i.attack, i.strikethrough,
        i.regen, i.manaregen, i.enduranceregen,
        i.shielding, i.spellshield, i.dotshielding
    ) AS power_score
FROM eligible_all_items e
JOIN items i ON e.id = i.id
WHERE NOT EXISTS (
    SELECT 1 FROM item_tier_map
    WHERE base_item_id = i.id AND tier_code = 1
);

SELECT CONCAT('✓ Tier 1 (Enhanced) generated: ', ROW_COUNT(), ' items at ', NOW()) AS status;

