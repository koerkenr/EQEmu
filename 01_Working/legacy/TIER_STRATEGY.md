# EQEmu Item Tiering Strategy - Progressive Stat Injection

## Core Principles

1. **Continuity**: T2 builds on T1, T3 builds on T2
2. **Variety**: Pseudo-random stat selection makes items feel unique
3. **Role-aware**: Stats respect class identity (no mana on melee, etc.)
4. **Progressive power**: Premium stats introduced gradually (T2 rare, T3 common)

## Tier 1 (Enhanced) - Foundation

### Existing Stats
- **Multiply**: AC ×1.10, HP/Mana/Endur ×1.18, Stats ×1.10, Damage ×1.03
- **Preserve**: Delay, haste, effects unchanged

### Missing Stats (Selective Injection)
Add 2-3 appropriate stats based on role:

**Tanks** (WAR/PAL/SHD):
- Always: STA +1
- Pick 1-2: STR +1, AGI +1, one resist +2

**Melee DPS** (RNG/MNK/BRD/ROG/BST/BER):
- Always: STA +1
- Pick 1-2: STR +1, DEX +1, AGI +1, one resist +2

**INT Casters** (WIZ/MAG/NEC/ENC):
- Always: STA +1
- Pick 1-2: INT +1, CHA +1, one resist +2

**WIS Casters** (CLR/DRU/SHM):
- Always: STA +1
- Pick 1-2: WIS +1, CHA +1, one resist +2

### What NOT to Add at T1
- Premium stats: accuracy, attack, strikethrough, avoidance, stun resist
- Regen/mana regen/endur regen
- Shielding/spell shield/dot shielding
- Heroics

### Pseudo-Random Selection
Use `MOD(base_item_id, N)` for deterministic variety:
- Which stat to inject: `MOD(id, 3)` picks from 2-3 options
- Which resist: `MOD(id, 5)` picks CR/DR/FR/MR/PR

## Tier 2 (Exalted) - Growth

### Base Calculation
- Start from T1 item stats (read from items table where id = base_id + 10M)
- Multiply T1 stats: AC ×1.27, HP/Mana/Endur ×1.40, Stats ×1.27, Damage ×1.08

### Premium Stats (Rare - ~20% chance)
Use `MOD(base_item_id, 5) = 0` for ~20% selection:

**Tanks**:
- Avoidance +1 OR Stun Resist +2

**Melee DPS**:
- Accuracy +2 OR Strikethrough +1

**Casters**:
- Spell Shield +1 (very rare)

### Heroics
- Add +1 to primary heroic stat only (heroic_str for tanks/melee, heroic_int/wis for casters)

## Tier 3 (Ascendant) - Power

### Base Calculation
- Start from T2 item stats (read from items table where id = base_id + 20M)
- Multiply T2 stats: AC ×1.45, HP/Mana/Endur ×1.70, Stats ×1.45, Damage ×1.15

### Premium Stats (Common - ~50% chance)
Use `MOD(base_item_id, 2) = 0` for ~50% selection:

**Tanks**:
- Avoidance +2, Stun Resist +3, Shielding +1

**Melee DPS**:
- Accuracy +4, Strikethrough +2, Attack +3

**Casters**:
- Spell Shield +2, Spell Damage +5 (if INT caster), Heal Amt +5 (if WIS caster)

### Heroics
- Add +2 to primary heroic stat
- Add +1 to secondary heroic stat

### Light Regen (Very Rare - ~10%)
Use `MOD(base_item_id, 10) = 0`:
- Regen +1 (tanks/melee)
- Mana Regen +1 (casters)

## Example Progression

### Flowing Black Silk Sash (Monk/Bard - Melee DPS)
**Base**: 0 stats (cosmetic)

**T1**: 
- STA +1, DEX +1 (selected via MOD)
- FR +2 (selected via MOD)
- HP +10, Endur +10

**T2** (builds on T1):
- STA +1, DEX +1 (carried forward)
- FR +2 (carried forward)
- HP +14, Endur +14
- Accuracy +2 (20% chance - this item got it)

**T3** (builds on T2):
- STA +2, DEX +2 (carried forward, scaled)
- FR +3 (carried forward, scaled)
- HP +20, Endur +20
- Accuracy +4, Strikethrough +2 (50% chance - this item got it)

### Cloak of Flame (Warrior - Tank)
**Base**: 5 AC, 50 HP, 0 stats

**T1**:
- AC 5, HP 59 (multiplied)
- STA +1, STR +1 (selected via MOD)
- MR +2 (selected via MOD)

**T2** (builds on T1):
- AC 6, HP 83 (multiplied from T1)
- STA +1, STR +1 (carried forward)
- MR +2 (carried forward)
- Avoidance +1 (20% chance - this item got it)
- Heroic STA +1

**T3** (builds on T2):
- AC 9, HP 119 (multiplied from T2)
- STA +2, STR +2 (carried forward, scaled)
- MR +3 (carried forward, scaled)
- Avoidance +2, Stun Resist +3, Shielding +1 (50% chance - this item got it)
- Heroic STA +2, Heroic STR +1

## Technical Implementation

### T1 Generation
- Single pass, reads from base items
- Deterministic stat selection via MOD
- No lookups needed

### T2 Generation
- Reads from T1 items (base_id + 10M)
- Multiplies T1 stats
- Adds premium stats rarely

### T3 Generation
- Reads from T2 items (base_id + 20M)
- Multiplies T2 stats
- Adds premium stats commonly

### Continuity Verification Query
```sql
SELECT 
    base.Name,
    base.ac AS base_ac, t1.ac AS t1_ac, t2.ac AS t2_ac, t3.ac AS t3_ac,
    base.hp AS base_hp, t1.hp AS t1_hp, t2.hp AS t2_hp, t3.hp AS t3_hp,
    t1.astr AS t1_str, t2.astr AS t2_str, t3.astr AS t3_str,
    t2.accuracy AS t2_acc, t3.accuracy AS t3_acc,
    t3.strikethrough AS t3_strike
FROM items base
LEFT JOIN items t1 ON t1.id = base.id + 10000000
LEFT JOIN items t2 ON t2.id = base.id + 20000000
LEFT JOIN items t3 ON t3.id = base.id + 30000000
WHERE base.id < 10000000
LIMIT 20;
```

This shows clear progression and continuity across all tiers.
