## Context

Moves with `power == 0` are divided into three categories: “stat boosts /
recovery / status ailments.” Currently, `action.rs::calculate_damage()` only
handles recovery (`healing`) and status ailments (`effect`); `stat_mod_stat` and
`stat_mod_stage` are parsed but not referenced at runtime. In addition,
`build_damage_log` is only called inside the `power > 0` block, so non-damaging
moves have an empty `log_message`.

The data model lacks a field representing “target,” making it impossible to
distinguish self-buff moves like `earth_barrier` from enemy debuff moves. Stats
are represented by the `Stat` enum (Attack=0..Spirit=4), and
`BattleParticipant::apply_stat_stage(stat, delta)` is already implemented but
has no caller. The bridge uses `part_dict` to pass `stat_stages` back and forth
to GDScript, so if the stage is changed on the Rust side, it will be reflected
in the UI.

## Goals / Non-Goals

**Goals:**

- Add `stat_mod_target` (target specification) to `MoveData` so that `SELF` /
  `TARGET` can be represented.
- Make `calculate_damage` apply stat boosts at runtime and update `stat_stages`.
- Generate `log_message` for non-damaging moves so that their effects appear in
  the battle log.
- Update all layers (core → battle → bridge → GDScript → data validation/export)
  consistently.
- Add tests to verify conformance with the spec.

**Non-Goals:**

- Changes to AI strategy (`BasicAi` / `_select_best_move`). Deciding whether to
  use non-damaging moves is out of scope for this change.
- Runtime application of `StatusEffectData.stat_mod_multiplier` (stat changes
  from status ailments like Charm). This is treated as a separate change.
- Harmonizing the stage range spec (spec says `[-6,+6]`, validator says
  `[-3,+3]`). Existing behavior is preserved; aligning spec and implementation
  is recorded as a separate issue.

## Decisions

### 1. `stat_mod_target` enum values are `SELF = 0` / `TARGET = 1`

Use the same numeric representation in both Rust and GDScript (same approach as
existing `Stat` / `TypeElement`).

```rust
#[repr(u8)]
pub enum StatModTarget {
    Self_ = 0,   // Applied to the attacker
    Target = 1,  // Applied to the defender
}
```

- **GDScript**: Add `enum StatModTarget { SELF, TARGET }` to
  `scripts/type_enums.gd`.
- Add `@export var stat_mod_target: int = TypeEnums.StatModTarget.SELF` to
  `move_data.gd` (default SELF = backward compatible).
- **Alternative**: Considered a bool `stat_mod_target_self`, but chose an enum
  to allow future extensions (e.g., whole party).

### 2. Application order and log generation in `calculate_damage`

Add stat-boost processing at the beginning of `calculate_damage` (after accuracy
check, before the `power > 0` block).

```
1. accuracy check (exit if miss)
2. if mv.has_stat_mod():
     target = if SELF { attacker } else { defender }
     target.apply_stat_stage(mv.stat_mod_stat, mv.stat_mod_stage)
     log_message += "{name}'s {stat} {rose|fell}!"
   (if stage > 0 then "rose", if < 0 then "fell"; add "sharply" for 2+ stages)
3. if mv.power > 0: existing damage processing (build_damage_log)
4. if mv.healing > 0: recovery processing
5. apply_status_effect
```

- `mv.has_stat_mod()` (existing method) is
  `stat_mod_stat.is_some() && stat_mod_stage != 0`.
- `apply_stat_stage` already clamps, so if the stage is already at the limit, it
  won’t change. The log records the “attempt” (read the effective stage
  beforehand and compare; if it changes, output a log).
- **Log wording**: Use English Poké-style wording, same as existing
  `build_damage_log`. E.g., `"{name}'s Defense rose sharply!"`. Multilingual
  support is a future task.
- **Alternative**: Considered splitting stat moves into a separate function
  `apply_stat_move()`, but to keep consistency with the existing flow (accuracy
  → effect application) inside `calculate_damage`, it is integrated there.

### 3. Guaranteeing `log_message` for non-damaging moves

Even for moves with `power == 0`, if a stat boost, status ailment, or recovery
occurs, always set `log_message`.

- Currently, recovery (`healing > 0`) and status ailments are already processed,
  but there are cases where the log remains empty (e.g., `war_cry`).
- If `ActionResult::log_message` is still empty at the end, set
  `"{name} used {move}!"` as a fallback. This ensures the UI’s `status_label` is
  never empty.
- **Alternative**: Considered having GDScript handle the fallback, but since
  Rust is the source of truth for logs, it is handled entirely on the Rust side.

### 4. Consistency in data validation and export

- Add an enum validity check for `stat_mod_target` (`Self_=0` / `Target=1`) to
  MR-4 in `validator.rs`.
- Similarly extend MR-4 in `systems/data/data_validator.gd`.
- Export `stat_mod_target` in `tools/data_export.gd`.
- Change `xiangke_checker`’s `MOVE_KEYS` from 14 → 15.
- Set `stat_mod_target = 0` (SELF) in `earth_barrier.tres`.

### 5. Testing strategy

| Layer                                    | Test content                                                                                                                                                                                 |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Rust unit (`action.rs`)                  | `power=0 + SELF + Defense+2` → attacker stage=2, log shows "rose"; `power=0 + TARGET + Attack-1` → defender stage=-1, log shows "fell"; non-damaging moves also have non-empty `log_message` |
| Rust integration (`integration.rs`)      | Run a battle including a self-buff move → verify `stat_stages` are updated                                                                                                                   |
| GDScript (`test_battle_flow_service.gd`) | Execute a self-buff move via the bridge → verify `get_front_participant(...).stat_stages` reflects the change                                                                                |

## Risks / Trade-offs

- **Log wording is fixed in English** → UI will show English text. Left as a
  future localization issue (existing `build_damage_log` is also English).
- **Default `stat_mod_target` is SELF** → Existing data (`earth_barrier`) is
  explicitly set, so no real harm. Unset data will be interpreted as self-buffs,
  but since stat boosts were not working at all before, backward compatibility
  is not broken.
- **Attack reduction from Charm remains unimplemented** → The description of
  `war_cry` (“charms and lowers Attack”) will be only partially implemented.
  However, this is a separate issue related to runtime application of
  `StatusEffectData.stat_mod_multiplier` and is explicitly out of scope.
- **Mismatch between spec and validator stage ranges** → Not changed this time.
  Recorded as a non-goal in `design.md`; spec will be cleaned up in a separate
  change.
