# Functional Design Plan — Unit 1: Resources (Shared Data)

## Unit Context

- **Unit**: Unit 1: Resources (Shared Data)
- **Purpose**: Define all shared game data used across systems.
- **Dependencies**: None (base unit)
- **Artifacts**: `resources/characters/`, `resources/moves/`,
  `resources/type_chart.gd`, `resources/status_effects.gd`

---

## Design Questions

Please answer the following questions to clarify the functional design for the
Resources unit.

### Question 1

Based on the theme of 三国志 (Romance of the Three Kingdoms) with 陰陽五行
(Yin-Yang Five Elements) as the core type system, how should the type
effectiveness be structured?

A) 5 types — 五行 only (木 Wood, 火 Fire, 土 Earth, 金 Metal, 水 Water) with
classic 相生 (generating) and 相克 (overcoming) cycles

B) 6 types — 五行 + 陰陽 as a separate dimension (e.g., Yang Fire / Yin Water)

C) 7 types — 五行 + 陰陽 as two additional types (Yang, Yin)

D) Other — I have a specific type system in mind (please describe after
[Answer]: tag below)

[Answer]: C — 7 types: Wood, Fire, Earth, Metal, Water, Yang, Yin

### Question 2

What status effects should be supported in the game?

A) Basic: Poison, Sleep, Paralysis

B) Basic + Burn, Freeze

C) Comprehensive: Poison, Sleep, Paralysis, Burn, Freeze, Confusion

D) Other (please describe after [Answer]: tag below)

[Answer]: D — Other: Burn (炎上), Poison (毒), Confusion (混乱), Chain (連環),
Charm (魅了)

### Question 3

How should moves define their effects beyond simple damage?

A) Damage only (no special effects)

B) Damage + chance to inflict status effect

C) Damage + status effect + stat modification (attack/defense/speed changes)

D) Complex: All of the above plus multi-hit, recoil, healing, etc.

E) Other (please describe after [Answer]: tag below)

[Answer]: D

### Question 4

How many moves should each character have access to?

A) 2 moves per character (simple)

B) 4 moves per character (standard)

C) 6+ moves per character (variety)

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Question 5

How many playable characters should be defined in the initial data set?

A) 3 characters (minimal)

B) 6 characters (small roster)

C) 9+ characters (medium roster)

D) Other (please describe after [Answer]: tag below)

[Answer]: C

### Question 6

Should characters have unique stats or follow a class/template system?

A) Unique stats per character (each character has distinct values)

B) Class/template system (characters share a class with modifiers)

C) Hybrid: Base class stats + individual variation

D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Plan Steps

- [x] Collect and analyze user answers to design questions
- [x] Define domain entities (Character, Move, TypeChart, StatusEffect)
- [x] Define data structures and property schemas
- [x] Define type effectiveness rules and lookup logic
- [x] Define status effect behavior rules
- [x] Define business rules for data validation
- [x] Generate `domain-entities.md`
- [x] Generate `business-logic-model.md`
- [x] Generate `business-rules.md`
- [x] Present completion message and await approval
