## Context

- Current roster: 13 characters, each a `CharacterData` `.tres` file in
  `resources/characters/`, auto-discovered by `DataLoader` and validated at
  startup by both the Rust validator (`extensions/core/src/validator.rs`,
  authoritative) and the GDScript validator (`systems/data/data_validator.gd`).
- Move pool is fixed at 8 moves (5 damaging, 3 utility). This change does not
  add moves — every character must draw exactly 4 from this pool.
- Type enum: 0=WOOD, 1=FIRE, 2=EARTH, 3=METAL, 4=WATER, 5=YANG, 6=YIN. Secondary
  type: `-1` = none.
- See proposal.md (Why) for motivation.

## Goals / Non-Goals

**Goals:**

- Define the complete data for 25 new characters (id, name, types, 6 stats, 4
  moves, description) such that the implementation step is mechanical.
- Balance the roster: meaningful stat tiers, faction coverage, and provisional
  type coverage across all 7 types.
- Keep every character valid under existing validation rules (CR-1..CR-4).

**Non-Goals:**

- Adding or modifying moves (move pool stays at 8).
- Finalizing the type system — types here are provisional placeholders to be
  reworked in a follow-up type-redesign change.
- Changing any validation rules, specs, or code.

## Decisions

### D1: Roster composition — 25 characters across 4 factions

Wei +8, Shu +5, Wu +7, Warlords +5 → 13 existing + 25 new = 38 total.

| Faction  | New characters (id)                                                           |
| -------- | ----------------------------------------------------------------------------- |
| Wei      | zhang_liao, xu_chu, dian_wei, guo_jia, xun_yu, cao_ren, xia_hou_yuan, zhen_ji |
| Shu      | liu_bei, pang_tong, jiang_wei, wei_yan, huang_yue_ying                        |
| Wu       | sun_shang_xiang, sun_ce, tai_shi_ci, gan_ning, lu_xun, lv_meng, da_qiao       |
| Warlords | dong_zhuo, yuan_shao, chen_gong, hua_tuo, zhang_jiao                          |

Rationale: fixes the Shu-heavy / Wu-light imbalance and covers iconic figures.
Alternative considered: pure Wei/Shu stars — rejected, leaves Wu/Warlords thin.

### D2: Provisional type assignment (reworked later)

Each character gets a primary type (and occasional secondary) matching their
archetype, using single types mostly so later rework is cheap. The follow-up
type redesign will revisit these.

Type coverage of the 25 new characters (primary): WOOD 3, FIRE 5, EARTH 4, METAL
3, WATER 5, YANG 1, YIN 4. Combined with the existing 13 this fills the
WOOD/WATER gaps and gives YANG its first primary-type character (xun_yu).

### D3: Stat tiers — four power bands

- **S tier** (sum ≈ 590–600): top-tier warriors — zhang_liao, dian_wei, sun_ce,
  tai_shi_ci. Comparable to guan_yu/zhao_yun, below lv_bu.
- **A tier** (sum ≈ 560–590): strong generals — xu_chu, cao_ren, xia_hou_yuan,
  wei_yan, gan_ning, jiang_wei, dong_zhuo, lv_meng, liu_bei, yuan_shao, lu_xun,
  sun_shang_xiang.
- **B tier** (sum ≈ 540–560): strategists/support — guo_jia, xun_yu, pang_tong,
  zhen_ji, da_qiao, hua_tuo, huang_yue_ying, chen_gong, zhang_jiao.

All sums are far below the 3000 cap and no stat exceeds 145 (soft cap 500).

### D4: Move assignment — reuse the existing 8-move pool

Every character takes exactly 4 moves. Rule set:

- At least one damaging move (power > 0) — mandatory per CR-4.
- Damage moves match primary type when a matching damaging move exists (FIRE →
  fire_strike/flame_burst, METAL → iron_cleave/metal_slash, WATER →
  water_surge). WOOD/EARTH/YANG/YIN primaries have no matching damaging move in
  the pool, so they borrow from other types — this is a known limitation,
  documented and resolved by the follow-up move/type change.
- Typical loadout: 2 damaging + 2 utility (or 3 damaging + 1 utility for
  fighters).

Alternative considered: adding a few moves (e.g., wood/earth damage moves) —
rejected per user decision; moves are out of scope for this change.

### D5: Descriptions in English

Flavor text is written in English, matching the existing character files (e.g.,
cao_cao: "The cunning warlord who unified the north...").

## Full Roster Data (implementation reference)

Format per character:
`id | name | type | secondary | hp/atk/def/spd/int/spr | moves | sum`

### Wei (+8)

