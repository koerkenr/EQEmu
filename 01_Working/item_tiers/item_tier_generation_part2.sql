-- ============================================================================
-- EQEmu Item Tiering System - Part 2: Tier 2 & 3 Generation
-- ============================================================================
-- Execute this AFTER item_tier_generation.sql completes successfully
-- ============================================================================

-- ============================================================================
-- STEP 6: Generate Tier 2 (Exalted) variants
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'GENERATING TIER 2 (Exalted) VARIANTS...' AS '';
SELECT '============================================================================' AS '';

-- Tier 2 multipliers: AC×1.22, HP/Mana/End×1.45, Stats×1.22, Damage×1.06
-- Heroics: +1 point for high-power items
-- ID offset: +20000000

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
    i.id + 20000000 AS id,
    i.minstatus,
    i.Name,
    -- Stats: ×1.22 with injection floor
    GREATEST(FLOOR(COALESCE(i.aagi,0) * 1.22), CASE WHEN COALESCE(i.aagi,0) = 0 AND i.itemclass != 1 THEN 2 ELSE 0 END) AS aagi,
    FLOOR(COALESCE(i.ac,0) * 1.22) AS ac,
    FLOOR(COALESCE(i.accuracy,0) * 1.22) AS accuracy,
    GREATEST(FLOOR(COALESCE(i.acha,0) * 1.22), CASE WHEN COALESCE(i.acha,0) = 0 AND i.itemclass != 1 THEN 2 ELSE 0 END) AS acha,
    GREATEST(FLOOR(COALESCE(i.adex,0) * 1.22), CASE WHEN COALESCE(i.adex,0) = 0 AND i.itemclass != 1 THEN 2 ELSE 0 END) AS adex,
    GREATEST(FLOOR(COALESCE(i.aint,0) * 1.22), CASE WHEN COALESCE(i.aint,0) = 0 AND i.itemclass != 1 THEN 2 ELSE 0 END) AS aint,
    GREATEST(FLOOR(COALESCE(i.asta,0) * 1.22), CASE WHEN COALESCE(i.asta,0) = 0 AND i.itemclass != 1 THEN 2 ELSE 0 END) AS asta,
    GREATEST(FLOOR(COALESCE(i.astr,0) * 1.22), CASE WHEN COALESCE(i.astr,0) = 0 AND i.itemclass != 1 THEN 2 ELSE 0 END) AS astr,
    FLOOR(COALESCE(i.attack,0) * 1.22) AS attack,
    -- Resists: ×1.22
    FLOOR(COALESCE(i.cr,0) * 1.22) AS cr,
    FLOOR(COALESCE(i.dr,0) * 1.22) AS dr,
    FLOOR(COALESCE(i.fr,0) * 1.22) AS fr,
    FLOOR(COALESCE(i.mr,0) * 1.22) AS mr,
    FLOOR(COALESCE(i.pr,0) * 1.22) AS pr,
    FLOOR(COALESCE(i.svcorruption,0) * 1.22) AS svcorruption,
    -- Sustain: ×1.45 with injection floor
    GREATEST(FLOOR(COALESCE(i.hp,0) * 1.45), CASE WHEN COALESCE(i.hp,0) < 30 AND i.itemclass != 1 THEN 50 ELSE 0 END) AS hp,
    GREATEST(FLOOR(COALESCE(i.mana,0) * 1.45), CASE WHEN COALESCE(i.mana,0) < 30 AND i.itemclass != 1 THEN 50 ELSE 0 END) AS mana,
    GREATEST(FLOOR(COALESCE(i.endur,0) * 1.45), CASE WHEN COALESCE(i.endur,0) < 30 AND i.itemclass != 1 THEN 50 ELSE 0 END) AS endur,
    LEAST(FLOOR(COALESCE(i.regen,0) * 1.45), 5) AS regen,
    LEAST(FLOOR(COALESCE(i.manaregen,0) * 1.45), 5) AS manaregen,
    LEAST(FLOOR(COALESCE(i.enduranceregen,0) * 1.45), 5) AS enduranceregen,
    -- Shielding: ×1.22, capped at 10
    LEAST(FLOOR(COALESCE(i.shielding,0) * 1.22), 10) AS shielding,
    LEAST(FLOOR(COALESCE(i.spellshield,0) * 1.22), 10) AS spellshield,
    LEAST(FLOOR(COALESCE(i.dotshielding,0) * 1.22), 10) AS dotshielding,
    -- Weapon damage: ×1.06, delay FROZEN
    CASE WHEN i.delay > 0 THEN FLOOR(COALESCE(i.damage,0) * 1.06) ELSE i.damage END AS damage,
    i.delay,
    FLOOR(COALESCE(i.strikethrough,0) * 1.22) AS strikethrough,
    FLOOR(COALESCE(i.avoidance,0) * 1.22) AS avoidance,
    -- Heroics: +1 point for items with power_score > 500 (high-tier items)
    -- Tank items: hSTA primary
    CASE WHEN (i.classes & 1) > 0 AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 500
         THEN COALESCE(i.heroic_str,0) ELSE i.heroic_str END AS heroic_str,
    -- Caster items: hINT or hWIS
    CASE WHEN ((i.classes & 256) > 0 OR (i.classes & 2048) > 0) AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 500
         THEN COALESCE(i.heroic_int,0) + 1 ELSE i.heroic_int END AS heroic_int,
    CASE WHEN ((i.classes & 2) > 0 OR (i.classes & 4) > 0) AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 500
         THEN COALESCE(i.heroic_wis,0) + 1 ELSE i.heroic_wis END AS heroic_wis,
    -- Melee items: hAGI secondary for tanks
    CASE WHEN (i.classes & 1) > 0 AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 500
         THEN COALESCE(i.heroic_agi,0) ELSE i.heroic_agi END AS heroic_agi,
    -- Melee DPS: hDEX primary
    CASE WHEN ((i.classes & 8) > 0 OR (i.classes & 16) > 0 OR (i.classes & 32) > 0) AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 500
         THEN COALESCE(i.heroic_dex,0) + 1 ELSE i.heroic_dex END AS heroic_dex,
    -- Tank items: hSTA primary
    CASE WHEN (i.classes & 1) > 0 AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 500
         THEN COALESCE(i.heroic_sta,0) + 1 ELSE i.heroic_sta END AS heroic_sta,
    i.heroic_cha,
    i.heroic_pr, i.heroic_dr, i.heroic_fr, i.heroic_cr, i.heroic_mr, i.heroic_svcorrup,
    -- Spell damage: small boost for caster items
    CASE WHEN i.mana > 50 THEN COALESCE(i.spelldmg,0) + FLOOR((i.mana + i.manaregen * 200) / 300) ELSE i.spelldmg END AS spelldmg,
    CASE WHEN i.mana > 50 THEN COALESCE(i.healamt,0) + FLOOR((i.mana + i.manaregen * 200) / 300) ELSE i.healamt END AS healamt,
    i.clairvoyance, i.backstabdmg,
    -- Bags: +3 slots (cap 14), +10 WR (cap 35)
    CASE WHEN i.itemclass = 1 THEN LEAST(COALESCE(i.bagslots,0) + 3, 14) ELSE i.bagslots END AS bagslots,
    CASE WHEN i.itemclass = 1 THEN LEAST(COALESCE(i.bagwr,0) + 10, 35) ELSE i.bagwr END AS bagwr,
    i.bagsize, i.bagtype,
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
    CONCAT('T2 Exalted variant of item ', i.id) AS comment,
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
    WHERE base_item_id = i.id AND tier_code = 2
);

