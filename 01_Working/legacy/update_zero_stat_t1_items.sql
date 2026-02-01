-- ============================================================================
-- Update Zero-Stat T1 Items with Selective Role-Based Stats
-- ============================================================================
-- This updates existing T1 items that came from zero-stat bases
-- Adds varied, class-appropriate stats instead of uniform +1 all stats
-- ============================================================================

SELECT '============================================================================' AS '';
SELECT 'UPDATING ZERO-STAT T1 ITEMS WITH SELECTIVE INJECTION...' AS '';
SELECT '============================================================================' AS '';

-- Show what will be updated
SELECT 
    'Zero-stat T1 items to update' AS action,
    COUNT(*) AS count
FROM item_tier_map itm
JOIN items base ON itm.base_item_id = base.id
JOIN items t1 ON itm.variant_item_id = t1.id
WHERE itm.tier_code = 1
  AND itm.item_category = 'gear'
  AND base.ac = 0 AND base.hp = 0 AND base.mana = 0 AND base.endur = 0
  AND (base.astr + base.asta + base.adex + base.aagi + base.aint + base.awis + base.acha) = 0;

-- Class bitmask reference:
-- Tanks (WAR=1 + PAL=4 + SHD=16): 21
-- Melee DPS (RNG=8 + MNK=64 + BRD=128 + ROG=256 + BST=16384 + BER=32768): 49608
-- INT casters (NEC=1024 + WIZ=2048 + MAG=4096 + ENC=8192): 15360
-- WIS casters (CLR=2 + DRU=32 + SHM=512): 546
-- All casters: 15906

-- Update zero-stat T1 items with selective, role-appropriate stats
UPDATE items t1
JOIN item_tier_map itm ON t1.id = itm.variant_item_id
JOIN items base ON itm.base_item_id = base.id
SET
    -- AC: Tanks get +3, melee DPS get +1, others get 0
    t1.ac = CASE 
        WHEN (base.classes & 21) > 0 THEN 3
        WHEN (base.classes & 49608) > 0 THEN 1
        ELSE 0 
    END,
    
    -- AGI: Melee DPS only
    t1.aagi = CASE WHEN (base.classes & 49608) > 0 THEN 1 ELSE 0 END,
    
    -- CHA: All casters
    t1.acha = CASE WHEN (base.classes & 15906) > 0 THEN 1 ELSE 0 END,
    
    -- DEX: Melee DPS only
    t1.adex = CASE WHEN (base.classes & 49608) > 0 THEN 1 ELSE 0 END,
    
    -- INT: INT casters only
    t1.aint = CASE WHEN (base.classes & 15360) > 0 THEN 1 ELSE 0 END,
    
    -- WIS: WIS casters only
    t1.awis = CASE WHEN (base.classes & 546) > 0 THEN 1 ELSE 0 END,
    
    -- STA: Everyone gets +1
    t1.asta = 1,
    
    -- STR: Tanks and melee DPS
    t1.astr = CASE WHEN (base.classes & 49629) > 0 THEN 1 ELSE 0 END,
    
    -- Accuracy: Melee (tanks + DPS)
    t1.accuracy = CASE WHEN (base.classes & 49629) > 0 THEN 2 ELSE 0 END,
    
    -- Attack: Melee (tanks + DPS)
    t1.attack = CASE WHEN (base.classes & 49629) > 0 THEN 2 ELSE 0 END,
    
    -- Resists: Random one resist gets +2 (pseudo-random via MOD on base item ID)
    t1.cr = CASE WHEN MOD(base.id, 5) = 0 THEN 2 ELSE 0 END,
    t1.dr = CASE WHEN MOD(base.id, 5) = 1 THEN 2 ELSE 0 END,
    t1.fr = CASE WHEN MOD(base.id, 5) = 2 THEN 2 ELSE 0 END,
    t1.mr = CASE WHEN MOD(base.id, 5) = 3 THEN 2 ELSE 0 END,
    t1.pr = CASE WHEN MOD(base.id, 5) = 4 THEN 2 ELSE 0 END,
    t1.svcorruption = 0,
    
    -- HP: Tanks get 15, everyone else gets 10
    t1.hp = CASE WHEN (base.classes & 21) > 0 THEN 15 ELSE 10 END,
    
    -- Mana: ONLY casters (respects class identity!)
    t1.mana = CASE WHEN (base.classes & 15906) > 0 THEN 12 ELSE 0 END,
    
    -- Endur: Melee (tanks + DPS)
    t1.endur = CASE WHEN (base.classes & 49629) > 0 THEN 10 ELSE 0 END,
    
    -- Regen/mana regen: None at T1 for zero-stat items
    t1.regen = 0,
    t1.manaregen = 0,
    t1.enduranceregen = 0,
    
    -- Shielding: None at T1
    t1.shielding = 0,
    t1.spellshield = 0,
    t1.dotshielding = 0,
    
    -- Strikethrough: None at T1
    t1.strikethrough = 0,
    
    -- Avoidance: Tanks only
    t1.avoidance = CASE WHEN (base.classes & 21) > 0 THEN 1 ELSE 0 END,
    
    -- Stun resist: Tanks only
    t1.stunresist = CASE WHEN (base.classes & 21) > 0 THEN 2 ELSE 0 END,
    
    -- Heroics: None at T1
    t1.heroic_str = 0,
    t1.heroic_int = 0,
    t1.heroic_wis = 0,
    t1.heroic_agi = 0,
    t1.heroic_dex = 0,
    t1.heroic_sta = 0,
    t1.heroic_cha = 0,
    t1.heroic_pr = 0,
    t1.heroic_dr = 0,
    t1.heroic_fr = 0,
    t1.heroic_cr = 0,
    t1.heroic_mr = 0,
    t1.heroic_svcorrup = 0,
    
    -- Spell damage: None at T1
    t1.spelldmg = 0,
    t1.healamt = 0,
    t1.clairvoyance = 0,
    t1.backstabdmg = 0,
    
    -- Update metadata
    t1.updated = NOW(),
    t1.comment = CONCAT('T1 Enhanced (selective injection) - base item ', base.id)
    
