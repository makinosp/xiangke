## Context

The current game state machine in `game_manager.gd` defines a linear flow: TITLE
→ CORPS_CREATION → CHARACTER_SELECT → BATTLE → RESULT. Each state maps to a
single scene. The `corps_creation` scene handles both character selection and
persistence, then hands off to `character_select` for battle deployment.

The title screen has two buttons: "Start" (→ CORPS_CREATION) and "Settings" (→
SETTINGS). Back buttons exist only on the settings screen.

## Goals / Non-Goals

**Goals:**

- Make the title screen a navigation hub with three destinations
- Separate corps configuration (persistent) from battle preparation
- Add back buttons to all sub-screens for consistent navigation
- Keep the change minimal — no new scenes, reuse existing `corps_creation` scene

**Non-Goals:**

- Multiple saved corps rosters (future work)
- Drag-and-drop or visual corps editor
- Corps preview on the title screen

## Decisions

### D1: Reuse corps_creation scene as Corps Settings

Rather than creating a new scene, repurpose `corps_creation.tscn` and its
script. The screen's behavior is identical — select 6 characters, save — only
the entry/exit points change.

**Alternative considered**: Create a dedicated `corps_settings.tscn`. Rejected
because the UI and logic are the same; duplicating would add maintenance cost
with no benefit.

### D2: GameState enum adds TITLE → CORPS_SETTINGS and TITLE → CHARACTER_SELECT

The state machine gets two new transitions from TITLE:

```
TITLE → CORPS_SETTINGS   (existing CORPS_CREATION repurposed)
TITLE → CHARACTER_SELECT (new direct path)
```

CORPS_SETTINGS returns to TITLE (not CHARACTER_SELECT). The linear chain
CORPS_CREATION → CHARACTER_SELECT is replaced by two independent spokes.

**Alternative considered**: Keep the linear flow but add a back button. Rejected
because it doesn't achieve the goal of separating the two phases.

### D3: Start button disabled state via save data check

On `_ready()`, the title screen checks `SaveManager.current_data` for a valid
6-character `corps_characters` array. If absent or incomplete, the Start button
is `disabled = true`.

### D4: Back button implemented as a Button node with signal

Each sub-screen gets a `BackButton` node connected to a handler that calls
`GameManager.transition_to_state(GameManager.GameState.TITLE)`. This follows the
existing pattern used by the settings screen.

### D5: Corps Settings save-and-back vs. separate save button

The corps settings screen gets two buttons: "Save & Back" (saves then returns to
title) and "Back" (returns without saving). This avoids adding a third screen
state for a separate save confirmation.

## Risks / Trade-offs

- **[Risk]** Existing save data from the old flow may have `corps_characters`
  set but no `battle_characters`. → Mitigation: The title screen already clears
  `battle_characters` on Start; this pattern continues.

- **[Trade-off]** Reusing the corps_creation scene means its internal flow
  (confirm → CHARACTER_SELECT) must be removed. The confirm button now saves and
  returns to title instead. This is a behavioral change to an existing scene
  rather than a clean separation, but the code change is small.
