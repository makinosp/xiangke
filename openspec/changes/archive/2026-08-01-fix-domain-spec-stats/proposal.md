## Why

The domain spec contradicts itself: the Type System requirement lists 5 stats
(Attack, Defense, Speed, Intelligence, Spirit), while the Character Data
requirement and the actual game data define 6 stats including HP. The spec
should describe the real system: 6 stats with HP.

## What Changes

- Correct the Type System requirement in the `domain` spec to list 6 stats (HP,
  Attack, Defense, Speed, Intelligence, Spirit), matching the Character Data
  requirement.
- Spec/documentation correction only — no gameplay or code behavior changes.

## Capabilities

### New Capabilities

<!-- None -->

### Modified Capabilities

- `domain`: Type System requirement corrected from "5 stats" to "6 stats" (HP
  included), resolving the internal contradiction.

## Impact

- `openspec/specs/domain/spec.md` — Type System requirement description updated
  via delta spec sync.
- No source code, resources, or tests affected.
