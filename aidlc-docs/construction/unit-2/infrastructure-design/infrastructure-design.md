# Infrastructure Design — Unit 2: Game Foundation

## Overview

This document maps the logical components from NFR Design to concrete
infrastructure choices for the game foundation layer. Since Unit 2 is a
client-side game with no server-side processing, the infrastructure focuses on
build pipeline, deployment, and runtime delivery.

---

## Infrastructure Mapping

### Logical Component → Infrastructure Mapping

| Logical Component         | Infrastructure Choice                 | Rationale                                         |
| ------------------------- | ------------------------------------- | ------------------------------------------------- |
| GameManager (Autoload)    | In-memory state machine (client-side) | No external storage needed; state managed locally |
| SaveManager (Autoload)    | ConfigFile API → user://save.cfg      | Local save file in sandboxed user data directory  |
| AudioManager (Autoload)   | AudioStreamPlayer nodes + OGG files   | Native Godot audio; bundled in game build         |
| SceneTransition (Node)    | AnimationPlayer + CanvasLayer overlay | Pure client-side visual transition effects        |
| UIFocusManager (Autoload) | Custom focus tracking + Control nodes | Client-side UI navigation; no external dependency |

---

## Deployment Environment

### Primary: Web (HTML5/WebAssembly)

| Aspect               | Decision                                                     | Details                                                      |
| -------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Hosting Platform** | Cloudflare Pages                                             | Fast global CDN, GitHub integration, automatic HTTPS         |
| **CDN**              | Built-in Cloudflare CDN                                      | Global edge caching with automatic optimization              |
| **Custom Domain**    | Optional (configurable)                                      | Supports custom domain with automatic SSL                    |
| **Storage**          | Git repository (source) + Cloudflare Pages (build artifacts) | Source in repo; exported build deployed via Cloudflare Pages |

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
# .github/workflows/export.yml
name: Export and Deploy
on:
  push:
    branches: [main]
  pull_request:
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
      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: xiangke
          directory: ./build/web
          previewBranch: true
```

### Build Environments

| Environment     | Tool                           | Purpose                                      |
| --------------- | ------------------------------ | -------------------------------------------- |
| **Development** | Local Godot 4.x editor         | Manual export for rapid iteration            |
| **CI/CD**       | Docker (`barichello/godot-ci`) | Reproducible export environment for releases |
| **Testing**     | Local Godot + CI artifacts     | Validate exports before and after deployment |

---

## Storage Infrastructure

### Save Data Storage

| Data Type       | Storage Method     | Location                       |
| --------------- | ------------------ | ------------------------------ |
| Game settings   | ConfigFile API     | `user://save.cfg` (sandboxed)  |
| Volume settings | ConfigFile section | `settings` section in save.cfg |
| Progress data   | ConfigFile section | `progress` section in save.cfg |
| Meta/version    | ConfigFile section | `meta` section in save.cfg     |

### Build Output

| Artifact          | Format                          | Size Estimate                      |
| ----------------- | ------------------------------- | ---------------------------------- |
| HTML5/WebAssembly | `.html`, `.wasm`, `.pck`, `.js` | ~5-15 MB (including Godot runtime) |

---

## Runtime Architecture

### Client-Side Architecture

```
Browser (Chrome/Firefox/Safari/Edge)
    ↓
Cloudflare Pages CDN
    ↓
index.html + index.wasm + index.pck + index.js
    ↓
Godot Engine (WebAssembly)
    ↓
├── GameManager (state machine)
├── SaveManager (local save)
├── AudioManager (audio playback)
├── SceneTransition (visual effects)
└── UIFocusManager (keyboard navigation)
```

### Web Audio API Initialization Flow

```
1. User opens game in browser
2. StartScreen shows "Click to Start"
3. User clicks button
4. AudioManager.initialize_audio() called
5. Silent audio plays to unlock Web Audio API
6. Audio playback enabled for session
```

---

## Monitoring and Error Reporting

### Error Logging

| Aspect               | Decision                             | Details                                                         |
| -------------------- | ------------------------------------ | --------------------------------------------------------------- |
| **Error Logging**    | Basic console logging only           | No external telemetry service; errors logged to browser console |
| **Error Format**     | Structured messages with context     | Include state, scene, and error type in log messages            |
| **Development Mode** | Enhanced logging with debug messages | Additional context in debug builds                              |

---

## Cost Estimation

| Resource              | Monthly Cost | Notes                                      |
| --------------------- | ------------ | ------------------------------------------ |
| Cloudflare Pages      | $0           | Free tier sufficient for game distribution |
| GitHub Actions        | $0           | Free for public repositories               |
| Domain (optional)     | $1-15        | Optional custom domain                     |
| **Total (estimated)** | **$0-15**    | Primarily for optional custom domain       |

---

## Traceability

| Infrastructure Item | Source Question | Decision                |
| ------------------- | --------------- | ----------------------- |
| Hosting Platform    | INF1            | D (Cloudflare Pages)    |
| Build Automation    | INF2            | C (CI/CD + PR preview)  |
| Development Env     | INF3            | A (Local Godot)         |
| Asset Delivery      | INF4            | A (Full bundle)         |
| Versioning          | INF5            | A (Cache-busting)       |
| Monitoring          | INF6            | B (Basic error logging) |
