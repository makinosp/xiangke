# Design: Character Portraits in Battle UI

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     BattleUnitPanel                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ TextureRect (Portrait) - NEW                             │ │
│ │   - expand_mode: KEEP_ASPECT_CENTERED                    │ │
│ │   - custom_minimum_size: Vector2(120, 180)  # 2:3 ratio  │ │
│ │   - texture: Load from CharacterData.portrait_path       │ │
│ │   - fallback: res://assets/portraits/placeholder.png     │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ HBox: Name + Type                                        │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ HP Bar + Text                                            │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ Status Effects                                           │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ Stat Stages                                              │ │
│ └─────────────────────────────────────────────────────────┘ │
```

## Data Model Changes

### CharacterData (scripts/character_data.gd)

```gdscript
## Path to character portrait image (2:3 aspect ratio recommended).
## Defaults to placeholder if empty or file not found.
@export var portrait_path: String = ""
```

### Resource Files (resources/characters/*.tres)

Each character gets a `portrait_path` entry:

```gdscript
portrait_path = "res://assets/portraits/cao_cao.png"
```

## Asset Structure

```
assets/
└── portraits/
    ├── placeholder.png          # Default fallback (2:3 ratio)
    ├── cao_cao.png              # Per-character portraits
    ├── cao_ren.png
    └── ...                      # One per character
```

## BattleUnitPanel Changes (scripts/battle_unit_panel.gd)

### New Member Variables

```gdscript
## Portrait display area
var _portrait_rect: TextureRect
## Cached placeholder texture
var _placeholder_texture: Texture2D
```

### UI Building (_build_ui)

Add portrait TextureRect as first child of main VBox:

```gdscript
_portrait_rect = TextureRect.new()
_portrait_rect.expand_mode = TextureRect.EXPAND_KEEP_ASPECT_CENTERED
_portrait_rect.custom_minimum_size = Vector2(120, 180)
_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
vbox.add_child(_portrait_rect)
```

### Portrait Loading Logic

```gdscript
func _load_portrait(portrait_path: String) -> void:
    var texture: Texture2D = null
    if portrait_path != "":
        texture = load(portrait_path)
    if texture == null:
        texture = _placeholder_texture
    _portrait_rect.texture = texture
```

### Integration Points

- `update_from_participant()`: Load portrait from
  `p.character_data.portrait_path`
- `show_hidden_placeholder()`: Load placeholder (grayed out via modulate)
- `show_defeated_placeholder()`: Load placeholder (grayed out via modulate)

## Enemy Portrait Visibility

| Slot State              | Portrait Display                                |
| ----------------------- | ----------------------------------------------- |
| Hidden (never revealed) | Placeholder, grayed out (modulate = Color.GRAY) |
| Revealed, alive         | Character portrait                              |
| Revealed, defeated      | Placeholder, grayed out with "DEFEATED" styling |

## Placeholder Image Spec

- Size: 120x180px (2:3 ratio)
- Style: Silhouette or generic "?" character
- Format: PNG with transparency

## Implementation Sequence

1. **Create placeholder asset** → `assets/portraits/placeholder.png`
2. **Add `portrait_path` to CharacterData** → scripts/character_data.gd
3. **Update BattleUnitPanel UI** → scripts/battle_unit_panel.gd
4. **Update character resources** → resources/characters/*.tres (add
   portrait_path = "")
5. **Test integration** → Run battle scene, verify both teams

## Size Modes (BattleUnitPanel)

Added to support the slanted layout: front characters render large,
bench characters render small.

```gdscript
enum SizeMode { STANDARD, LARGE, SMALL }

# Preset values (applied via _apply_size_mode())
# STANDARD: portrait 120x180, fonts 14/12/11, panel min 160 wide
# LARGE:    portrait 160x240, fonts 16/14/13, panel min 176x321,
#           status + stat rows visible
# SMALL:    portrait 40x60, fonts 10/9/9, status + stat rows hidden,
#           panel min 80x109
```

- Portrait TextureRect uses `expand_mode = EXPAND_IGNORE_SIZE` so the
  preset's `custom_minimum_size` wins over the texture pixel size.
- `set_size_mode(mode)` stores the preset and applies it immediately when
  the UI is built (or once `_build_ui()` runs).
- Panel margins adapt: SMALL=4, STANDARD=6, LARGE=8.

## Slanted Battle Layout (battle_scene.tscn)

Diagonal arrangement so large front panels (176x321 min) coexist with the
move list (min height 332) in a 1280x720 viewport.

```
┌──────────────────────────────────────────────────────┐
│  [StatusLabel "Battle!"]                              │
│  [PlayerBench SMALL]          [EnemyFrontPanel LARGE] │
│  [EnemyBench SMALL]                                   │
│  [PlayerFrontPanel LARGE]     [MoveContainer]         │
│  [BattleLog]                                          │
└──────────────────────────────────────────────────────┘
```

Anchor layout (viewport 1280x720):

| Node                  | Anchor X      | Anchor Y   | Size (approx.) |
| --------------------- | ------------- | ---------- | -------------- |
| StatusLabel           | 0.5 centered  | 0.005      | 320x28         |
| PlayerBenchContainer  | 0.02-0.44     | 0.05       | h=112 (SMALL)  |
| EnemyBenchContainer   | 0.02-0.44     | 0.21       | h=112 (SMALL)  |
| PlayerFrontPanel      | 0.02-0.44     | 0.375-0.825| LARGE          |
| EnemyFrontPanel       | 0.55-0.98     | 0.05-0.496 | LARGE          |
| MoveContainer         | 0.55-0.98     | 0.52-0.982 | min h=332      |
| BattleLog             | 0.02-0.5      | 0.845-1.0  | fill           |

Front/bench update flow in battle_scene.gd:

- `_update_player_team()`: front → LARGE panel + front highlight;
  remaining corps → SMALL panels in `player_bench_container`
- `_update_enemy_team()`: front corps index marked revealed → LARGE panel;
  other corps → SMALL panels (revealed=portrait, revealed+defeated=grayed
  placeholder, hidden=hidden placeholder)
