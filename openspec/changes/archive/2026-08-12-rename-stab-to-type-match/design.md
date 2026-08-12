## Context

The codebase has already migrated from "STAB" to "type match" terminology in
Rust code (`is_type_matched`, `TYPE_MATCH_MULTIPLIER`,
`RawDamage.is_type_matched`). The remaining work is cleanup of historical
references, test naming, spec documentation, and bridge exposure. See
proposal.md for motivation.

## Goals / Non-Goals

**Goals:**

- Eliminate all "STAB" terminology from source code and comments
- Document the type match bonus mechanic in the domain spec
- Expose `is_type_matched` to GDScript via the bridge for UI feedback
- Disambiguate the GDScript test name that conflates "same type" with type
  effectiveness

**Non-Goals:**

- Changing the 1.5× multiplier value
- Changing the damage calculation pipeline order
- Renaming the `test_same_type_effectiveness_is_neutral` proptest in Rust (it
  tests type chart neutrality, not STAB)

## Decisions

### Decision: Remove historical STAB reference from doc comment

The comment on `is_type_matched` in `action.rs` line 76 says "formerly known as
STAB / Same-Type Attack Bonus". This historical reference is unnecessary noise.
The function name and surrounding code already use "type match" consistently.

**Rationale:** Keeping historical references in comments creates confusion for
new contributors who may search for "STAB" and find stale references.

### Decision: Rename GDScript test for clarity

`test_same_type_is_neutral` in `tests/unit/test_type_chart.gd` tests that
same-type effectiveness is 1.0× (neutral). This is about the type chart, not the
type match bonus. Renaming to `test_same_type_effectiveness_is_neutral`
disambiguates it.

**Rationale:** The current name could be confused with the STAB/type-match
concept, especially during a terminology migration.

### Decision: Expose `is_type_matched` in bridge result dict

The `result_dict()` function in `extensions/godot_bridge/src/lib.rs` currently
does not include `is_type_matched`. Adding it allows GDScript to display
"same-type attack bonus!" feedback to the player.

**Rationale:** The `ActionResult` struct already tracks this internally via
`RawDamage.is_type_matched`, but it's not propagated to the `ActionResult`
struct or serialized. We need to add it to `ActionResult` and expose it in the
bridge.

### Decision: Add type match bonus to domain spec

The domain spec's "Damage Calculation" requirement mentions `type_mult` but
doesn't define the 1.5× type match multiplier. Adding a dedicated requirement
documents this as a first-class game mechanic.

**Rationale:** The spec should document all observable game mechanics, not just
implementation details.

## Risks / Trade-offs

- **Risk:** Adding `is_type_matched` to `ActionResult` changes the struct layout
  → **Mitigation:** It's a new field, no existing fields change; GDScript
  consumers that don't read it are unaffected.
- **Risk:** Renaming the GDScript test could break CI if tests are referenced by
  name → **Mitigation:** Verify no other code references the test by name.
