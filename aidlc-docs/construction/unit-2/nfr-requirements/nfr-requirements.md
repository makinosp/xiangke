# NFR Requirements — Unit 2: Game Foundation

## Overview

Non-functional requirements for the game foundation layer. These requirements
govern application lifecycle, scene management, persistence, and audio playback
behavior.

---

## Performance Requirements

### PF-1: Scene Transitions

- **PF-1.1**: Scene transitions shall complete within 500ms for smooth UX
  expectation.
- **PF-1.2**: Transitions shall use configurable fade/animation effects via
  exported variables on the transition node.
- **PF-1.3**: Transition configuration shall support duration, fade color, and
  easing curve parameters.

### PF-2: Audio Latency

- **PF-2.1**: Audio playback latency (SFX trigger to audible) shall be less than
  50ms for responsive feedback.
- **PF-2.2**: BGM crossfade transitions shall complete within 1 second.
- **PF-2.3**: Dynamic audio layers shall be implemented via AudioStreamPlayer
  buses without performance impact.

---

## Reliability Requirements

### RE-1: Save Data Handling

- **RE-1.1**: Save file corruption or missing save data shall trigger a reset to
  defaults with a one-time warning message.
- **RE-1.2**: Save operations shall use Godot's ConfigFile API with atomic write
  patterns where possible.
- **RE-1.3**: Missing save keys shall be treated as their default values
  (graceful degradation).

### RE-2: State Machine Error Handling

- **RE-2.1**: Invalid state transition requests shall be logged and ignored in
  release builds.
- **RE-2.2**: Invalid state transition requests shall log errors and show debug
  messages in development builds.
- **RE-2.3**: The state machine shall never crash on invalid transition
  requests.

---

## Security Requirements

### SE-1: Save File Integrity

- **SE-1.1**: Save files shall include basic checksum validation to detect
  corruption.
- **SE-1.2**: Checksum validation shall be performed on load before applying
  save data.
- **SE-1.3**: Tampered save files shall be reset to defaults with appropriate
  logging.

---

## Maintainability Requirements

### MA-1: Scene Transition Configuration

- **MA-1.1**: Scene transition system shall be configurable via exported
  variables on the transition node.
- **MA-1.2**: Transition parameters shall include: duration, fade color, easing
  curve, and animation player reference.
- **MA-1.3**: No hardcoded transition values in scene transition code.

### MA-2: Audio System Documentation

- **MA-2.1**: Audio system shall include inline comments explaining bus
  configuration.
- **MA-2.2**: Audio track registry documentation shall be maintained in code.
- **MA-2.3**: Audio naming convention guide shall document BGM/SFX file
  organization.

---

## Usability Requirements

### US-1: Web Audio Initialization

- **US-1.1**: First launch on Web shall show a "Click to Start" screen that
  initializes audio on first click.
- **US-1.2**: Audio initialization shall unlock the Web Audio API for subsequent
  playback.
- **US-1.3**: The start screen shall not show on subsequent launches after
  successful initialization.

### US-2: Character Selection Navigation

- **US-2.1**: Character selection screen shall use custom focus management with
  visual highlighting.
- **US-2.2**: Keyboard navigation shall follow Godot's focus system with custom
  visual feedback.
- **US-2.3**: Focus shall wrap around screen edges for intuitive navigation.

---

## Compatibility Requirements

### CP-1: Screen Aspect Ratios

- **CP-1.1**: Game shall support responsive layout with flexible UI anchoring.
- **CP-1.2**: UI elements shall maintain proper positioning across 16:9, 16:10,
  and 4:3 aspect ratios.
- **CP-1.3**: Letterboxing/pillarboxing shall be used only as a last resort for
  extreme ratios.

---

## Tech Stack Requirements

### TS-1: Audio Format

- **TS-1.1**: BGM and SFX audio files shall use OGG Vorbis format.
- **TS-1.2**: OGG format provides best Web compatibility with small file sizes.
- **TS-1.3**: All audio assets shall be converted to OGG before import.

### TS-2: UI Theme System

- **TS-2.1**: Project shall use Godot's built-in theme system for UI.
- **TS-2.2**: Built-in theme shall be used with custom overrides for
  game-specific styling.
- **TS-2.3**: Theme customization shall be applied via Godot's theme editor.

---

## Traceability

| NFR ID | Source Question | Requirement Source                  |
| ------ | --------------- | ----------------------------------- |
| PF-1   | P1              | Scene transitions within 500ms      |
| PF-2   | P2              | Audio latency <50ms                 |
| RE-1   | REL1            | Reset to defaults with warning      |
| RE-2   | REL2            | Log error + debug message in dev    |
| SE-1   | SEC1            | Basic checksum validation           |
| MA-1   | MA1             | Configurable via exported variables |
| MA-2   | MA2             | Inline comments + registry docs     |
| US-1   | U1              | Click to Start screen               |
| US-2   | U2              | Custom focus management             |
| CP-1   | COM1            | Responsive layout                   |
| TS-1   | T1              | OGG Vorbis format                   |
| TS-2   | T2              | Built-in theme with overrides       |
