# Infrastructure Design — Unit 1: Resources (Shared Data)

## Overview

This document maps the logical components from NFR Design to concrete
infrastructure choices for the game's data layer. Since Unit 1 is a client-side
data layer with no server-side processing, the infrastructure focuses on build
pipeline, deployment, and runtime delivery.

---

## Infrastructure Mapping

### Logical Component → Infrastructure Mapping

| Logical Component        | Infrastructure Choice                   | Rationale                                             |
| ------------------------ | --------------------------------------- | ----------------------------------------------------- |
| Data Registry (Autoload) | In-memory Dictionary (client-side)      | No external storage needed; data preloaded at startup |
| DataLoader               | Godot ResourceLoader (built-in)         | Native `.tres` file loading; no custom infrastructure |
| DataValidator            | GDScript static functions (client-side) | Runs at load time within the game client              |
| DataValidationUtils      | GDScript static utility class           | Pure logic; no infrastructure dependency              |
| Resource Files (.tres)   | Bundled in game build                   | All data compiled into the export                     |
| Type Chart               | GDScript script constant                | Embedded in code; no external storage                 |

---

## Deployment Environment

### Primary: Web (HTML5/WebAssembly)

| Aspect               | Decision                                                 | Details                                                        |
| -------------------- | -------------------------------------------------------- | -------------------------------------------------------------- |
| **Hosting Platform** | GitHub Pages                                             | Free, GitHub-integrated, optimal for static HTML5 game hosting |
| **CDN**              | Built-in (GitHub Pages CDN)                              | Global edge caching provided by default                        |
| **Custom Domain**    | Optional (configurable)                                  | Supports custom domain with SSL via Let's Encrypt              |
| **Storage**          | Git repository (source) + GitHub Pages (build artifacts) | Source in repo; exported build deployed to `gh-pages` branch   |

### Secondary: Desktop (Development & Testing)

| Aspect               | Decision                      | Details                                   |
| -------------------- | ----------------------------- | ----------------------------------------- |
| **Distribution**     | Local builds via Godot editor | Manual export for Windows, macOS, Linux   |
| **CI/CD**            | GitHub Actions                | Automated export on push to main branch   |
| **Artifact Storage** | GitHub Releases               | Desktop builds attached as release assets |

---

## Build Infrastructure

### CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/export.yml (planned structure)
name: Export and Deploy
on:
  push:
    branches: [main]

jobs:
  export-web:
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.x
    steps:
      - uses: actions/checkout@v4
      - name: Export HTML5
        run: godot --export-release "HTML5" build/web/index.html
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

### Build Environments

| Environment     | Tool                           | Purpose                                      |
| --------------- | ------------------------------ | -------------------------------------------- |
| **Development** | Local Godot 4.x editor         | Manual export for rapid iteration            |
| **CI/CD**       | Docker (`barichello/godot-ci`) | Reproducible export environment for releases |
| **Testing**     | Local Godot + CI artifacts     | Validate exports before and after deployment |

---

## Storage Infrastructure

### Data Storage

| Data Type                  | Storage Method          | Location                               |
| -------------------------- | ----------------------- | -------------------------------------- |
| Character data (252 files) | `.tres` resource files  | `res://resources/characters/{id}.tres` |
| Move data (200+ files)     | `.tres` resource files  | `res://resources/moves/{id}.tres`      |
| Type chart                 | GDScript constant       | `scripts/type_chart.gd`                |
| Status effects             | GDScript enum/constants | Embedded in code                       |

### Build Output

| Artifact          | Format                          | Size Estimate                      |
| ----------------- | ------------------------------- | ---------------------------------- |
| HTML5/WebAssembly | `.html`, `.wasm`, `.pck`, `.js` | ~5-10 MB (including Godot runtime) |
| Desktop (Windows) | `.exe` + `.pck`                 | ~20-30 MB                          |
| Desktop (macOS)   | `.app` bundle                   | ~20-30 MB                          |
| Desktop (Linux)   | `.x86_64` + `.pck`              | ~20-30 MB                          |

---

## Networking Infrastructure

### Static File Delivery

Since the game is fully client-side with no server API (for Unit 1), networking
is limited to static file delivery:

| Component     | Infrastructure          | Details                                              |
| ------------- | ----------------------- | ---------------------------------------------------- |
| Game files    | GitHub Pages            | Static HTML/JS/WASM delivery                         |
| Assets        | Bundled in `.pck`       | All textures, audio, data packed into Godot PCK file |
| Cache control | Versioned query strings | `index.html?v=1.0.1` for cache busting               |

