# Migration Requirements — Clarifying Questions

Please answer the following questions to clarify the GDScript → Rust migration
requirements.

## Question 1

What is the primary motivation for migrating from GDScript to Rust?

A) Performance — Rust's zero-cost abstractions and native compilation will
significantly improve battle calculation speed and frame rate

B) Type safety — Rust's strong static type system eliminates entire classes of
runtime errors compared to GDScript's dynamic typing

C) Ecosystem — Rust's package ecosystem (crates.io) and tooling (Cargo, rustfmt,
clippy) provide better development experience

D) Platform expansion — Rust enables targeting additional platforms (native
desktop, WASM, mobile) more efficiently

E) Learning/exploration — Want to explore Rust for game development as a
learning opportunity

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 2

What is the target engine/framework for the Rust version?

A) Bevy — Modern ECS-based game engine written in Rust, active community, WASM
support

B) Fyrox — Feature-rich Rust game engine with editor, similar to Godot in
concept

C) ggez — Lightweight 2D game framework for Rust

D) Macroquad — Minimal, cross-platform 2D game library for Rust

E) Custom engine — Build a custom game loop using raw wgpu/winit/glutin

F) Godot Rust bindings — Keep using Godot Engine but write game logic in Rust
via godot-rust (gdext)

X) Other (please describe after [Answer]: tag below)

[Answer]: F

## Question 3

What is the migration strategy?

A) Full rewrite — Discard all GDScript code and rebuild from scratch in Rust
(preserving design/architecture)

B) Incremental — Keep Godot/GDScript for scenes/UI, rewrite only battle system
logic in Rust (via godot-rust/gdext)

C) Hybrid — Use Rust for core systems (battle, data, AI) and keep GDScript for
UI/scenes, then gradually migrate

D) Phased — Start with a minimal Rust prototype, then add features incrementally

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 4

What is the target platform priority?

A) Web (WASM) — Same as current Godot target, Rust compiles to WASM via
wasm-pack

B) Desktop (Windows/macOS/Linux) — Native performance, easier debugging

C) Both Web and Desktop equally

D) Mobile (iOS/Android) — Rust has good mobile support

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5

What is the expected timeline for this migration?

A) ASAP — Complete migration in one continuous development session

B) Short-term — Complete within a few days/weeks

C) Medium-term — Phased migration over weeks/months

D) Long-term — Ongoing, no fixed deadline

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 6

What is the scope of the initial Rust implementation?

A) Full game — Complete migration of all 26 GDScript files, 5 scenes, and 11
resources

B) Battle system only — Migrate only `systems/battle/` (5 files) and core data
types first

C) Core logic — Migrate battle system + data layer + game state machine, keep
UI/scenes in Godot

D) Minimal prototype — Create a working battle simulation in Rust CLI (no
graphics) to validate the approach

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 7

Should the security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for
production-grade applications)

B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental
projects)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 8

Should the resiliency baseline be applied to this project?

A) Yes — apply the resiliency baseline as directional best practices and
design-time guidance (recommended for business-critical workloads)

B) No — skip the resiliency baseline (suitable for PoCs, prototypes, and
experimental projects)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 9

Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects
with business logic, data transformations, serialization, or stateful
components)

B) Partial — enforce PBT rules only for pure functions and serialization
round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only
projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: C