-- Record T2 mappings
INSERT INTO item_tier_map (base_item_id, tier_code, variant_item_id, power_score)
SELECT
    i.id,
    2 AS tier_code,
    i.id + 20000000 AS variant_item_id,
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
    WHERE base_item_id = i.id AND tier_code = 2
);

SELECT CONCAT('✓ Tier 2 (Exalted) generated: ', ROW_COUNT(), ' items at ', NOW()) AS status;

-- ============================================================================
-- STEP 7: Generate Tier 3 (Ascendant) variants - THE CAPSTONE TIER
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'GENERATING TIER 3 (Ascendant) VARIANTS...' AS '';
SELECT '============================================================================' AS '';

-- Tier 3 multipliers: AC×1.38, HP/Mana/End×1.95, Stats×1.40, Damage×1.11
-- Heroics: +1 to +3 points across 1-2 heroic stats (role-based)
-- Spell damage: meaningful boost for casters
-- ID offset: +30000000

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
    i.id + 30000000 AS id,
    i.minstatus,
    i.Name,
    -- Stats: ×1.40 with injection floor
    GREATEST(FLOOR(COALESCE(i.aagi,0) * 1.40), CASE WHEN COALESCE(i.aagi,0) = 0 AND i.itemclass != 1 THEN 5 ELSE 0 END) AS aagi,
    FLOOR(COALESCE(i.ac,0) * 1.38) AS ac,
    FLOOR(COALESCE(i.accuracy,0) * 1.40) AS accuracy,
    GREATEST(FLOOR(COALESCE(i.acha,0) * 1.40), CASE WHEN COALESCE(i.acha,0) = 0 AND i.itemclass != 1 THEN 5 ELSE 0 END) AS acha,
    GREATEST(FLOOR(COALESCE(i.adex,0) * 1.40), CASE WHEN COALESCE(i.adex,0) = 0 AND i.itemclass != 1 THEN 5 ELSE 0 END) AS adex,
    GREATEST(FLOOR(COALESCE(i.aint,0) * 1.40), CASE WHEN COALESCE(i.aint,0) = 0 AND i.itemclass != 1 THEN 5 ELSE 0 END) AS aint,
    GREATEST(FLOOR(COALESCE(i.asta,0) * 1.40), CASE WHEN COALESCE(i.asta,0) = 0 AND i.itemclass != 1 THEN 5 ELSE 0 END) AS asta,
    GREATEST(FLOOR(COALESCE(i.astr,0) * 1.40), CASE WHEN COALESCE(i.astr,0) = 0 AND i.itemclass != 1 THEN 5 ELSE 0 END) AS astr,
    FLOOR(COALESCE(i.attack,0) * 1.40) AS attack,
    -- Resists: ×1.40
    FLOOR(COALESCE(i.cr,0) * 1.40) AS cr,
    FLOOR(COALESCE(i.dr,0) * 1.40) AS dr,
    FLOOR(COALESCE(i.fr,0) * 1.40) AS fr,
    FLOOR(COALESCE(i.mr,0) * 1.40) AS mr,
    FLOOR(COALESCE(i.pr,0) * 1.40) AS pr,
    FLOOR(COALESCE(i.svcorruption,0) * 1.40) AS svcorruption,
    -- Sustain: ×1.95 with injection floor (BIG boost for solo/duo)
    GREATEST(FLOOR(COALESCE(i.hp,0) * 1.95), CASE WHEN COALESCE(i.hp,0) < 50 AND i.itemclass != 1 THEN 120 ELSE 0 END) AS hp,
    GREATEST(FLOOR(COALESCE(i.mana,0) * 1.95), CASE WHEN COALESCE(i.mana,0) < 50 AND i.itemclass != 1 THEN 120 ELSE 0 END) AS mana,
    GREATEST(FLOOR(COALESCE(i.endur,0) * 1.95), CASE WHEN COALESCE(i.endur,0) < 50 AND i.itemclass != 1 THEN 120 ELSE 0 END) AS endur,
    LEAST(FLOOR(COALESCE(i.regen,0) * 1.95), 5) AS regen,
    LEAST(FLOOR(COALESCE(i.manaregen,0) * 1.95), 5) AS manaregen,
    LEAST(FLOOR(COALESCE(i.enduranceregen,0) * 1.95), 5) AS enduranceregen,
    -- Shielding: ×1.40, capped at 10
    LEAST(FLOOR(COALESCE(i.shielding,0) * 1.40), 10) AS shielding,
    LEAST(FLOOR(COALESCE(i.spellshield,0) * 1.40), 10) AS spellshield,
    LEAST(FLOOR(COALESCE(i.dotshielding,0) * 1.40), 10) AS dotshielding,
    -- Weapon damage: ×1.11, delay FROZEN
    CASE WHEN i.delay > 0 THEN FLOOR(COALESCE(i.damage,0) * 1.11) ELSE i.damage END AS damage,
    i.delay,
    FLOOR(COALESCE(i.strikethrough,0) * 1.40) AS strikethrough,
    FLOOR(COALESCE(i.avoidance,0) * 1.40) AS avoidance,
    -- Heroics: +1 to +3 points based on power score and class
    -- Melee DPS: hSTR (secondary)
    CASE WHEN ((i.classes & 8) > 0 OR (i.classes & 16) > 0 OR (i.classes & 32) > 0) AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 300
         THEN COALESCE(i.heroic_str,0) + 1 ELSE i.heroic_str END AS heroic_str,
    -- Caster items: hINT (primary for INT casters)
    CASE WHEN ((i.classes & 256) > 0 OR (i.classes & 2048) > 0) AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 300
         THEN COALESCE(i.heroic_int,0) + CASE WHEN calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 800 THEN 3 ELSE 2 END
         ELSE i.heroic_int END AS heroic_int,
    -- Caster items: hWIS (primary for WIS casters)
    CASE WHEN ((i.classes & 2) > 0 OR (i.classes & 4) > 0 OR (i.classes & 64) > 0) AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 300
         THEN COALESCE(i.heroic_wis,0) + CASE WHEN calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 800 THEN 3 ELSE 2 END
         ELSE i.heroic_wis END AS heroic_wis,
    -- Tank items: hAGI (secondary)
    CASE WHEN (i.classes & 1) > 0 AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 500
         THEN COALESCE(i.heroic_agi,0) + 1 ELSE i.heroic_agi END AS heroic_agi,
    -- Melee DPS: hDEX (primary)
    CASE WHEN ((i.classes & 8) > 0 OR (i.classes & 16) > 0 OR (i.classes & 32) > 0 OR (i.classes & 128) > 0) AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 300
         THEN COALESCE(i.heroic_dex,0) + CASE WHEN calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 800 THEN 3 ELSE 2 END
         ELSE i.heroic_dex END AS heroic_dex,
    -- Tank items: hSTA (primary)
    CASE WHEN (i.classes & 1) > 0 AND calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 300
         THEN COALESCE(i.heroic_sta,0) + CASE WHEN calculate_power_score(i.ac, i.hp, i.mana, i.endur, i.astr, i.asta, i.adex, i.aagi, i.aint, i.awis, i.acha, i.cr, i.dr, i.fr, i.mr, i.pr, i.svcorruption, i.accuracy, i.attack, i.strikethrough, i.regen, i.manaregen, i.enduranceregen, i.shielding, i.spellshield, i.dotshielding) > 800 THEN 3 ELSE 2 END
         ELSE i.heroic_sta END AS heroic_sta,
    i.heroic_cha,
    i.heroic_pr, i.heroic_dr, i.heroic_fr, i.heroic_cr, i.heroic_mr, i.heroic_svcorrup,
    -- Spell damage: meaningful boost for casters (capstone tier)
    CASE WHEN i.mana > 30 THEN COALESCE(i.spelldmg,0) + FLOOR((i.mana + i.manaregen * 200 + (i.aint + i.awis) * 10) / 200) ELSE i.spelldmg END AS spelldmg,
    CASE WHEN i.mana > 30 THEN COALESCE(i.healamt,0) + FLOOR((i.mana + i.manaregen * 200 + (i.aint + i.awis) * 10) / 200) ELSE i.healamt END AS healamt,
    i.clairvoyance, i.backstabdmg,
    -- Bags: +4 slots (cap 15), +15 WR (cap 50)
    CASE WHEN i.itemclass = 1 THEN LEAST(COALESCE(i.bagslots,0) + 4, 15) ELSE i.bagslots END AS bagslots,
    CASE WHEN i.itemclass = 1 THEN LEAST(COALESCE(i.bagwr,0) + 15, 50) ELSE i.bagwr END AS bagwr,
    i.bagsize, i.bagtype,
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
    i.damageshield, i.deity, augdistiller, i.clicktype, i.clicklevel2,
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
    CONCAT('T3 Ascendant variant of item ', i.id) AS comment,
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
    WHERE base_item_id = i.id AND tier_code = 3
);

