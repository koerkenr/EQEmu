-- ============================================================================
-- Generate T2 and T3 Bags (Containers)
-- ============================================================================
-- This script generates T2 and T3 bag variants from T1 bags
-- Bags get increased slots and weight reduction, no combat stats
-- ============================================================================

SET @start_time = NOW();
SET SESSION sql_mode = '';

-- Use existing generation run ID or create new one
SET @generation_run_id = CONCAT('bags_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'));

SELECT '============================================================================' AS '';
SELECT 'GENERATING T2 AND T3 BAG VARIANTS...' AS '';
SELECT '============================================================================' AS '';

-- ============================================================================
-- CLEANUP: Remove existing T2 and T3 bags to avoid duplicates
-- ============================================================================

SELECT 'Cleaning up existing T2/T3 bags...' AS status;

-- Delete existing T3 bag items
DELETE FROM items
WHERE id IN (
    SELECT variant_item_id
    FROM item_tier_map
    WHERE tier_code = 3 AND item_category = 'bag'
);

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' existing T3 bag items') AS status;

-- Delete existing T3 bag mappings
DELETE FROM item_tier_map
WHERE tier_code = 3 AND item_category = 'bag';

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' existing T3 bag mappings') AS status;

-- Delete existing T2 bag items
DELETE FROM items
WHERE id IN (
    SELECT variant_item_id
    FROM item_tier_map
    WHERE tier_code = 2 AND item_category = 'bag'
);

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' existing T2 bag items') AS status;

-- Delete existing T2 bag mappings
DELETE FROM item_tier_map
WHERE tier_code = 2 AND item_category = 'bag';

SELECT CONCAT('✓ Deleted ', ROW_COUNT(), ' existing T2 bag mappings') AS status;

-- ============================================================================
-- TIER 2 (Exalted) BAGS - Build on T1 bags
-- ============================================================================

SELECT 'Generating T2 (Exalted) bags...' AS status;