| id           | name   | type  | 2nd | HP  | ATK | DEF | SPD | INT | SPR | moves                                              | Σ   |
| ------------ | ------ | ----- | --- | --- | --- | --- | --- | --- | --- | -------------------------------------------------- | --- |
| zhang_liao   | 張遼   | METAL | -1  | 125 | 115 | 95  | 105 | 75  | 85  | metal_slash, iron_cleave, fire_strike, war_cry     | 600 |
| xu_chu       | 許褚   | EARTH | -1  | 140 | 115 | 105 | 65  | 55  | 90  | iron_cleave, metal_slash, earth_barrier, war_cry   | 570 |
| dian_wei     | 典韋   | EARTH | -1  | 140 | 112 | 112 | 85  | 55  | 96  | iron_cleave, metal_slash, earth_barrier, war_cry   | 600 |
| guo_jia      | 郭嘉   | WATER | -1  | 85  | 65  | 75  | 105 | 120 | 100 | water_surge, flame_burst, wood_heal, earth_barrier | 550 |
| xun_yu       | 荀彧   | YANG  | -1  | 90  | 60  | 85  | 80  | 115 | 110 | war_cry, flame_burst, wood_heal, earth_barrier     | 540 |
| cao_ren      | 曹仁   | EARTH | -1  | 130 | 85  | 120 | 70  | 75  | 95  | iron_cleave, earth_barrier, metal_slash, wood_heal | 575 |
| xia_hou_yuan | 夏侯淵 | FIRE  | -1  | 105 | 105 | 80  | 115 | 80  | 80  | flame_burst, fire_strike, water_surge, war_cry     | 565 |
| zhen_ji      | 甄姫   | YIN   | -1  | 90  | 70  | 80  | 95  | 105 | 110 | water_surge, flame_burst, wood_heal, war_cry       | 550 |

### Shu (+5)

| id             | name   | type  | 2nd | HP  | ATK | DEF | SPD | INT | SPR | moves                                              | Σ   |
| -------------- | ------ | ----- | --- | --- | --- | --- | --- | --- | --- | -------------------------------------------------- | --- |
| liu_bei        | 劉備   | WOOD  | -1  | 115 | 85  | 95  | 90  | 100 | 100 | wood_heal, metal_slash, earth_barrier, war_cry     | 585 |
| pang_tong      | 龐統   | YIN   | -1  | 90  | 65  | 80  | 85  | 120 | 100 | flame_burst, water_surge, war_cry, earth_barrier   | 540 |
| jiang_wei      | 姜維   | WATER | -1  | 108 | 100 | 95  | 95  | 95  | 85  | water_surge, flame_burst, earth_barrier, war_cry   | 578 |
| wei_yan        | 魏延   | FIRE  | -1  | 115 | 110 | 90  | 100 | 70  | 80  | fire_strike, flame_burst, iron_cleave, war_cry     | 565 |
| huang_yue_ying | 黄月英 | WOOD  | -1  | 85  | 70  | 90  | 90  | 118 | 105 | flame_burst, wood_heal, earth_barrier, water_surge | 558 |

### Wu (+7)

| id              | name   | type  | 2nd | HP  | ATK | DEF | SPD | INT | SPR | moves                                                | Σ   |
| --------------- | ------ | ----- | --- | --- | --- | --- | --- | --- | --- | ---------------------------------------------------- | --- |
| sun_shang_xiang | 孫尚香 | FIRE  | -1  | 100 | 110 | 82  | 118 | 82  | 88  | fire_strike, flame_burst, metal_slash, war_cry       | 580 |
| sun_ce          | 孫策   | FIRE  | -1  | 120 | 118 | 90  | 107 | 70  | 85  | flame_burst, fire_strike, iron_cleave, war_cry       | 590 |
| tai_shi_ci      | 太史慈 | METAL | -1  | 115 | 110 | 90  | 110 | 75  | 90  | metal_slash, iron_cleave, water_surge, earth_barrier | 590 |
| gan_ning        | 甘寧   | WATER | -1  | 110 | 108 | 85  | 112 | 75  | 80  | water_surge, iron_cleave, metal_slash, war_cry       | 570 |
| lu_xun          | 陸遜   | FIRE  | -1  | 100 | 85  | 90  | 95  | 118 | 105 | flame_burst, fire_strike, water_surge, wood_heal     | 593 |
| lv_meng         | 呂蒙   | WATER | -1  | 110 | 95  | 95  | 90  | 105 | 90  | water_surge, flame_burst, wood_heal, earth_barrier   | 585 |
| da_qiao         | 大喬   | YIN   | -1  | 85  | 60  | 80  | 95  | 110 | 115 | water_surge, flame_burst, wood_heal, earth_barrier   | 545 |

### Warlords (+5)

