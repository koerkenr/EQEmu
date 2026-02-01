# Tier 1 Selective Injection - Implementation Guide

## Overview
This guide shows how to regenerate T1 with role-based selective stat injection for zero-stat items.

## Step 1: Rollback Existing T1

Run `rollback_t1.sql` in HeidiSQL to delete all existing T1 variants.

## Step 2: Key Changes Needed

### Add `is_zero_stat` flag to power score cache

In the power score cache table creation, add:
```sql
is_zero_stat BOOLEAN,
KEY idx_zero (is_zero_stat)
```

And in the INSERT:
```sql
(i.ac = 0 AND i.hp = 0 AND i.mana = 0 AND i.endur = 0 AND 
 (i.astr + i.asta + i.adex + i.aagi + i.aint + i.awis + i.acha) = 0) AS is_zero_stat
```

### Split T1 Generation Into Two Inserts

**Insert 1: Items WITH stats (multiplicative scaling)**
```sql
WHERE ps.is_zero_stat = 0  -- Only items WITH stats
```
Keep all existing multiplicative logic.

**Insert 2: Zero-stat items (selective injection)**
```sql
WHERE ps.is_zero_stat = 1  -- Only zero-stat items
```

Use role-based selective injection:

```sql
-- AGI: Melee DPS only
CASE WHEN ps.is_melee_dps THEN 1 ELSE 0 END AS aagi,

-- AC: Tanks get +3, melee get +1
CASE WHEN ps.is_tank THEN 3 WHEN ps.is_melee_dps THEN 1 ELSE 0 END AS ac,

-- Accuracy: Melee only
CASE WHEN ps.is_melee_dps OR ps.is_tank THEN 2 ELSE 0 END AS accuracy,

-- CHA: Casters only
CASE WHEN ps.is_int_caster OR ps.is_wis_caster THEN 1 ELSE 0 END AS acha,

-- DEX: Melee DPS only
CASE WHEN ps.is_melee_dps THEN 1 ELSE 0 END AS adex,

-- INT: INT casters only
CASE WHEN ps.is_int_caster THEN 1 ELSE 0 END AS aint,

-- STA: Everyone
1 AS asta,

-- STR: Tanks and melee
CASE WHEN ps.is_tank OR ps.is_melee_dps THEN 1 ELSE 0 END AS astr,

-- Attack: Melee only
CASE WHEN ps.is_melee_dps OR ps.is_tank THEN 2 ELSE 0 END AS attack,

-- Resists: Random one resist gets +2 (pseudo-random via MOD)
CASE WHEN MOD(i.id, 5) = 0 THEN 2 ELSE 0 END AS cr,
CASE WHEN MOD(i.id, 5) = 1 THEN 2 ELSE 0 END AS dr,
CASE WHEN MOD(i.id, 5) = 2 THEN 2 ELSE 0 END AS fr,
CASE WHEN MOD(i.id, 5) = 3 THEN 2 ELSE 0 END AS mr,
CASE WHEN MOD(i.id, 5) = 4 THEN 2 ELSE 0 END AS pr,
0 AS svcorruption,

-- HP: Everyone, tanks get more
CASE WHEN ps.is_tank THEN 15 ELSE 10 END AS hp,

-- Mana: ONLY casters (respects class identity!)
CASE WHEN ps.is_int_caster OR ps.is_wis_caster THEN 12 ELSE 0 END AS mana,

-- Endur: Melee and tanks
CASE WHEN ps.is_tank OR ps.is_melee_dps THEN 10 ELSE 0 END AS endur,

-- Regen/shielding: None at T1 for zero-stat items
0 AS regen,
0 AS manaregen,
0 AS enduranceregen,
0 AS shielding,
0 AS spellshield,
0 AS dotshielding,
0 AS strikethrough,

-- Avoidance: Tanks only
CASE WHEN ps.is_tank THEN 1 ELSE 0 END AS avoidance,

-- Stun resist: Tanks only
CASE WHEN ps.is_tank THEN 2 ELSE 0 END AS stunresist,

-- Heroics: None at T1
0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0,

-- Spell damage: None at T1
0, 0, 0, 0
```

## What This Achieves

### Variety
- Not all items get +1 all stats
- Each item gets 2-4 relevant stats based on class
- Random resist distribution (via MOD)

### Class Identity
- Melee items don't get mana
- Caster items don't get attack/accuracy
- Tanks get defensive stats
- DPS gets offensive stats

### Conservative Power
- T1 zero-stat items get minimal boosts
- Real gear with multiplicative scaling stays much better
- Cosmetic items become useful but not overpowered

## Example Results

**Flowing Black Silk Sash** (Monk/Bard - melee DPS):
- Base: 0 stats
- T1: +1 AC, +1 AGI, +1 DEX, +1 STA, +2 accuracy, +2 attack, +10 HP, +10 endur, +2 random resist

**Decorative Robe** (Wizard - INT caster):
- Base: 0 stats
- T1: +1 INT, +1 CHA, +1 STA, +10 HP, +12 mana, +2 random resist

**Ornate Plate Bracer** (Warrior - tank):
- Base: 0 stats
- T1: +3 AC, +1 STR, +1 STA, +2 accuracy, +2 attack, +15 HP, +10 endur, +1 avoidance, +2 stun resist, +2 random resist

## Next Steps

1. Run `rollback_t1.sql`
2. I'll create the complete updated script
3. Execute and verify varied stats on zero-stat items
