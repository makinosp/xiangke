# Requirements Document — GDScript to Rust Migration

## Intent Analysis Summary

| Field                   | Value                                                                           |
| ----------------------- | ------------------------------------------------------------------------------- |
| **User Request**        | Migrate existing Godot Engine 4.x / GDScript turn-based battle game to Rust     |
| **Request Type**        | Migration (Technology Stack)                                                    |
| **Scope Estimate**      | System-wide (26 GDScript files, 5 scenes, 11 resources → incremental migration) |
| **Complexity Estimate** | Complex                                                                         |

---

## Migration Strategy

### MS-1: Incremental Migration via Godot Rust Bindings

- **MS-1.1**: The project shall use **godot-rust (gdext)** to write game logic
  in Rust while continuing to use Godot Engine 4.x as the game engine.
- **MS-1.2**: The existing GDScript codebase shall remain functional during the
  migration; no full rewrite.
- **MS-1.3**: Migration shall proceed incrementally, starting with the battle
  system (`systems/battle/`) and core data types.
- **MS-1.4**: Scene files (`.tscn`), UI logic, resources (`.tres`), and audio
  shall remain in GDScript/Godot format.
- **MS-1.5**: The Rust GDExtension binary shall be built alongside the existing
  Godot project.

### MS-2: Migration Phasing

- **MS-2.1**: **Phase 1 — Toolchain Setup**: Install Rust toolchain, configure
  gdext, create minimal GDExtension skeleton that loads in Godot.
- **MS-2.2**: **Phase 2 — Core Data Types**: Migrate `type_enums.gd` (7-type
  enum), `type_chart.gd` (7×7 effectiveness table), `character_data.gd`,
  `move_data.gd`, `status_effect_data.gd` to Rust structs/enums.
- **MS-2.3**: **Phase 3 — Battle System**: Migrate `battle_participant.gd`,
  `battle_state.gd`, `action_system.gd`, `battle_manager.gd`,
  `battle_flow_service.gd` to Rust.
- **MS-2.4**: **Phase 4 — Integration**: Wire Rust battle system into the
  existing Godot scenes, replacing GDScript battle logic.
- **MS-2.5**: **Phase 5 — Cleanup**: Remove migrated GDScript files, optimize
  Rust bindings, final testing on Web (WASM) target.

---

## Functional Requirements

### FR-1: Game Core (Carried Forward)

- **FR-1.1**: The game shall remain a 2D turn-based battle game built with
  **Godot Engine 4.x**.
- **FR-1.2**: The primary scripting language for game logic shall transition
  from GDScript to **Rust** via gdext.
- **FR-1.3**: The game shall export to Web (HTML5/WebAssembly) as the primary
  target platform.
- **FR-1.4**: The game shall support desktop platforms (Windows, macOS, Linux)
  for development and testing.
- **FR-1.5**: Scene files (`.tscn`) shall remain in Godot's native format; UI
  and scene logic may stay in GDScript or be migrated later.

### FR-2: AI / NPC Behavior (Carried Forward)

- **FR-2.1**: The game shall include AI-controlled NPCs with defined behavior
  patterns.
- **FR-2.2**: NPC AI logic shall be migrated to Rust alongside the battle
  system.
- **FR-2.3**: AI behaviors shall use Rust's type system for pattern matching and
  state management.

### FR-3: UI / HUD (Carried Forward, Unchanged)

- **FR-3.1**: The game shall include a user interface with HUD elements (HP
  bars, status, action menu).
- **FR-3.2**: UI/HUD shall remain in GDScript and Godot scenes (`.tscn`).
- **FR-3.3**: Menu systems (Title, Character Select, Result) shall remain in
  GDScript.
- **FR-3.4**: The Rust battle system shall expose signals/methods that the
  GDScript UI can call.

### FR-4: Audio / Music System (Carried Forward, Unchanged)

- **FR-4.1**: Audio (BGM, SFX) shall remain managed by GDScript `AudioManager`.
- **FR-4.2**: Audio playback shall remain compatible with Web platform browser
  autoplay policies.

### FR-5: Local Storage (Carried Forward, Unchanged)

- **FR-5.1**: Save/load functionality shall remain in GDScript (`SaveManager`).
- **FR-5.2**: No external database server is required.

---

## Non-Functional Requirements

### NFR-1: Performance (Revised for Rust)

- **NFR-1.1**: Battle system logic in Rust shall complete turn processing in
  **<10ms** (was <100ms in GDScript).
- **NFR-1.2**: Damage calculation shall complete in **<1ms** (was <10ms target).
- **NFR-1.3**: The game shall maintain ≥30 FPS on Web (WASM) export and ≥60 FPS
  on Desktop.
- **NFR-1.4**: The Rust GDExtension binary size shall be optimized for Web
  delivery (<5MB additional).

### NFR-2: Compatibility (Revised for Rust)

- **NFR-2.1**: The Rust GDExtension shall compile and target **WASM32** via
  `wasm-pack` / `cargo build --target wasm32-unknown-emscripten`.
- **NFR-2.2**: The Web export shall function correctly in modern browsers
  (Chrome, Firefox, Safari, Edge).
- **NFR-2.3**: Input shall remain handled via keyboard and mouse.

### NFR-3: Maintainability (Revised for Rust)

- **NFR-3.1**: Rust code shall follow idiomatic Rust conventions (clippy,
  rustfmt).
- **NFR-3.2**: Rust code shall be organized in a Cargo workspace under `rust/`
  directory.
- **NFR-3.3**: Rust code shall have comprehensive unit tests via `#[cfg(test)]`.
- **NFR-3.4**: GDScript code that interfaces with Rust shall have minimal, thin
  wrapper layer.
- **NFR-3.5**: All documentation, comments, and docstrings shall be written in
  English.

### NFR-4: Security (Carried Forward)

- **NFR-4.1**: Local player data shall be stored in Godot's user data directory
  (sandboxed by the browser).
- **NFR-4.2**: No sensitive data is transmitted to external servers.

---

## Constraints

| ID    | Constraint                                                              | Source                        |
| ----- | ----------------------------------------------------------------------- | ----------------------------- |
| CON-1 | The project must use Godot Engine 4.x (latest stable)                   | Original                      |
| CON-2 | Game logic shall be written in Rust via **godot-rust (gdext)**          | Migration Decision            |
| CON-3 | The primary export target is Web (HTML5/WASM)                           | Original + Migration Decision |
| CON-4 | This is an internal tool (not a commercial product)                     | Original                      |
| CON-5 | Scene/UI layer shall remain in GDScript during initial migration        | Migration Decision            |
| CON-6 | Rust code shall be in a `rust/` subdirectory                            | Convention                    |
| CON-7 | All documentation, comments, and docstrings shall be written in English | Project Rule                  |

---

## Assumptions

- **ASM-1**: Godot Rust bindings (gdext) support Godot 4.x and WASM target.
- **ASM-2**: The existing GDScript battle system can coexist with the Rust
  version during migration.
- **ASM-3**: Web export with GDExtension is feasible with emscripten WASM
  target.
- **ASM-4**: The migration does not change game mechanics or balance; logic
  parity is the goal.

---

## Out of Scope (for initial migration)

- **OOS-1**: AI System as a standalone module (Unit 4) — deferred.
- **OOS-2**: UI/HUD enhancements (Unit 5) — deferred.
- **OOS-3**: Audio asset production (Unit 6) — deferred.
- **OOS-4**: Mobile platform support.
- **OOS-5**: Full rewrite of all GDScript to Rust.