-- Generate T2 bags from T1 bags
INSERT INTO items (
    id, minstatus, Name,
    aagi, ac, accuracy, acha, adex, aint, asta, astr, awis, attack,
    cr, dr, fr, mr, pr, svcorruption,
    hp, mana, endur, regen, manaregen, enduranceregen,
    shielding, spellshield, dotshielding,
    damage, delay, strikethrough, avoidance, stunresist,
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
    filename, fvnodrop, clicklevel, icon, idfile,
    itemclass, itemtype, ldonprice, ldontheme, ldonsold, light, lore, loregroup,
    magic, material, herosforgemodel, maxcharges, nodrop, norent,
    pendingloreflag, procrate, races, `range`, reclevel, recskill, reqlevel,
    sellrate, size, skillmodtype, skillmodvalue, slots,
    summonedflag, tradeskills, favor, weight,
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
    base.id + 500000 AS id,
    t1.minstatus,
    CONCAT(REPLACE(REPLACE(t1.Name, CHAR(0x12), ''), ' (Enhanced)', ''), ' ', CHAR(0x1A), '(Exalted)', CHAR(0x12)) AS Name,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- zero all combat stats
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0,
    -- Bag stats: +2 slots (cap 14), improved WR
    LEAST(t1.bagslots + 2, 14) AS bagslots,
    CASE
        WHEN t1.bagwr < 50 THEN LEAST(t1.bagwr + 10, 50)
        ELSE LEAST(t1.bagwr + 10, 90)
    END AS bagwr,
    t1.bagsize,
    t1.bagtype,
    t1.proceffect, t1.clickeffect, t1.worneffect, t1.focuseffect, t1.scrolleffect, t1.bardeffect,
    t1.haste,
    t1.artifactflag, t1.augrestrict,
    t1.augslot1type, t1.augslot1visible, t1.augslot2type, t1.augslot2visible,
    t1.augslot3type, t1.augslot3visible, t1.augslot4type, t1.augslot4visible,
    t1.augslot5type, t1.augslot5visible, t1.augslot6type, t1.augslot6visible,
    t1.augtype, t1.banedmgamt, t1.banedmgraceamt, t1.banedmgbody, t1.banedmgrace,
    t1.bardtype, t1.bardvalue, t1.book, t1.casttime, t1.casttime_, t1.charmfile, t1.charmfileid,
    t1.classes, t1.color, t1.combateffects, t1.extradmgskill, t1.extradmgamt, t1.price,
    t1.damageshield, t1.deity, t1.augdistiller, t1.clicktype, t1.clicklevel2,
    t1.elemdmgtype, t1.elemdmgamt,
    t1.factionamt1, t1.factionamt2, t1.factionamt3, t1.factionamt4,
    t1.factionmod1, t1.factionmod2, t1.factionmod3, t1.factionmod4,
    t1.filename, t1.fvnodrop, t1.clicklevel, t1.icon, t1.idfile,
    t1.itemclass, t1.itemtype, t1.ldonprice, t1.ldontheme, t1.ldonsold, t1.light, t1.lore, t1.loregroup,
    t1.magic, t1.material, t1.herosforgemodel, t1.maxcharges, t1.nodrop, t1.norent,
    t1.pendingloreflag, t1.procrate, t1.races, t1.`range`, t1.reclevel, t1.recskill, t1.reqlevel,
    t1.sellrate, t1.size, t1.skillmodtype, t1.skillmodvalue, t1.slots,
    t1.summonedflag, t1.tradeskills, t1.favor, t1.weight,
    t1.UNK012, t1.UNK013, t1.benefitflag, t1.UNK054, t1.UNK059, t1.booktype,
    t1.recastdelay, t1.recasttype, t1.guildfavor, t1.UNK123, t1.UNK124, t1.attuneable, t1.nopet,
    NOW() AS updated,
    CONCAT('T2 Exalted bag variant of item ', base.id, ' - ', @generation_run_id) AS comment,
    t1.UNK127, t1.pointtype, t1.potionbelt, t1.potionbeltslots,
    t1.stacksize, t1.notransfer, t1.stackable, t1.UNK134, t1.UNK137,
    t1.proctype, t1.proclevel2, t1.proclevel, t1.UNK142,
    t1.worntype, t1.wornlevel2, t1.wornlevel, t1.UNK147,
    t1.focustype, t1.focuslevel2, t1.focuslevel, t1.UNK152,
    t1.scrolltype, t1.scrolllevel2, t1.scrolllevel, t1.UNK157,
    t1.serialized, t1.verified, t1.serialization, t1.source, t1.UNK033, t1.lorefile, t1.UNK014,
    t1.skillmodmax, t1.UNK060,
    t1.augslot1unk2, t1.augslot2unk2, t1.augslot3unk2, t1.augslot4unk2, t1.augslot5unk2, t1.augslot6unk2,
    t1.UNK120, t1.UNK121, t1.questitemflag, t1.UNK132,
    t1.clickunk5, t1.clickunk6, t1.clickunk7,
    t1.procunk1, t1.procunk2, t1.procunk3, t1.procunk4, t1.procunk6, t1.procunk7,
    t1.wornunk1, t1.wornunk2, t1.wornunk3, t1.wornunk4, t1.wornunk5, t1.wornunk6, t1.wornunk7,
    t1.focusunk1, t1.focusunk2, t1.focusunk3, t1.focusunk4, t1.focusunk5, t1.focusunk6, t1.focusunk7,
    t1.scrollunk1, t1.scrollunk2, t1.scrollunk3, t1.scrollunk4, t1.scrollunk5, t1.scrollunk6, t1.scrollunk7,
    t1.UNK193, t1.purity, t1.evoitem, t1.evoid, t1.evolvinglevel, t1.evomax,
    t1.clickname, t1.procname, t1.wornname, t1.focusname, t1.scrollname, t1.bardname,
    t1.dsmitigation, t1.created, t1.elitematerial, t1.ldonsellbackrate, t1.scriptfileid,
    t1.expendablearrow, t1.powersourcecapacity, t1.bardeffecttype, t1.bardlevel2, t1.bardlevel,
    t1.bardunk1, t1.bardunk2, t1.bardunk3, t1.bardunk4, t1.bardunk5, t1.bardunk7,
    t1.UNK214, t1.subtype, t1.UNK220, t1.UNK221, t1.heirloom,
    t1.UNK223, t1.UNK224, t1.UNK225, t1.UNK226, t1.UNK227, t1.UNK228, t1.UNK229, t1.UNK230,
    t1.UNK231, t1.UNK232, t1.UNK233, t1.UNK234, t1.placeable, t1.UNK236, t1.UNK237, t1.UNK238,
    t1.UNK239, t1.UNK240, t1.UNK241, t1.epicitem
FROM items base
JOIN item_tier_map itm ON itm.base_item_id = base.id AND itm.tier_code = 1 AND itm.item_category = 'bag'
JOIN items t1 ON t1.id = itm.variant_item_id
WHERE NOT EXISTS (SELECT 1 FROM item_tier_map WHERE base_item_id = base.id AND tier_code = 2 AND item_category = 'bag')
AND NOT EXISTS (SELECT 1 FROM items WHERE id = base.id + 500000);

SELECT CONCAT('✓ T2 bags generated: ', ROW_COUNT(), ' items') AS status;

-- Record T2 bag mappings
INSERT INTO item_tier_map (base_item_id, tier_code, variant_item_id, power_score, item_category, generation_run_id)
SELECT
    base.id,
    2,
    base.id + 500000,
    0,
    'bag',
    @generation_run_id
FROM items base
JOIN item_tier_map itm ON itm.base_item_id = base.id AND itm.tier_code = 1 AND itm.item_category = 'bag'
WHERE EXISTS (SELECT 1 FROM items WHERE id = base.id + 500000);

SELECT CONCAT('✓ T2 bag mappings recorded: ', ROW_COUNT()) AS status;

-- ============================================================================
-- TIER 3 (Ascendant) BAGS - Build on T2 bags
-- ============================================================================

SELECT 'Generating T3 (Ascendant) bags...' AS status;

-- Generate T3 bags from T2 bags
INSERT INTO items (
    id, minstatus, Name,
    aagi, ac, accuracy, acha, adex, aint, asta, astr, awis, attack,
    cr, dr, fr, mr, pr, svcorruption,
    hp, mana, endur, regen, manaregen, enduranceregen,
    shielding, spellshield, dotshielding,
    damage, delay, strikethrough, avoidance, stunresist,
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
    filename, fvnodrop, clicklevel, icon, idfile,
    itemclass, itemtype, ldonprice, ldontheme, ldonsold, light, lore, loregroup,
    magic, material, herosforgemodel, maxcharges, nodrop, norent,
    pendingloreflag, procrate, races, `range`, reclevel, recskill, reqlevel,
    sellrate, size, skillmodtype, skillmodvalue, slots,
    summonedflag, tradeskills, favor, weight,
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
    base.id + 700000 AS id,
    t2.minstatus,
    CONCAT(REPLACE(REPLACE(REPLACE(t2.Name, CHAR(0x1A), ''), CHAR(0x12), ''), ' (Exalted)', ''), ' ', CHAR(0x0A), '(Ascendant)', CHAR(0x12)) AS Name,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- zero all combat stats
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0,
    0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    0, 0, 0, 0,
    -- Bag stats: +2 slots (cap 16), improved WR
    LEAST(t2.bagslots + 2, 16) AS bagslots,
    CASE
        WHEN t2.bagwr < 50 THEN LEAST(t2.bagwr + 10, 50)
        ELSE LEAST(t2.bagwr + 10, 90)
    END AS bagwr,
    t2.bagsize,
    t2.bagtype,
    t2.proceffect, t2.clickeffect, t2.worneffect, t2.focuseffect, t2.scrolleffect, t2.bardeffect,
    t2.haste,
    t2.artifactflag, t2.augrestrict,
    t2.augslot1type, t2.augslot1visible, t2.augslot2type, t2.augslot2visible,
    t2.augslot3type, t2.augslot3visible, t2.augslot4type, t2.augslot4visible,
    t2.augslot5type, t2.augslot5visible, t2.augslot6type, t2.augslot6visible,
    t2.augtype, t2.banedmgamt, t2.banedmgraceamt, t2.banedmgbody, t2.banedmgrace,
    t2.bardtype, t2.bardvalue, t2.book, t2.casttime, t2.casttime_, t2.charmfile, t2.charmfileid,
    t2.classes, t2.color, t2.combateffects, t2.extradmgskill, t2.extradmgamt, t2.price,
    t2.damageshield, t2.deity, t2.augdistiller, t2.clicktype, t2.clicklevel2,
    t2.elemdmgtype, t2.elemdmgamt,
    t2.factionamt1, t2.factionamt2, t2.factionamt3, t2.factionamt4,
    t2.factionmod1, t2.factionmod2, t2.factionmod3, t2.factionmod4,
    t2.filename, t2.fvnodrop, t2.clicklevel, t2.icon, t2.idfile,
    t2.itemclass, t2.itemtype, t2.ldonprice, t2.ldontheme, t2.ldonsold, t2.light, t2.lore, t2.loregroup,
    t2.magic, t2.material, t2.herosforgemodel, t2.maxcharges, t2.nodrop, t2.norent,
    t2.pendingloreflag, t2.procrate, t2.races, t2.`range`, t2.reclevel, t2.recskill, t2.reqlevel,
    t2.sellrate, t2.size, t2.skillmodtype, t2.skillmodvalue, t2.slots,
    t2.summonedflag, t2.tradeskills, t2.favor, t2.weight,
    t2.UNK012, t2.UNK013, t2.benefitflag, t2.UNK054, t2.UNK059, t2.booktype,
    t2.recastdelay, t2.recasttype, t2.guildfavor, t2.UNK123, t2.UNK124, t2.attuneable, t2.nopet,
    NOW() AS updated,
    CONCAT('T3 Ascendant bag variant of item ', base.id, ' - ', @generation_run_id) AS comment,
    t2.UNK127, t2.pointtype, t2.potionbelt, t2.potionbeltslots,
    t2.stacksize, t2.notransfer, t2.stackable, t2.UNK134, t2.UNK137,
    t2.proctype, t2.proclevel2, t2.proclevel, t2.UNK142,
    t2.worntype, t2.wornlevel2, t2.wornlevel, t2.UNK147,
    t2.focustype, t2.focuslevel2, t2.focuslevel, t2.UNK152,
    t2.scrolltype, t2.scrolllevel2, t2.scrolllevel, t2.UNK157,
    t2.serialized, t2.verified, t2.serialization, t2.source, t2.UNK033, t2.lorefile, t2.UNK014,
    t2.skillmodmax, t2.UNK060,
    t2.augslot1unk2, t2.augslot2unk2, t2.augslot3unk2, t2.augslot4unk2, t2.augslot5unk2, t2.augslot6unk2,
    t2.UNK120, t2.UNK121, t2.questitemflag, t2.UNK132,
    t2.clickunk5, t2.clickunk6, t2.clickunk7,
    t2.procunk1, t2.procunk2, t2.procunk3, t2.procunk4, t2.procunk6, t2.procunk7,
    t2.wornunk1, t2.wornunk2, t2.wornunk3, t2.wornunk4, t2.wornunk5, t2.wornunk6, t2.wornunk7,
    t2.focusunk1, t2.focusunk2, t2.focusunk3, t2.focusunk4, t2.focusunk5, t2.focusunk6, t2.focusunk7,
    t2.scrollunk1, t2.scrollunk2, t2.scrollunk3, t2.scrollunk4, t2.scrollunk5, t2.scrollunk6, t2.scrollunk7,
    t2.UNK193, t2.purity, t2.evoitem, t2.evoid, t2.evolvinglevel, t2.evomax,
    t2.clickname, t2.procname, t2.wornname, t2.focusname, t2.scrollname, t2.bardname,
    t2.dsmitigation, t2.created, t2.elitematerial, t2.ldonsellbackrate, t2.scriptfileid,
    t2.expendablearrow, t2.powersourcecapacity, t2.bardeffecttype, t2.bardlevel2, t2.bardlevel,
    t2.bardunk1, t2.bardunk2, t2.bardunk3, t2.bardunk4, t2.bardunk5, t2.bardunk7,
    t2.UNK214, t2.subtype, t2.UNK220, t2.UNK221, t2.heirloom,
    t2.UNK223, t2.UNK224, t2.UNK225, t2.UNK226, t2.UNK227, t2.UNK228, t2.UNK229, t2.UNK230,
    t2.UNK231, t2.UNK232, t2.UNK233, t2.UNK234, t2.placeable, t2.UNK236, t2.UNK237, t2.UNK238,
    t2.UNK239, t2.UNK240, t2.UNK241, t2.epicitem
FROM items base
JOIN item_tier_map itm ON itm.base_item_id = base.id AND itm.tier_code = 2 AND itm.item_category = 'bag'
JOIN items t2 ON t2.id = itm.variant_item_id
WHERE NOT EXISTS (SELECT 1 FROM item_tier_map WHERE base_item_id = base.id AND tier_code = 3 AND item_category = 'bag')
AND NOT EXISTS (SELECT 1 FROM items WHERE id = base.id + 700000);

SELECT CONCAT('✓ T3 bags generated: ', ROW_COUNT(), ' items') AS status;

-- Record T3 bag mappings
INSERT INTO item_tier_map (base_item_id, tier_code, variant_item_id, power_score, item_category, generation_run_id)
SELECT
    base.id,
    3,
    base.id + 700000,
    0,
    'bag',
    @generation_run_id
FROM items base
JOIN item_tier_map itm ON itm.base_item_id = base.id AND itm.tier_code = 2 AND itm.item_category = 'bag'
WHERE EXISTS (SELECT 1 FROM items WHERE id = base.id + 700000);

SELECT CONCAT('✓ T3 bag mappings recorded: ', ROW_COUNT()) AS status;

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'T2/T3 BAG GENERATION COMPLETE!' AS '';
SELECT '============================================================================' AS '';

SELECT
    tier_code,
    CASE tier_code
        WHEN 2 THEN 'Exalted (T2)'
        WHEN 3 THEN 'Ascendant (T3)'
    END AS tier_name,
    COUNT(*) AS bag_count
FROM item_tier_map
WHERE tier_code IN (2, 3) AND item_category = 'bag'
GROUP BY tier_code;

SELECT CONCAT('✓ Total execution time: ', TIMESTAMPDIFF(SECOND, @start_time, NOW()), ' seconds') AS timing;
