# NFR Requirements Plan — Unit 2: Game Foundation

## Status

- [x] Step 1: Analyze Functional Design
- [x] Step 2: Create NFR Requirements Plan (this file)
- [x] Step 3: Generate Context-Appropriate Questions
- [x] Step 4: Store Plan
- [x] Step 5: Collect and Analyze Answers
- [x] Step 6: Generate NFR Requirements Artifacts
- [ ] Step 7: Present Completion Message
- [ ] Step 8: Wait for Explicit Approval
- [ ] Step 9: Record Approval and Update Progress

## Already Decided (from requirements.md)

The following NFR items are already established in
`inception/requirements/requirements.md` and do not require re-confirmation:

| Topic                     | Requirement                                            | Source                |
| ------------------------- | ------------------------------------------------------ | --------------------- |
| **Target Platform**       | Web (HTML5/WebAssembly) primary; desktop for dev/test  | FR-1.2, FR-1.3, CON-3 |
| **Load Time**             | <10 seconds initial load                               | NFR-1.2               |
| **Frame Rate**            | ≥30 FPS in Web export                                  | NFR-1.1               |
| **Offline**               | Fully offline; no external server                      | FR-5.4, NFR-4.2       |
| **Sensitive Data**        | None — local storage only, sandboxed by browser        | NFR-4.1, NFR-4.2      |
| **Godot Version**         | Godot 4.x (latest stable)                              | FR-1.1, CON-1         |
| **Primary Language**      | GDScript                                               | CON-2                 |
| **Browser Compatibility** | Chrome, Firefox, Safari, Edge                          | NFR-2.1               |
| **Input**                 | Keyboard and mouse                                     | NFR-2.2               |
| **Code Quality**          | GDScript best practices, Godot node-based architecture | NFR-3.1, NFR-3.2      |

---

## NFR Assessment Questions

### Performance Requirements

#### Question P1

What are the performance requirements for scene transitions?

A) No strict requirement — transitions can take up to 1 second

B) Must complete within 500ms (smooth UX expectation)

C) Must complete within 250ms (instant-feeling transitions)

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question P2

What is the acceptable latency for audio playback (SFX trigger to audible)?

A) No strict requirement — up to 100ms delay acceptable

B) Must be <50ms for responsive feedback

C) Must be <25ms for immediate feedback

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Reliability Requirements

#### Question REL1

How should the system handle save file corruption or missing save data?

A) Reset to defaults silently (no user notification)

B) Reset to defaults with a one-time warning message

C) Attempt recovery of valid portions, preserve what's usable

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question REL2

What happens if the game state machine receives an invalid transition request?

A) Log error and ignore (no user feedback)

B) Log error and show a debug message in development builds

C) Show an error dialog to the user

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Security Requirements

#### Question SEC1

What level of save file integrity checking is required?

A) None — save file can be corrupted without detection

B) Basic checksum validation to detect corruption

C) Checksum + timestamp validation to detect tampering

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Maintainability Requirements

#### Question MA1

How should the scene transition system be configured for different transitions?

A) Hardcoded values in the transition code

B) Configurable via exported variables on the transition node

C) Data-driven via a transition configuration file

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question MA2

What documentation is required for the audio system?

A) Inline code comments only

B) Inline comments + audio track registry documentation

C) Inline comments + documentation + audio naming convention guide

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Usability Requirements

#### Question U1

What should happen when the player first launches the game on Web (autoplay
policy)?

A) Show a "Click to Start" screen that initializes audio on first click

B) Show a modal dialog explaining audio restrictions

C) Attempt silent audio initialization (will fail on most browsers)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

#### Question U2

How should the character selection screen handle keyboard navigation?

A) Use Godot's default focus system only

B) Custom focus management with visual highlighting

C) Full gamepad navigation with UI focus groups

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Compatibility Requirements

#### Question COM1

Should the game support different screen aspect ratios?

A) Fixed 16:9 only (letterbox/pillarbox on other ratios)

B) Responsive layout with flexible UI anchoring

C) Dynamic scaling with multiple layout presets

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Tech Stack Requirements

#### Question T1

What audio format should be used for BGM and SFX?

A) OGG Vorbis (best Web compatibility, small size)

B) MP3 (widest compatibility, larger size)

C) WAV (uncompressed, largest size)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

#### Question T2

Should the project use Godot's built-in theme system for UI?

A) No — custom UI elements only

B) Yes — use built-in theme with custom overrides

C) Yes — use theme + custom styles for all controls

D) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Extension Compliance

| Extension              | Status | Notes                                            |
| ---------------------- | ------ | ------------------------------------------------ |
| Resiliency Baseline    | N/A    | Extension opted out during Requirements Analysis |
| Security Baseline      | N/A    | Extension opted out during Requirements Analysis |
| Property-Based Testing | N/A    | Extension opted out during Requirements Analysis |
