# Design: Improve Character Select Preview

## Context

Both the corps creation screen and the character select screen share an
identical `StatsPreview` structure: a `Panel` anchored to the right side of the
viewport with fixed-offset child labels. In `scenes/character_select.tscn` the
panel spans anchors 0.55–0.95 x / 0.35–0.8 y, which is 512×324 px at 1280×720.

The current content layout is hardcoded in the scene file:

| Element     | Y range | Notes                                                 |
| ----------- | ------- | ----------------------------------------------------- |
| Name        | 10–40   |                                                       |
| Type        | 45–65   |                                                       |
| HP…Spirit   | 68–203  | 6 rows × 23px                                         |
| Move list   | 206–286 | VBoxContainer, 80px — needs ~92px (4×20 + separators) |
| Description | 290–370 | Label ends 46px below the panel bottom (324)          |

Consequences verified against the 1280×720 viewport:

- The fourth move row overflows the 80px container and overlaps the description
  label (which draws on top), hiding the last move.
- The description label extends 46px past the panel's bottom edge and its text
  collides with the panel border.
- All labels are fixed at x=10–200 (~190px wide) while the panel is ~512px wide,
  so the description wraps into more lines than necessary, increasing the
  vertical pressure.

On the character select screen the opponent corps is built in
`_load_opponent_display()` as plain `Label` nodes (reddish tint) inside a
`ScrollContainer`. Labels default to `MOUSE_FILTER_IGNORE`, so no mouse events
are emitted and there is no hover preview for opponents. Player characters get
`mouse_entered`/`mouse_exited` wiring to `_on_character_hovered` /
`_on_character_hover_exit` at button creation time.

`corps_creation.tscn` has the same `StatsPreview` panel (anchors 0.65–0.95 x /
0.1–0.75 y, ~384×468px at 1280×720) and the same fixed-offset labels, so it
carries the identical overflow/overlap bug. It has no opponent panel.

## Goals / Non-Goals

**Goals:**

- All preview content (name, type, 6 stats, 4 moves, description) fully visible
  inside the panel with no clipping and no element overlap on both screens
- Description wraps within the panel and never collides with the move list
- Hovering an opponent character on the character select screen shows the same
  overview window, and leaving the label hides it
- Player vs opponent remains visually distinguishable (existing reddish enemy
  tint on the opponent list labels)

**Non-Goals:**

- Changing selection rules, deploy logic, or roster data
- Adding keyboard focus support for the opponent list (mouse hover only; the
  opponent list stays read-only)
- Changing the battle screen or the Rust bridge

## Decisions

### D1: Container-based preview layout with full-width labels

Restructure `StatsPreview` into a `MarginContainer` (10px padding) wrapping a
`VBoxContainer`:

```
StatsPreview (Panel, anchors unchanged)
└── MarginContainer
    └── VBoxContainer
        ├── NameLabel          (autowrap, full width)
        ├── TypeLabel
        ├── HP … Spirit        (6 labels, full width)
        ├── MovesContainer     (VBox, 4 move labels)
        └── DescLabel          (size_flags_vertical = EXPAND_FILL,
                                autowrap_word_smart, full width)
```

Child labels drop their fixed `offset_right` so they span the container width;
their text becomes right-cropped/autowrapped by the container instead of being
hard-limited to 190px. The scene files gain a `MarginContainer` +
`VBoxContainer` wrapper, and the label offsets change from fixed pixel rects to
container-managed layout.

**Rationale:** fixed pixel offsets are the root cause of the bug — the panel
height is viewport-derived (anchors), while the content size is hardcoded, so
any viewport/theme/font change breaks the fit. Containers make content height
derive from actual text and let the description absorb remaining space.

**Alternatives considered:** shrinking fonts — rejected, harms readability on
the Web target; expanding the panel and shrinking other UI — rejected, the
right-side panel position already occupies the available space; keeping fixed
offsets but compressing rows — rejected, remains fragile and still clips at
other font sizes/locales (e.g. longer translated labels).

### D2: Description fills remaining space below the move list

`DescLabel` gets `size_flags_vertical = SIZE_EXPAND_FILL` and
`autowrap_mode = TextServer.AUTOWRAP_WORD_SMART`. With the container layout it
occupies whatever vertical space the move list does not use, ending exactly at
the panel bottom. `max_lines_visible` and `lines_truncated` are removed so the
text wraps and clips via the container instead of being truncated at a fixed
line count.

**Rationale:** the description is variable-length (per-locale flavor text), so
it must be the flexible element. Anchoring it to the panel bottom via container
expansion guarantees no overflow regardless of locale or font.

### D3: Opponent hover preview via mouse_filter + existing handlers

In `_load_opponent_display()`, each opponent `Label` gets:

- `mouse_filter = Control.MOUSE_FILTER_STOP` (default is `IGNORE`, without this
  no mouse events are emitted)
- `mouse_entered` → `_on_character_hovered(char_id)` (existing)
- `mouse_exited` → `_on_character_hover_exit` (existing)

The reddish tint on the opponent list label is kept, so the list stays visually
distinct from the player's corps. The preview panel itself is identical for both
sides (same `CharacterData` fields), which is acceptable because the preview is
shown in the same fixed panel position and the opponent list already
communicates enemy identity.

**Rationale:** reusing `_on_character_hovered` avoids duplicating the population
logic and guarantees the same rendering path. No focus-group registration is
added, so keyboard navigation behavior is unchanged.

**Alternatives considered:** dedicated `_on_opponent_hovered` with an enemy flag
— rejected, the preview content is identical and a flag would only add a code
path without user-visible value; keeping labels as-is — rejected, that is the
current broken behavior.

### D4: Apply the same layout fix to corps_creation

The corps creation screen's `StatsPreview` (identical structure, no opponent
panel) gets the same container-based layout from D1/D2. No hover changes are
needed there — player hover already works and there is no opponent list.

**Rationale:** the two screens share a duplicated `StatsPreview` structure and
the same bug; fixing only one leaves an inconsistent experience. The change is
mechanical (same scene restructuring), so keeping both in scope is cheap.

## Risks / Open Questions

- **Text length variance across locales:** container layout absorbs vertical
  differences, but extremely long descriptions could still exhaust panel space
  and clip at the bottom. Mitigation: the description is the flex element and
  wraps at full width; verification tests pin a worst-case description (longest
  catalog entry) inside the panel.
- **Mouse hover vs scroll on the opponent list:** the list sits inside a
  `ScrollContainer`; `mouse_entered`/`mouse_exited` fire on the label bounds
  regardless of scrolling, and `mouse_exited` fires when the pointer leaves the
  label, so scrolling away correctly hides the preview. No additional handling
  needed, but worth a manual check.
- **Scene restructure vs code-built UI:** the preview labels are referenced by
  `@onready` paths (`$StatsPreview/NameLabel` etc.) in both scripts. Adding the
  `MarginContainer`/`VBoxContainer` wrapper changes those paths
  (`$StatsPreview/MarginContainer/VBoxContainer/NameLabel`), so both
  `character_select.gd` and `corps_creation.gd` must update their `@onready`
  references, or the nodes must be re-parented via unique names. Prefer updating
  the `@onready` paths to keep the scene structure explicit.