-- Record T3 mappings
INSERT INTO item_tier_map (base_item_id, tier_code, variant_item_id, power_score)
SELECT
    i.id,
    3 AS tier_code,
    i.id + 30000000 AS variant_item_id,
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
    WHERE base_item_id = i.id AND tier_code = 3
);

SELECT CONCAT('✓ Tier 3 (Ascendant) generated: ', ROW_COUNT(), ' items at ', NOW()) AS status;

-- ============================================================================
-- STEP 8: Final statistics and QA queries
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'GENERATION COMPLETE - RUNNING QA CHECKS' AS '';
SELECT '============================================================================' AS '';

-- Total counts
SELECT
    'Total tier variants generated' AS metric,
    COUNT(*) AS count
FROM item_tier_map;

-- Breakdown by tier
SELECT
    td.tier_name,
    COUNT(*) AS item_count
FROM item_tier_map itm
JOIN tier_defs td ON itm.tier_code = td.tier_code
GROUP BY td.tier_name, td.tier_code
ORDER BY td.tier_code;

-- Breakdown by category
SELECT
    e.item_category,
    COUNT(DISTINCT itm.base_item_id) AS base_items,
    COUNT(*) AS total_variants
FROM item_tier_map itm
JOIN eligible_all_items e ON itm.base_item_id = e.id
GROUP BY e.item_category;

