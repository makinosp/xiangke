# Tasks: Character Portraits in Battle UI

## Task List

### T1: Create Placeholder Asset

- [x] Create `assets/portraits/` directory
- [x] Create placeholder.png (120x180px, 2:3 ratio, silhouette style)
- [x] Verify asset imports correctly in Godot

### T2: Add portrait_path to CharacterData

- [x] Add `@export var portrait_path: String = ""` to scripts/character_data.gd
- [x] Add documentation comment
- [x] Verify no syntax errors

### T3: Update BattleUnitPanel UI

- [x] Add `_portrait_rect: TextureRect` member variable
- [x] Add `_placeholder_texture: Texture2D` member variable
- [x] Modify `_build_ui()` to create and add TextureRect at top of VBox
- [x] Configure TextureRect: expand_mode (EXPAND_IGNORE_SIZE), stretch_mode,
      custom_minimum_size
- [x] Load placeholder texture in `_ready()` or `_build_ui()`
- [x] Add `_load_portrait(portrait_path: String)` helper method
- [x] Call `_load_portrait()` in `update_from_participant()`
- [x] Call `_load_portrait()` in `show_hidden_placeholder()` with gray modulate
- [x] Call `_load_portrait()` in `show_defeated_placeholder()` with gray
      modulate

### T4: Update Character Resources

- [x] Add `portrait_path = ""` to all character .tres files in
      resources/characters/
- [x] Can be done via script or manually

### T5: Size Modes

- [x] Add `SizeMode` enum (STANDARD / LARGE / SMALL) to BattleUnitPanel
- [x] Add `set_size_mode(mode)` API that applies the preset immediately
- [x] LARGE: portrait 160x240, status/stat rows visible, min 176x321
- [x] SMALL: portrait 40x60, status/stat rows hidden, min 80x109
- [x] STANDARD: unchanged 120x180 default

### T6: Slanted Battle Layout

- [x] Rebuild battle_scene.tscn with diagonal arrangement
- [x] PlayerFrontPanel bottom-left (LARGE), EnemyFrontPanel top-right (LARGE)
- [x] PlayerBenchContainer / EnemyBenchContainer top-left (SMALL rows)
- [x] MoveContainer bottom-right, BattleLog bottom-left
- [x] All panels fit within 1280x720 viewport (verified via measurement)

### T7: Front/Bench Update Logic

- [x] Replace per-team HP containers with front panel + bench row updates
- [x] `_update_player_team()`: front LARGE + highlight, bench SMALL panels
- [x] `_update_enemy_team()`: front LARGE, bench SMALL with visibility rules
- [x] Reuse existing `_resize_panels()` panel pool pattern

### T8: Integration Testing

- [x] Run battle scene
- [x] Verify player team portraits show placeholder
- [x] Verify enemy team: hidden = grayed placeholder, revealed = placeholder
- [x] Test character switch updates portraits
- [x] Test enemy reveal updates portrait
- [x] Test defeated enemy shows grayed placeholder
- [x] Check console for errors
- [x] Visual confirmation via screenshot (user reviewed, no issues)

### T9: Run Test Suite

- [x] Run existing unit tests
- [x] Update `test_opponent_visibility.gd` for new front/bench structure
- [x] Add SizeMode tests (LARGE/SMALL/STANDARD)
- [x] Verify no regressions (68 tests pass)

## Dependencies

```
T1 → T3 (placeholder needed for panel)
T2 → T3 (CharacterData field needed)
T3 → T4 (panel must work before configuring resources)
T3 → T5 (portrait rect needed for size presets)
T5 → T6 (size modes needed before layout)
T6 → T7 (layout needed before update logic)
T3 → T8 (panel must work before testing)
T8 → T9 (integration tests before full suite)
```
