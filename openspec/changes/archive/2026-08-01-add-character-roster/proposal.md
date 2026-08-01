## Why

The playable roster is only 13 characters, which makes corps selection (6 per
side) feel thin and offers little variety across battles. The user wants to
expand the roster significantly now, and revisit the type system design in a
separate change afterwards.

## What Changes

- Add 25 new `CharacterData` resource files under `resources/characters/`,
  growing the roster from 13 to 38 characters across all four factions (Wei,
  Shu, Wu, and Warlords).
- Assign each new character provisional primary/secondary types based on
  archetype; types are explicitly provisional and will be reworked in a
  follow-up change (type system redesign).
- Do **not** add any new moves — every new character picks exactly 4 moves from
  the existing 8-move pool.
- No code changes: `DataLoader` auto-discovers `.tres` files, and existing
  validation (Rust + GDScript) runs at startup.
- No spec-level behavior changes — this is pure data population.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This change adds content (character data files) without altering any
requirements in `openspec/specs/`. The Character Data requirement already
defines the schema and validation rules that the new files must satisfy.
`skip_specs: true` is set in `.openspec.yaml`.

## Impact

- `resources/characters/*.tres` — 25 new files created.
- `DataRegistry` — loads the new characters automatically via `DataLoader`
  (`res://resources/characters/` scan).
- Validation — both `extensions/core/src/validator.rs` (authoritative) and
  `systems/data/data_validator.gd` validate all new characters at startup. Every
  character must satisfy: lowercase snake_case id, name 1–20 chars, stats in [1,
  500] (hard cap 999), stat sum ≤ 3000, exactly 4 moves, and at least one
  damaging move (power > 0).
- Character selection screens (`corps_creation`, `character_select`) show the
  expanded roster with no changes needed.
- Tests — no existing tests hardcode the roster size; no test changes expected.