-- Power score distribution
SELECT
    'Power Score Distribution' AS metric,
    MIN(power_score) AS min_power,
    FLOOR(AVG(power_score)) AS avg_power,
    MAX(power_score) AS max_power
FROM item_tier_map
WHERE tier_code = 0 OR tier_code IS NULL;

-- Sample comparison: show a few items across all tiers
SELECT '============================================================================' AS '';
SELECT 'SAMPLE ITEM COMPARISON (First 5 eligible items across all tiers)' AS '';
SELECT '============================================================================' AS '';

SELECT
    i.id,
    i.Name,
    COALESCE(td.tier_name, 'Base') AS tier,
    i.ac,
    i.hp,
    i.mana,
    i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha AS total_stats,
    i.heroic_str + i.heroic_int + i.heroic_wis + i.heroic_agi + i.heroic_dex + i.heroic_sta + i.heroic_cha AS total_heroics,
    i.damage,
    i.delay
FROM (
    SELECT id FROM eligible_all_items LIMIT 5
) sample
JOIN items base ON sample.id = base.id
LEFT JOIN item_tier_map itm ON base.id = itm.base_item_id
LEFT JOIN items i ON COALESCE(itm.variant_item_id, base.id) = i.id
LEFT JOIN tier_defs td ON itm.tier_code = td.tier_code
ORDER BY base.id, COALESCE(itm.tier_code, -1);

