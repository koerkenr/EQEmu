# Simple Approach: Update Existing T1 Zero-Stat Items

Instead of regenerating everything, let's just UPDATE the zero-stat T1 items that already exist with selective stats.

## Step 1: Identify Zero-Stat T1 Items

```sql
-- Find T1 items that came from zero-stat bases
SELECT COUNT(*)
FROM item_tier_map itm
JOIN items base ON itm.base_item_id = base.id
JOIN items t1 ON itm.variant_item_id = t1.id
WHERE itm.tier_code = 1
  AND base.ac = 0 AND base.hp = 0 AND base.mana = 0 AND base.endur = 0
  AND (base.astr + base.asta + base.adex + base.aagi + base.aint + base.awis + base.acha) = 0
  AND t1.ac = 0 AND t1.hp = 0;  -- T1 is also zero
```

## Step 2: Update Them With Selective Stats

Use UPDATE statements with role-based CASE logic:

```sql
-- Update zero-stat T1 items with selective injection
UPDATE items t1
JOIN item_tier_map itm ON t1.id = itm.variant_item_id
JOIN items base ON itm.base_item_id = base.id
SET
    -- Tanks get +3 AC, melee get +1
    t1.ac = CASE 
        WHEN (base.classes & 21) > 0 THEN 3  -- Tank
        WHEN (base.classes & 33288) > 0 THEN 1  -- Melee DPS
        ELSE 0 
    END,
    
    -- Everyone gets +1 STA
    t1.asta = 1,
    
    -- Melee gets AGI
    t1.aagi = CASE WHEN (base.classes & 33288) > 0 THEN 1 ELSE 0 END,
    
    -- Melee gets DEX
    t1.adex = CASE WHEN (base.classes & 33288) > 0 THEN 1 ELSE 0 END,
    
    -- Tanks and melee get STR
    t1.astr = CASE WHEN (base.classes & 33309) > 0 THEN 1 ELSE 0 END,
    
    -- INT casters get INT
    t1.aint = CASE WHEN (base.classes & 15360) > 0 THEN 1 ELSE 0 END,
    
    -- WIS casters get WIS (not shown but similar)
    
    -- Casters get CHA
    t1.acha = CASE WHEN (base.classes & 15906) > 0 THEN 1 ELSE 0 END,
    
    -- Melee gets accuracy and attack
    t1.accuracy = CASE WHEN (base.classes & 33309) > 0 THEN 2 ELSE 0 END,
    t1.attack = CASE WHEN (base.classes & 33309) > 0 THEN 2 ELSE 0 END,
    
    -- Random resist (using MOD)
    t1.cr = CASE WHEN MOD(base.id, 5) = 0 THEN 2 ELSE 0 END,
    t1.dr = CASE WHEN MOD(base.id, 5) = 1 THEN 2 ELSE 0 END,
    t1.fr = CASE WHEN MOD(base.id, 5) = 2 THEN 2 ELSE 0 END,
    t1.mr = CASE WHEN MOD(base.id, 5) = 3 THEN 2 ELSE 0 END,
    t1.pr = CASE WHEN MOD(base.id, 5) = 4 THEN 2 ELSE 0 END,
    
    -- HP: tanks get 15, others get 10
    t1.hp = CASE WHEN (base.classes & 21) > 0 THEN 15 ELSE 10 END,
    
    -- Mana: ONLY casters
    t1.mana = CASE WHEN (base.classes & 15906) > 0 THEN 12 ELSE 0 END,
    
    -- Endur: melee and tanks
    t1.endur = CASE WHEN (base.classes & 33309) > 0 THEN 10 ELSE 0 END,
    
    -- Avoidance: tanks only
    t1.avoidance = CASE WHEN (base.classes & 21) > 0 THEN 1 ELSE 0 END,
    
    -- Stun resist: tanks only
    t1.stunresist = CASE WHEN (base.classes & 21) > 0 THEN 2 ELSE 0 END,
    
    t1.updated = NOW(),
    t1.comment = CONCAT('T1 Enhanced (selective injection) - ', base.id)
    
WHERE itm.tier_code = 1
  AND base.ac = 0 AND base.hp = 0 AND base.mana = 0 AND base.endur = 0
  AND (base.astr + base.asta + base.adex + base.aagi + base.aint + base.awis + base.acha) = 0;
```

This is MUCH simpler and faster than regenerating everything!

## Class Bitmasks Reference
- Tanks (WAR+PAL+SHD): 21
- Melee DPS (RNG+MNK+BRD+ROG+BST+BER): 33288
- All melee (tanks + dps): 33309
- INT casters (NEC+WIZ+MAG+ENC): 15360
- WIS casters (CLR+DRU+SHM): 546
- All casters: 15906
