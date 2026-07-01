# Build Instructions — Unit 2: Game Foundation

## Overview

Build instructions for the game foundation layer (Unit 2). This layer provides
the core application lifecycle, scene management, persistence, and audio
systems.

---

## Prerequisites

- Godot 4.x (latest stable) installed
- Export templates installed (for HTML5 export)
- Project files from Unit 1 (Resources) already in place

---

## Build Steps

### 1. Open Project

```bash
# Open project in Godot editor
godot --path /path/to/xiangke
```

### 2. Verify Autoloads

In Godot Editor:

1. Go to Project → AutoLoad
2. Verify the following are registered:
   - `DataRegistry` → `autoloads/data_registry.gd`
   - `GameManager` → `autoloads/game_manager.gd`
   - `SaveManager` → `autoloads/save_manager.gd`
   - `AudioManager` → `autoloads/audio_manager.gd`
   - `UIFocusManager` → `autoloads/ui_focus_manager.gd`

### 3. Run in Editor

Press F5 or click "Play" to run the project.

**Expected Flow:**

1. Title screen appears
2. Click "Start" button
3. Audio initializes (Web) or loads (Desktop)
4. Character select screen loads
5. Select 6 characters → "Confirm Corps"
6. Select 3 characters → "Deploy"
7. Battle placeholder scene (auto-advances after 1 second)
8. Result screen shows "Victory!" or "Defeat..."
9. Click "Return to Title" to loop back

---

## Export Instructions

### HTML5 Export

```bash
# Export HTML5 build
godot --headless --export-release "HTML5" build/web/index.html
```

**Output Files:**

- `build/web/index.html`
- `build/web/index.wasm`
- `build/web/index.pck`
- `build/web/index.js`

### Desktop Export

```bash
# Export Windows build
godot --headless --export-release "Windows Desktop" build/xiangke-windows.exe

# Export macOS build
godot --headless --export-release "macOS" build/xiangke-macos.zip

# Export Linux build
godot --headless --export-release "Linux/X11" build/xiangke-linux.x86_64
```

---

## Troubleshooting

### Autoload Not Found

**Error**: `Invalid get index 'get_character' (on base: 'Nil').`

**Solution**: Ensure autoloads are registered in `project.godot` under
`[autoload]` section.

### Scene Not Found

**Error**: `Failed to load scene: res://scenes/title_screen.tscn`

**Solution**: Ensure all `.tscn` files are in the `scenes/` directory.

### Audio Not Playing (Web)

**Error**: No audio on first click.

**Solution**: This is expected behavior. The "Click to Start" screen must be
used to initialize audio. Check browser console for autoplay policy messages.

### Save File Issues

**Error**: Save data not persisting.

**Solution**: Check that `user://save.cfg` is being written. On Web, this is
sandboxed and may be cleared on browser refresh.