-- Verify delay never changed on weapons
SELECT
    'Delay Integrity Check' AS check_name,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS - All weapon delays preserved'
        ELSE CONCAT('⚠ FAIL - ', COUNT(*), ' weapons have changed delays!')
    END AS result
FROM items base
JOIN item_tier_map itm ON base.id = itm.base_item_id
JOIN items variant ON itm.variant_item_id = variant.id
WHERE base.delay > 0 AND base.delay != variant.delay;

-- Verify no duplicate variant IDs
SELECT
    'Variant ID Uniqueness Check' AS check_name,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT variant_item_id) THEN '✓ PASS - All variant IDs unique'
        ELSE CONCAT('⚠ FAIL - ', COUNT(*) - COUNT(DISTINCT variant_item_id), ' duplicate variant IDs!')
    END AS result
FROM item_tier_map;

-- Check for any items that failed to generate all 3 tiers
SELECT
    'Tier Completeness Check' AS check_name,
    CASE
        WHEN COUNT(DISTINCT base_item_id) * 3 = COUNT(*) THEN '✓ PASS - All items have 3 tiers'
        ELSE CONCAT('⚠ WARNING - ', COUNT(DISTINCT base_item_id) * 3 - COUNT(*), ' tier variants missing')
    END AS result
FROM item_tier_map;

-- Execution summary
SELECT '============================================================================' AS '';
SELECT 'EXECUTION SUMMARY' AS '';
SELECT '============================================================================' AS '';

SELECT
    CONCAT('Started: ', @start_time) AS start_time,
    CONCAT('Completed: ', NOW()) AS end_time,
    CONCAT('Duration: ', TIMESTAMPDIFF(SECOND, @start_time, NOW()), ' seconds') AS duration,
    (SELECT COUNT(*) FROM item_tier_map) AS total_variants_created,
    (SELECT COUNT(DISTINCT base_item_id) FROM item_tier_map) AS base_items_tiered;

SELECT '============================================================================' AS '';
SELECT '✓ ITEM TIER GENERATION COMPLETE!' AS '';
SELECT 'Next steps:' AS '';
SELECT '1. Review sample comparisons above' AS '';
SELECT '2. Test a few items in-game' AS '';
SELECT '3. Add tier variants to loot tables (separate script)' AS '';
SELECT '4. Update quest/merchant systems as needed' AS '';
SELECT '============================================================================' AS '';