WHERE itm.tier_code = 1
  AND itm.item_category = 'gear'
  AND base.ac = 0 AND base.hp = 0 AND base.mana = 0 AND base.endur = 0
  AND (base.astr + base.asta + base.adex + base.aagi + base.aint + base.awis + base.acha) = 0;

SELECT CONCAT('✓ Updated ', ROW_COUNT(), ' zero-stat T1 items with selective stats') AS status;

-- Show sample results
SELECT '============================================================================' AS '';
SELECT 'SAMPLE UPDATED ITEMS:' AS '';
SELECT '============================================================================' AS '';

SELECT 
    base.Name,
    base.classes,
    CASE 
        WHEN (base.classes & 21) > 0 THEN 'Tank'
        WHEN (base.classes & 49608) > 0 THEN 'Melee DPS'
        WHEN (base.classes & 15360) > 0 THEN 'INT Caster'
        WHEN (base.classes & 546) > 0 THEN 'WIS Caster'
        ELSE 'Hybrid'
    END AS role,
    t1.ac, t1.hp, t1.mana, t1.endur,
    t1.astr, t1.asta, t1.adex, t1.aagi, t1.aint, t1.awis, t1.acha,
    t1.accuracy, t1.attack, t1.avoidance, t1.stunresist,
    CONCAT(
        CASE WHEN t1.cr > 0 THEN 'CR+2 ' ELSE '' END,
        CASE WHEN t1.dr > 0 THEN 'DR+2 ' ELSE '' END,
        CASE WHEN t1.fr > 0 THEN 'FR+2 ' ELSE '' END,
        CASE WHEN t1.mr > 0 THEN 'MR+2 ' ELSE '' END,
        CASE WHEN t1.pr > 0 THEN 'PR+2 ' ELSE '' END
    ) AS resists
FROM item_tier_map itm
JOIN items base ON itm.base_item_id = base.id
JOIN items t1 ON itm.variant_item_id = t1.id
WHERE itm.tier_code = 1
  AND itm.item_category = 'gear'
  AND base.ac = 0 AND base.hp = 0 AND base.mana = 0 AND base.endur = 0
  AND (base.astr + base.asta + base.adex + base.aagi + base.aint + base.awis + base.acha) = 0
LIMIT 20;

SELECT '============================================================================' AS '';
SELECT '✓ SELECTIVE INJECTION COMPLETE' AS '';
SELECT 'Zero-stat items now have varied, role-appropriate stats' AS '';
SELECT '============================================================================' AS '';
