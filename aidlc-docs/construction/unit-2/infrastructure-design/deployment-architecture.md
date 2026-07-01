# Deployment Architecture — Unit 2: Game Foundation

## Overview

This document describes the deployment pipeline, release process, and runtime
architecture for the game foundation layer.

---

## Deployment Environments

### Environment Overview

| Environment     | Platform                      | Purpose                     | URL/Access                               |
| --------------- | ----------------------------- | --------------------------- | ---------------------------------------- |
| **Development** | Local Godot editor            | Active development, testing | `localhost` (Godot play)                 |
| **Preview**     | Cloudflare Pages (PR preview) | Pull request validation     | `https://xiangke.pages.dev/pr-{number}/` |
| **Production**  | Cloudflare Pages (main)       | Public game access          | `https://xiangke.pages.dev/`             |

### Branch Strategy

| Branch                 | Deployment Target   | Trigger             |
| ---------------------- | ------------------- | ------------------- |
| `feature/*`            | None (local only)   | Developer push      |
| `feature/construction` | None (current work) | Development branch  |
| `main`                 | Production          | Merge via PR        |
| `release/*`            | Preview             | Release preparation |

---

## Build Pipeline

### Local Development Build

```
Developer Workflow:
  1. Open project in Godot 4.x editor
  2. Edit .tres files, .gd scripts
  3. Press F5 (Play) for instant testing
  4. Project → Export → HTML5 for local web testing
  5. Commit and push to feature/construction
```

### CI/CD Pipeline (GitHub Actions)

```
Trigger: push to main branch OR pull request

Pipeline Stages:
  ┌─────────────────────────────────────────────────────────────┐
  │ Stage 1: Checkout                                           │
  │   - actions/checkout@v4                                     │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ Stage 2: Setup Godot (Docker)                               │
  │   - Image: barichello/godot-ci:4.x                          │
  │   - Includes: Godot engine, export templates                │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ Stage 3: Export HTML5                                       │
  │   - Command: godot --export-release "HTML5" build/web/      │
  │   - Output: index.html, index.wasm, index.pck, index.js     │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ Stage 4: Deploy to Cloudflare Pages                         │
  │   - Action: cloudflare/pages-action@v1                       │
  │   - Production: main branch → xiangke.pages.dev             │
  │   - Preview: PR → xiangke.pages.dev/pr-{number}             │
  └─────────────────────────────────────────────────────────────┘
```

### Desktop Build Pipeline (Manual Release)

```
Trigger: GitHub Release creation

Pipeline Stages:
  1. Export Windows (release): godot --export-release "Windows" build/xiangke-windows.zip
  2. Export macOS (release): godot --export-release "macOS" build/xiangke-macos.zip
  3. Export Linux (release): godot --export-release "Linux" build/xiangke-linux.zip
  4. Attach to GitHub Release as assets
```

---

## Release Process

### Versioning Scheme

- **Format**: Semantic Versioning (`MAJOR.MINOR.PATCH`)
- **Example**: `v1.0.0`, `v1.1.0`, `v2.0.0`
- **Pre-release**: `v1.0.0-alpha`, `v1.0.0-beta`

### Release Checklist

| Step | Description                        | Required |
| ---- | ---------------------------------- | -------- |
| 1    | Update version in `project.godot`  | Yes      |
| 2    | Run full test suite                | Yes      |
| 3    | Export HTML5 build                 | Yes      |
| 4    | Test Web build locally             | Yes      |
| 5    | Create GitHub Release              | Yes      |
| 6    | Upload desktop builds              | Optional |
| 7    | Verify Cloudflare Pages deployment | Yes      |

---

## Runtime Architecture

### Client-Side Component Flow

```
Browser (Chrome/Firefox/Safari/Edge)
    ↓
Cloudflare Pages CDN
    ↓
index.html + index.wasm + index.pck + index.js
    ↓
Godot Engine (WebAssembly)
    ↓
Autoloads (initialized on startup)
├── GameManager (state machine)
├── SaveManager (local save)
├── AudioManager (audio playback)
└── UIFocusManager (keyboard navigation)
    ↓
Scene System
├── Title Screen
├── Character Select
├── Battle Scene (Unit 3)
└── Result Screen
```

### State Machine Runtime Flow

```
1. Game Start
   → GameManager initializes to GameState.TITLE
   → StartScreen loads (Click to Start for Web)

2. User Interaction
   → AudioManager.initialize_audio() (Web only)
   → SaveManager.load_save()
   → GameManager.transition_to_state(GameState.CHARACTER_SELECT)

3. Character Selection
   → UIFocusManager handles keyboard navigation
   → CorpsRoster tracks 6→3 character selection
   → SceneTransition handles scene changes

4. Battle
   → GameState.BATTLE (managed by BattleManager, Unit 3)

5. Result
   → GameState.RESULT
   → SaveManager.save_game() with battle results

6. Return to Title
   → GameManager.transition_to_state(GameState.TITLE)
```

---

## Cache-Busting Strategy

### File Versioning

| File Type    | Cache-Busting Method                  |
| ------------ | ------------------------------------- |
| `index.html` | Filename versioning via release tag   |
| `index.wasm` | Filename versioning via release tag   |
| `index.pck`  | Filename versioning via release tag   |
| `index.js`   | Filename versioning via release tag   |
| Audio files  | Bundled in .pck (no separate caching) |

### Cloudflare Pages Configuration

```toml
# wrangler.toml or _headers
[site]
bucket = "./build/web"

[[headers]]
for = "/index.wasm"
[headers.values]
Cache-Control = "public, max-age=31536000"

[[headers]]
for = "/index.pck"
[headers.values]
Cache-Control = "public, max-age=31536000"
```

---

## Error Handling at Runtime

### Error Categories

| Category                     | Handling                    | Logging                    |
| ---------------------------- | --------------------------- | -------------------------- |
| Save corruption              | Reset to defaults + warning | Console warning            |
| Invalid state transition     | Ignore + log                | Console error (debug only) |
| Scene load failure           | Stay on current scene       | Console error              |
| Audio initialization failure | Silent fail (Web policy)    | Console warning            |

### Error Recovery Flow

```
Error Occurs
    ↓
Is it recoverable?
    ├── Yes → Use fallback/default
    │         → Log warning
    │         → Continue execution
    └── No → Log error
            → Show user message (if critical)
            → Potentially halt execution
```
