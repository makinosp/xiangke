# Build Instructions

## Prerequisites

- **Engine**: Godot 4.x (4.3 or later recommended)
- **Export Templates**: Installed via Godot Editor → Manage Export Templates
- **System Requirements**:
  - macOS 10.15+ / Windows 10+ / Ubuntu 20.04+
  - 4 GB RAM minimum
  - 500 MB disk space for editor + project
- **Environment Variables**: None required

## Build Steps

### 1. Open Project in Godot Editor

```bash
# Launch Godot and open the project
godot --path /path/to/xiangke
```

Or open Godot Editor → Import → select `project.godot`.

### 2. Verify Project Loads Correctly

- No errors in the Output panel
- `DataRegistry` autoload is registered (Project → Project Settings → Autoload)
- All `.tres` files appear in the FileSystem dock

### 3. Run Project in Editor (F5)

Press **F5** or click the Play button to run the project in the editor.

**Expected Output:**

```
DataRegistry: All data loaded and validated successfully.
  Characters: 3 | Moves: 7
```

### 4. Export HTML5 (Web)

```
Project → Export → Add → Web
→ Set export path: build/web/index.html
→ Click "Export Project"
```

**Expected Artifacts:**

- `build/web/index.html`
- `build/web/index.wasm`
- `build/web/index.pck`
- `build/web/index.js`

### 5. Export Desktop (Optional)

```
Project → Export → Add → Windows/macOS/Linux
→ Set export path: build/desktop/xiangke
→ Click "Export Project"
```

### 6. Verify Export Success

- HTML5: Open `build/web/index.html` in a browser, check console for errors
- Desktop: Run the executable, verify it launches without crashes

## Troubleshooting

### "DataRegistry" autoload not found

- **Cause**: `project.godot` not properly configured
- **Solution**: Re-open project, check Project Settings → Autoload tab

### `.tres` files fail to load

- **Cause**: Script class not registered (missing `class_name` or `@tool`)
- **Solution**: Verify `scripts/character_data.gd` and `scripts/move_data.gd`
  have `class_name` and `@tool` annotation

### Validation errors on load

- **Cause**: Sample data violates business rules
- **Solution**: Check Output panel for `[DataValidator]` error messages, fix the
  offending `.tres` file

### Export fails with "template not found"

- **Cause**: Export templates not installed
- **Solution**: Editor → Manage Export Templates → Download and Install