### Future Considerations (Not in Unit 1 Scope)

- Leaderboard API (future Database Unit)
- Multiplayer networking (future unit)
- User account system (future unit)

---

## Monitoring Infrastructure

### Error Tracking

| Layer                 | Method                            | Details                                                |
| --------------------- | --------------------------------- | ------------------------------------------------------ |
| **GDScript errors**   | `push_error()` / `push_warning()` | Logged to Godot output console                         |
| **JavaScript bridge** | `window.onerror` capture          | Catches GDScript errors exported to JS in HTML5 builds |
| **Log storage**       | Local file (client-side)          | Errors saved to local log file for developer review    |

### Performance Monitoring

| Metric       | Tool                    | Environment        |
| ------------ | ----------------------- | ------------------ |
| FPS          | Godot built-in profiler | Local development  |
| Load time    | Browser DevTools        | Web export testing |
| Memory usage | Godot monitor           | Local development  |

---

## Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        DEVELOPMENT                               │
│                                                                  │
│  ┌──────────────────┐    ┌──────────────────────────────────┐   │
│  │  Local Godot 4.x │    │  Git Repository (source code)    │   │
│  │  - Edit .tres    │───▶│  - .gd scripts                   │   │
│  │  - Local export  │    │  - .tres resource files          │   │
│  │  - Test & debug  │    │  - project.godot                 │   │
│  └──────────────────┘    └──────────────┬───────────────────┘   │
│                                         │                        │
└─────────────────────────────────────────┼────────────────────────┘
                                          │ push to main
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                        CI/CD (GitHub Actions)                    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Docker: barichello/godot-ci:4.x                         │   │
│  │  1. Export HTML5 → build/web/                            │   │
│  │  2. Export Desktop → build/desktop/                      │   │
│  │  3. Deploy web to GitHub Pages                           │   │
│  │  4. Attach desktop builds to GitHub Release              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DEPLOYMENT                                │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  GitHub Pages (gh-pages branch)                          │   │
│  │  - index.html?v=1.0.1                                    │   │
│  │  - index.wasm                                            │   │
│  │  - index.pck  (contains all .tres data)                  │   │
│  │  - index.js                                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  GitHub Releases                                          │   │
│  │  - xiangke-windows-v1.0.1.zip                            │   │
│  │  - xiangke-macos-v1.0.1.zip                              │   │
│  │  - xiangke-linux-v1.0.1.zip                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        RUNTIME (Client)                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Web Browser (HTML5/WebAssembly)                          │   │
│  │  1. Download all files from GitHub Pages CDN              │   │
│  │  2. Initialize Godot engine (WASM)                        │   │
│  │  3. Load .pck (contains all .tres data)                   │   │
│  │  4. DataRegistry: preload all character/move data         │   │
│  │  5. DataValidator: validate all data                      │   │
│  │  6. Game ready                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Error Monitoring                                         │   │
│  │  - window.onerror captures JS-bridge errors               │   │
│  │  - push_error() logs to local file                        │   │
│  │  - No server-side analytics (Unit 1 scope)                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Infrastructure Decisions Summary

| Decision           | Choice                  | Rationale                                                   |
| ------------------ | ----------------------- | ----------------------------------------------------------- |
| **Hosting**        | GitHub Pages            | Free, GitHub-integrated, static hosting optimized for HTML5 |
| **CI/CD**          | GitHub Actions          | Native GitHub integration, Godot Docker support             |
| **Container**      | `barichello/godot-ci`   | Standard Godot CI image, reproducible exports               |
| **Asset Delivery** | Full bundle in PCK      | <200KB data + assets; preload at startup per NFR Design     |
| **Cache Strategy** | Versioned query strings | Prevents stale cache on web updates                         |
| **Monitoring**     | Basic error logging     | Client-side only; no server analytics needed for Unit 1     |
| **Development**    | Local Godot editor      | GUI-based editing; Docker only for CI                       |

---

## Future Infrastructure (Out of Scope for Unit 1)

These infrastructure components will be addressed in future units:

| Component          | Trigger         | Infrastructure Needed                           |
| ------------------ | --------------- | ----------------------------------------------- |
| Leaderboard system | Database Unit   | Server API, database (PostgreSQL/Firestore)     |
| User accounts      | Auth Unit       | Authentication service (OAuth, JWT)             |
| Multiplayer        | Network Unit    | WebSocket server, matchmaking service           |
| DLC content        | Expansion       | CDN for downloadable content packs              |
| Analytics          | Post-deployment | Analytics platform (self-hosted or third-party) |