| id         | name | type  | 2nd | HP  | ATK | DEF | SPD | INT | SPR | moves                                                | Σ   |
| ---------- | ---- | ----- | --- | --- | --- | --- | --- | --- | --- | ---------------------------------------------------- | --- |
| dong_zhuo  | 董卓 | EARTH | -1  | 145 | 100 | 95  | 60  | 75  | 95  | iron_cleave, metal_slash, fire_strike, earth_barrier | 570 |
| yuan_shao  | 袁紹 | METAL | -1  | 120 | 90  | 90  | 80  | 95  | 100 | metal_slash, iron_cleave, earth_barrier, war_cry     | 575 |
| chen_gong  | 陳宮 | WATER | -1  | 95  | 70  | 85  | 90  | 110 | 105 | water_surge, wood_heal, earth_barrier, war_cry       | 555 |
| hua_tuo    | 華佗 | WOOD  | -1  | 95  | 55  | 80  | 85  | 110 | 120 | wood_heal, earth_barrier, war_cry, flame_burst       | 545 |
| zhang_jiao | 張角 | YIN   | -1  | 95  | 75  | 85  | 80  | 115 | 105 | flame_burst, water_surge, wood_heal, war_cry         | 555 |

### Flavored descriptions

- **zhang_liao**: "Wei's most feared general. Routed Sun Quan's army at Hefei
  and stopped a thousand warriors with eight hundred of his own."
- **xu_chu**: "A massive, loyal bodyguard of Cao Cao. His strength is said to
  rival that of a thousand men."
- **dian_wei**: "Cao Cao's first bodyguard. His twin halberds fell dozens of
  enemies before he died covering his lord's escape."
- **guo_jia**: "Cao Cao's sharpest strategist. Died young, but his foresight won
  the north before he left."
- **xun_yu**: "The architect of Wei's civil administration. Often called the
  true pillar of Cao Cao's rise."
- **cao_ren**: "The unbreakable shield of Wei. Held Fan Castle against Guan Yu's
  siege with a skeleton garrison."
- **xia_hou_yuan**: "A swift and fierce Wei general. Met his end at the hands of
  Huang Zhong at Mount Dingjun."
- **zhen_ji**: "Lady Zhen, famed beauty of the Wei court. Graceful and
  perceptive, favored of the Cao family."
- **liu_bei**: "The benevolent founder of Shu. Won hearts across the land with
  his kindness and ambition to restore the Han."
- **pang_tong**: "The 'Young Phoenix,' rival of Zhuge Liang. His genius was cut
  short at Fallen Phoenix Slope."
- **jiang_wei**: "Zhuge Liang's successor in the northern campaigns. Carried
  Shu's ambitions long after the master's death."
- **wei_yan**: "A fierce and proud Shu general. His talents were overshadowed by
  mistrust and a fiery temper."
- **huang_yue_ying**: "Zhuge Liang's wife and fellow inventor. Her mechanical
  brilliance built the wooden oxen and crossbow."
- **sun_shang_xiang**: "Sun Quan's martial sister, betrothed to Liu Bei. As
  fierce with a blade as any general."
- **sun_ce**: "The 'Little Conqueror.' With a thousand men he carved out the
  foundation of Wu in a single campaign."
- **tai_shi_ci**: "An archer of unmatched skill and a loyal knight. Served Wu
  with honor until his final arrow."
- **gan_ning**: "The 'Pirate General' of Wu. Feared at sea, he burned a thousand
  Cao ships in a night raid."
- **lu_xun**: "The quiet fire of Wu. Burned Liu Bei's army to ash at Yiling and
  outsmarted Wei for a decade."
- **lv_meng**: "The scholar-general of Wu. Slain by Guan Yu's ghost, but his
  scheme took the enemy's head first."
- **da_qiao**: "Eldest of the Qiao sisters, wife of Sun Ce. A beauty whose
  sorrow was sung of for centuries."
- **dong_zhuo**: "The tyrant who seized the Han capital. His brutality forged
  the alliance that would topple him."
- **yuan_shao**: "Proud lord of the north. Vast in power and following, undone
  by indecision at Guandu."
- **chen_gong**: "A strategist of shifting loyalty. Served Cao Cao, then Lü Bu,
  and died refusing to beg for life."
- **hua_tuo**: "The legendary physician. His surgeries and anesthesia were
  centuries ahead of their time."
- **zhang_jiao**: "The 'Great Teacher' of the Yellow Turbans. His rebellion
  shook the Han to its foundations."

## Risks / Trade-offs

- [WOOD/EARTH/YANG/YIN primary characters have no same-type damaging move in the
  pool] → Accepted; they borrow from other types. Documented in D4 and resolved
  by the follow-up move/type change.
- [Provisional types may need mass edits after the type redesign] → Single types
  only, secondary types avoided (all -1), keeping rework to one field per
  character.
- [Move overlap: all fighters share iron_cleave/metal_slash/war_cry combos] →
  Accepted for this change; character distinctiveness comes later with the move
  expansion.
- [Stat balance disputes] → All new characters sit below lv_bu (existing apex),
  so the power ceiling is preserved; individual tuning is easy via single .tres
  edits.

## Open Questions

None. Roster, stats, types, and moves are fully specified above; description
wording is cosmetic and adjustable during implementation.
