# System Specification

## Purpose

Define the overall architecture, components, services, tech stack, and
deployment strategy for the turn-based command battle game.

## Requirements

### Requirement: Game Engine

The system SHALL use Godot Engine 4.x as the game engine.

#### Scenario: Engine initialization

- **WHEN** the application starts
- **THEN** Godot Engine 4.x loads the project configuration
- **AND** all autoloads are registered

### Requirement: Core Logic Language

The system SHALL implement core battle logic in Rust via GDExtension.

#### Scenario: Rust crate compilation

- **WHEN** `cargo build --workspace` is run
- **THEN** three crates compile: `xiangke-core`, `xiangke-battle`,
  `xiangke-godot-bridge`
- **AND** a `.dylib`/`.so`/`.dll` bridge library is produced

### Requirement: Scripting Language

The system SHALL use GDScript for scene logic, UI, and game flow orchestration.

#### Scenario: Scene script loading

- **WHEN** a scene is loaded in Godot
- **THEN** its attached GDScript runs without errors
- **AND** the script can call Rust bridge methods via GDExtension

### Requirement: Export Target

The system SHALL export to Web (HTML5/WebAssembly) as the primary platform.

#### Scenario: Web export

- **WHEN** the project is exported to HTML5
- **THEN** the output includes `.wasm`, `.pck`, `.html`, and `.js` files
- **AND** the game runs in a browser at ≥30 FPS

### Requirement: Desktop Support

The system SHALL support desktop platforms (macOS, Windows, Linux) for
development and testing.

#### Scenario: Desktop development

- **WHEN** the project is opened in Godot editor on macOS/Windows/Linux
- **THEN** the game runs with F5 (Play) without errors

### Requirement: Autoload Singletons

The system SHALL provide autoload singletons for global state management.

#### Scenario: Autoload registration

- **WHEN** the project loads
- **THEN** GameManager, AudioController, SaveManager, DataRegistry, and
  UIFocusManager are available as global singletons

### Requirement: Scene Flow

The system SHALL support a hub-and-spoke scene flow centered on the title
screen: Title → CorpsSettings, Title → CharacterSelect → Battle → Result, and
Title → Settings. All sub-screens return to Title via a back button.

#### Scenario: Scene transition from title

- **WHEN** GameManager changes the game state from Title
- **THEN** the corresponding scene is loaded with a transition animation
- **AND** relevant data is passed between scenes

#### Scenario: Return to title from sub-screen

- **WHEN** GameManager transitions back to the Title state from any sub-screen
- **THEN** the title screen is loaded
- **AND** the title screen reflects current save state (e.g., Start button
  enabled/disabled)

### Requirement: Tech Stack

The system SHALL use the defined tech stack: Godot 4.x, GDScript, Rust, `.tres`
data files, ConfigFile persistence, GitHub Actions CI, GitHub Pages deployment.

#### Scenario: CI pipeline

- **WHEN** code is pushed to the main branch
- **THEN** GitHub Actions runs `cargo fmt --check`, `cargo clippy`,
  `cargo build`, and `cargo test`
- **AND** the Web export is deployed to GitHub Pages

### Requirement: Unit Dependency Order

The system SHALL respect the unit dependency graph: Unit 1 (Resources) → Unit 2
(Foundation) → Unit 3 (Battle) → Unit 4 (AI) / Unit 5 (UI) / Unit 6 (Audio).

#### Scenario: Development order

- **WHEN** implementing a new feature
- **THEN** its dependent units must be implemented first
- **AND** shared data from Unit 1 is available to all downstream units
