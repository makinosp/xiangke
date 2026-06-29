# Deployment Architecture — Unit 1: Resources (Shared Data)

## Overview

This document describes the deployment pipeline, release process, and runtime
architecture for the game's web and desktop builds.

---

## Deployment Environments

### Environment Overview

| Environment     | Platform                   | Purpose                     | URL/Access                                |
| --------------- | -------------------------- | --------------------------- | ----------------------------------------- |
| **Development** | Local Godot editor         | Active development, testing | `localhost` (Godot play)                  |
| **Staging**     | GitHub Pages (dev branch)  | Pre-release validation      | `https://makinosp.github.io/xiangke/dev/` |
| **Production**  | GitHub Pages (main branch) | Public game access          | `https://makinosp.github.io/xiangke/`     |

### Branch Strategy

| Branch                 | Deployment Target          | Trigger             |
| ---------------------- | -------------------------- | ------------------- |
| `feature/*`            | None (local only)          | Developer push      |
| `feature/construction` | None (current work)        | Development branch  |
| `main`                 | Production (GitHub Pages)  | Merge via PR        |
| `release/*`            | Staging (GitHub Pages dev) | Release preparation |

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
Trigger: push to main branch

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
  │ Stage 4: Deploy to GitHub Pages                             │
  │   - Action: peaceiris/actions-gh-pages@v3                   │
  │   - Target: gh-pages branch                                 │
  │   - Source: ./build/web                                     │
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

| Step | Action                            | Verification                 |
| ---- | --------------------------------- | ---------------------------- |
| 1    | Merge feature branch → main       | PR approved, CI passes       |
| 2    | CI auto-deploys to GitHub Pages   | Verify at production URL     |
| 3    | Create Git tag `vX.Y.Z`           | Tag matches deployed version |
| 4    | Create GitHub Release             | Desktop builds attached      |
| 5    | Update version in `project.godot` | Version string matches tag   |

### Cache Busting

To ensure players receive the latest version after an update:

```
URL Pattern: https://makinosp.github.io/xiangke/index.html?v=1.0.1

Implementation:
  - Query parameter ?v=X.Y.Z forces browser to fetch fresh copy
  - GitHub Pages CDN caches based on full URL (including query)
  - No service worker needed for Unit 1 scope
```

---

## Runtime Architecture

### Web (HTML5/WebAssembly) Runtime

```
┌─────────────────────────────────────────────────────────────┐
│                     Web Browser                              │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  GitHub Pages CDN                                    │    │
│  │  ├── index.html  (entry point)                       │    │
│  │  ├── index.wasm  (Godot engine binary)               │    │
│  │  ├── index.pck   (game data + assets)                │    │
│  │  └── index.js    (loader/bridge)                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Godot Engine (WASM)                                 │    │
│  │  1. Initialize engine                                │    │
│  │  2. Load .pck file                                   │    │
│  │  3. Parse all .tres resources                        │    │
│  │  4. Populate DataRegistry (Autoload)                 │    │
│  │  5. Run DataValidator.validate_all()                 │    │
│  │  6. Emit warnings for invalid data                   │    │
│  │  7. Game ready for play                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Game Runtime (client-side only)                     │    │
│  │  - DataRegistry: in-memory character/move data       │    │
│  │  - Battle System: future unit                        │    │
│  │  - UI/HUD: future unit                               │    │
│  │  - No server communication (Unit 1 scope)            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Desktop Runtime

```
┌─────────────────────────────────────────────────────────────┐
│                   Desktop Application                        │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Executable + PCK                                    │    │
│  │  ├── xiangke.exe (or .app, .x86_64)                 │    │
│  │  └── xiangke.pck (game data + assets)               │    │
│  └─────────────────────────────────────────────────────┘    │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Godot Engine (native)                               │    │
│  │  Same initialization flow as Web                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow at Runtime

### Startup Sequence

```
1. Engine Initialization
   └── Godot starts (WASM or native)

2. PCK Loading
   └── Load xiangke.pck from disk/network

3. Resource Discovery
   └── DataLoader.discover_characters()
       └── Scan res://resources/characters/*.tres
   └── DataLoader.discover_moves()
       └── Scan res://resources/moves/*.tres

4. Data Loading
   └── DataLoader.load_all()
       └── Preload all .tres files into memory
       └── Populate DataRegistry.characters Dictionary
       └── Populate DataRegistry.moves Dictionary

5. Validation
   └── DataValidator.validate_all()
       └── Check all business rules (CR-1 through CR-4, MR-1 through MR-4, etc.)
       └── Collect errors and warnings
       └── Log summary to output

6. Game Ready
   └── All data available in memory
   └── Battle System, UI/HUD can access DataRegistry
```

---

## Monitoring and Observability

### Error Capture

| Source              | Method                         | Output                                      |
| ------------------- | ------------------------------ | ------------------------------------------- |
| GDScript errors     | `push_error("message")`        | Godot Output panel (dev) / JS console (web) |
| JavaScript bridge   | `window.onerror`               | Browser console + local log file            |
| Validation warnings | `DataValidator.validate_all()` | Logged summary at startup                   |

### Log Storage

- **Development**: Godot Output panel (real-time)
- **Web**: Browser console + downloadable log file
- **Desktop**: `user://logs/game.log` (Godot user data directory)

### Future Monitoring (Out of Scope)

- Server-side error aggregation (requires backend infrastructure)
- Player analytics (requires analytics platform)
- Performance telemetry (requires monitoring service)

---

## Security Considerations

### Current Scope (Unit 1)

| Concern          | Status         | Notes                                                                 |
| ---------------- | -------------- | --------------------------------------------------------------------- |
| Client-side only | ✅ Secure      | No server to attack                                                   |
| No user data     | ✅ Secure      | No PII, no accounts                                                   |
| Data integrity   | ⚠️ Client-side | `.tres` files can be modified by users (acceptable for single-player) |
| Code obfuscation | ❌ Not applied | GDScript compiled to bytecode; acceptable for v1                      |

### Future Security Needs

- Anti-cheat (when multiplayer is added)
- Server-side validation (when leaderboard is added)
- Authentication (when user accounts are added)

---

## Cost Estimation

| Service             | Cost         | Notes                           |
| ------------------- | ------------ | ------------------------------- |
| GitHub (repository) | Free         | Public repository               |
| GitHub Pages        | Free         | Static hosting, 1GB limit       |
| GitHub Actions      | Free         | 2,000 minutes/month (free tier) |
| Docker Hub          | Free         | `barichello/godot-ci` is public |
| **Total**           | **$0/month** | Fully within free tiers         |

---

## Scalability Considerations

### Current Capacity

| Metric                 | Limit        | Headroom                                |
| ---------------------- | ------------ | --------------------------------------- |
| GitHub Pages bandwidth | 100 GB/month | Sufficient for ~10,000 game loads/month |
| GitHub Pages storage   | 1 GB         | Current build ~10 MB                    |
| GitHub Actions minutes | 2,000/month  | ~66 builds/month at 30 min/build        |

### Scaling Triggers

| Trigger                        | Action                                       |
| ------------------------------ | -------------------------------------------- |
| Bandwidth exceeds 100 GB/month | Migrate to Cloudflare Pages or S3+CloudFront |
| Build minutes exceeded         | Self-hosted runner or optimize build time    |
| Need server-side features      | Add cloud infrastructure (future unit)       |
