# Infrastructure Design Plan — Unit 1: Resources (Shared Data)

## Objective

Map the logical components from NFR Design (DataRegistry, DataLoader,
DataValidator, Resource Files) to actual infrastructure choices for build,
deployment, and runtime environments.

## Context Summary

- **Project Type**: Godot 4.x 2D game (Three Kingdoms themed)
- **Primary Export**: Web (HTML5/WebAssembly)
- **Secondary Export**: Desktop (Windows, macOS, Linux)
- **Data Layer**: `.tres` resource files (252 characters, 200+ moves, type
  chart)
- **Data Size**: <200KB total, preloaded at startup
- **Target Audience**: Web browser users (primary), desktop testers (secondary)

---

## Plan Steps

- [x] **Step 1**: Analyze design artifacts (functional design, NFR design, tech
      stack)
- [x] **Step 2**: Identify infrastructure categories applicable to this project
- [x] **Step 3**: Generate context-appropriate questions for infrastructure
      decisions
- [x] **Step 4**: Collect and analyze user answers
- [x] **Step 5**: Generate infrastructure-design.md (infrastructure mapping)
- [x] **Step 6**: Generate deployment-architecture.md (deployment pipeline and
      hosting)
- [x] **Step 7**: Present completion message and await approval

---

## Infrastructure Categories Assessment

### Applicable Categories

| Category                  | Applicable | Rationale                                                                |
| ------------------------- | ---------- | ------------------------------------------------------------------------ |
| Deployment Environment    | ✅ Yes     | Web export requires hosting; need to choose platform                     |
| Compute Infrastructure    | ⚠️ Limited | Game is client-side; server only needed if leaderboard/multiplayer added |
| Storage Infrastructure    | ⚠️ Limited | `.tres` files bundled in build; no external database for Unit 1          |
| Messaging Infrastructure  | ❌ No      | Single-player game; no async messaging needed                            |
| Networking Infrastructure | ⚠️ Limited | Static file delivery only (no API gateway needed for Unit 1)             |
| Monitoring Infrastructure | ✅ Yes     | Error logging, performance monitoring for web builds                     |
| Shared Infrastructure     | ❌ No      | Single-tenant game project                                               |

### Key Infrastructure Questions

#### Q1: Web Hosting Platform

The game exports to HTML5/WebAssembly and needs to be hosted for browser play.
Which hosting approach do you prefer?

- **A)** Static hosting service (GitHub Pages, Netlify, Vercel, Cloudflare
  Pages)
- **B)** Cloud object storage + CDN (AWS S3 + CloudFront, GCP Cloud Storage)
- **C)** Self-hosted / own server
- **D)** Godot export only (user handles hosting separately)

[Answer]: A

#### Q2: Build Automation

How should the Godot export process be automated?

- **A)** CI/CD pipeline (GitHub Actions, GitLab CI) — automated export on push
- **B)** Local export only — manual export by developer
- **C)** Both — CI for releases, local for development testing

[Answer]: C

#### Q3: Development Environment

What is the development environment setup?

- **A)** Local Godot editor only
- **B)** Local Godot + Docker container for consistent export environment
- **C)** Cloud-based development (GitHub Codespaces, etc.)

[Answer]: A

#### Q4: Asset Delivery

How should game assets (`.tres` files, textures, audio) be delivered to players?

- **A)** Bundled entirely in the initial download (all data loaded at startup)
- **B)** Bundled core + DLC/downloadable content packs for expansions
- **C)** Streaming/assets loaded on-demand during gameplay

[Answer]: A

#### Q5: Versioning and Updates

How should game updates be managed for web players?

- **A)** Cache-busting with versioned filenames (forces fresh download on
  update)
- **B)** Service worker with offline support and background updates
- **C)** Simple cache headers (browser default caching behavior)
- **D)** No special handling — players refresh to get latest

[Answer]: A

#### Q6: Monitoring and Error Tracking

What level of runtime monitoring do you want for the web build?

- **A)** No monitoring — rely on user reports
- **B)** Basic error logging (JavaScript error capture, send to simple endpoint)
- **C)** Full analytics (performance metrics, error tracking, player behavior)
- **D)** Godot-specific profiling only (local development profiling)

[Answer]: B

---

## Notes

- Unit 1 (Resources) is purely client-side data — no server infrastructure
  needed
- Future units (Database/Leaderboard, Multiplayer) will require additional
  infrastructure
- Current scope: build pipeline + static hosting + asset delivery strategy
