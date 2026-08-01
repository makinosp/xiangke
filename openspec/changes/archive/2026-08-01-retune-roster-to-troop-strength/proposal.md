# Retune Roster to Troop Strength

## Why

HP currently reads as personal toughness, so bodyguards (Dian Wei 140, Xu Chu
140) outrank warlords who commanded armies (Sun Quan 110, Yuan Shao 120).
Historically, HP should be inspired by 兵力 (troop strength): rulers and supreme
commanders field the largest forces, strategists led armies in the field, while
bodyguards and non-military figures commanded few or no troops.

## What Changes

Retune HP and Defense across the full 38-character roster as a pure stat swap
(sum per character stays identical; ATK/SPD/INT/SPR untouched):

- **Shields (4)**: HP → DEF transfer of 40 points (Cao Ren already done at 60
  via `adjust-cao-ren-stats`, kept as anchor). Dian Wei, Xu Chu, Xiahou Dun
  become extreme physical walls.
- **Strategists (9)**: HP +25 / DEF −25 (DEF only; SPR preserved). Field
  commanders like Zhuge Liang, Sima Yi, Zhou Yu gain survivability from troops
  but become vulnerable to physical strikes.
- **Rulers (6)**: HP +5 / DEF −5. Dong Zhuo, Cao Cao, Yuan Shao, Sun Ce, Liu
  Bei, Sun Quan embody max troop strength.
- **Warriors (3 adjusted / 11 unchanged)**: Lu Bu shifts to a glass cannon (HP
  −5 / DEF +5), Huang Zhong gains troops, Lü Meng is treated as a warrior (HP +5
  / DEF −5). The other 11 generals are already consistent with troop strength.
- **Non-military (5)**: HP −10 / DEF +10. Da Qiao, Zhen Ji, Diao Chan, Huang Yue
  Ying, Hua Tuo command no troops; personal agility replaces bulk.

## Capabilities

### New Capabilities

None — pure data change, no new behavior.

### Modified Capabilities

None — no spec-level behavior changes. Character data validation rules
(CR-1..CR-4) are unaffected: all stats remain in [1, 500], sums are unchanged.

## Impact

- `resources/characters/*.tres` — HP/defense fields for 24 of 38 characters (Cao
  Ren already tuned; 11 warriors unchanged; 13 untouched files overall).
- No code changes: Rust core, GDExtension bridge, GDScript validation, and the
  move pool are all unaffected.
- Gameplay feel: physical walls (Dian Wei, Xu Chu, Xiahou Dun, Cao Ren) and
  troop-based bulk for rulers/strategists; magic weakness becomes a sharper
  counter to high-DEF shields.
