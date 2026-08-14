## Context

The battle scene (`scenes/battle_scene.tscn` +
`scripts/foundation/battle_scene.gd`) uses a flat layout with 7 nodes and zero
nesting. All content is created dynamically at runtime via `Button.new()`,
`Label.new()`, `container.add_child()`. The HP display (`_update_team_hp()`)
destroys and recreates all labels on every call — multiple times per turn.
`BattleParticipant` already carries `stat_stages: Array[int]` (5 values) and
`active_status_effects: Array[int]` but neither is surfaced in the UI. The
`TypeEnums` and `DataRegistry` provide all necessary data.

Constraints: GDScript-only changes (no Rust modifications). Must work on Web
(HTML5/WASM) target. No external art assets — all visuals are programmatically
generated. Existing `BattleFlowService` signals (`turn_started`,
`action_executed`, etc.) are currently unconnected.

## Goals / Non-Goals

**Goals:**

- Replace text-only HP with visual progress bars that convey health status at a
  glance
- Surface all battle-relevant state: status effects, stat stages, character
  types
- Introduce a reusable `BattleUnitPanel` component to reduce code duplication
  across HP, switch, and future UIs
- Maintain the existing battle flow logic unchanged — purely visual layer

**Non-Goals:**

- Battle animations, damage numbers, or hit effects (separate change)
- Audio integration (BGM/SFX during battle — separate change)
- Keyboard/controller navigation via UIFocusManager (separate change)
- Character portraits or sprite art (requires external assets)
- HP bar tween animations (smooth fill transitions — possible follow-up)
- Custom Theme resource or font changes (keep using programmatic overrides)

## Decisions

### D1: BattleUnitPanel as a standalone scene

**Decision**: Create `scenes/battle_unit_panel.tscn` with a
`scripts/battle_unit_panel.gd` script as a reusable `Control` node.

**Rationale**: The current `_update_team_hp()` recreates labels from scratch
every call. A scene-based panel can be instantiated once per participant and
updated in-place via a public `update_from_participant()` method. This also
enables reuse in the switch selection UI and potential future screens.

**Alternatives considered**:

- _Extend existing Label nodes_: Rejected — Labels can't natively hold HP bars +
  status badges + type info without becoming unwieldy.
- _Use a Control with manual child creation in GDScript_: Rejected — a `.tscn`
  scene is easier to read, inspect in the editor, and maintain.

### D2: Godot ProgressBar for HP visualization

**Decision**: Use Godot's built-in `ProgressBar` (with
`show_percentage = false`) for HP bars.

**Rationale**: `ProgressBar` provides a fill-based visual with minimal code.
Color is set via `modulate` based on HP ratio thresholds (green ≥ 50%, yellow
25–50%, red < 25%). No custom StyleBox needed — the default theme provides a
reasonable look.

**Alternatives considered**:

- _TextureProgressBar_: More visual flexibility but requires texture assets —
  rejected for asset-free constraint.
- _Custom ColorRect + Tween_: More control but significantly more code for
  marginal benefit.

### D3: Text-based status effect badges

**Decision**: Display status effects as `Label` nodes with emoji/text prefixes
(e.g., "🔥炎", "☠毒", "❓混乱").

**Rationale**: No art assets exist. Emoji provides instant visual recognition
and works on Web. The `StatusEffectData` from `DataRegistry` supplies display
names. A `TypeColors` utility maps effect types to colors for the label
modulate.

**Alternatives considered**:

- _TextureRect with icons_: Requires icon assets — deferred to future art pass.
- _Color-coded dots only_: Too ambiguous for 5+ effects.

### D4: Stat stage display as compact text

**Decision**: Show stat stages as a single-line `Label` below the HP bar (e.g.,
"ATK↑2 DEF↓1"). Only show stats with non-zero stages to reduce clutter.

**Rationale**: Stat stages range from -3 to +3 across 5 stats. Showing all 5 at
all times would be noisy. Filtering to non-zero stages keeps the display clean
while preserving tactical information.

**Alternatives considered**:

- _5 separate colored bars per stat_: Too much visual space for a 1280×720
  viewport.
- _Tooltip on hover_: Inaccessible on Web touch devices.

### D5: TypeColors as a static utility

**Decision**: Create `scripts/foundation/type_colors.gd` as a `@tool` script
with static methods for type-to-color mapping and status effect labels.

**Rationale**: Type colors need to be consistent across move buttons, character
panels, and any future UI. A single source of truth prevents color drift. The
`@tool` annotation allows use in the editor for preview.

### D6: Preserve existing container layout

**Decision**: Keep `PlayerHPContainer` and `EnemyHPContainer` as `HBoxContainer`
nodes. Replace their child `Label` nodes with `BattleUnitPanel` instances.

**Rationale**: The existing anchor-based layout (player top-left, enemy
top-right) works well. Changing the container type would require reworking the
`.tscn` anchors. HBoxContainer naturally stacks panels side by side.

### D7: Incremental update pattern

**Decision**: On first `_update_team_hp()` call, create `BattleUnitPanel`
instances and store them in a dictionary keyed by slot index. On subsequent
calls, iterate stored panels and call `update_from_participant()`.

**Rationale**: Eliminates the current destroy-recreate pattern. Panels are
created once, updated in place. The dictionary keyed by slot index handles
front/bench reordering when switches occur.

## Risks / Trade-offs

- **[Risk] Panel count mismatch on switch** → When a switch happens, the panel
  at a given HBoxContainer position changes identity. Mitigation: store panels
  in an `Array` per container, reorder on switch by clearing and re-adding in
  the new order (panels are reused, not recreated).
- **[Risk] ProgressBar visual inconsistency on Web** → Godot's default theme
  ProgressBar may look different across platforms. Mitigation: acceptable for
  MVP; a custom StyleBox can be added later if needed.
- **[Risk] Status effect badge overflow** → A character with 3+ simultaneous
  effects could overflow the panel width. Mitigation: use `HBoxContainer` with
  `SIZE_EXPAND` and allow text to wrap or truncate; the current engine limits
  effects to a u8 bitfield (max 8).
- **[Trade-off] No HP bar animation** → HP changes instantly without smooth fill
  transition. This is simpler and avoids tween management complexity. Can be
  added as a follow-up.
- **[Trade-off] Emoji rendering varies by platform** → Some emoji may render
  differently on Web vs desktop. Mitigation: use simple, widely-supported emoji
  (🔥☠❓⚡✨).
