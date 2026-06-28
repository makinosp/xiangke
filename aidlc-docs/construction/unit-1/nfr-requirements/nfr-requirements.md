# NFR Requirements — Unit 1: Resources (Shared Data)

## Overview

Non-functional requirements for the game's shared data layer. These requirements
govern how the data infrastructure supports the game's runtime behavior,
maintainability, and quality.

---

## Scalability Requirements

### SC-1: Character and Move Roster

- **SC-1.1**: The system shall support an initial roster of 50+ characters.
- **SC-1.2**: The system shall support 200+ moves.
- **SC-1.3**: The data structure shall accommodate post-launch content expansion
  (DLC) without architectural changes.
- **SC-1.4**: Character and move data shall be defined in individual resource
  files to allow incremental addition.

### SC-2: Post-Launch Modifiability

- **SC-2.1**: Game data shall support developer-controlled balance patches.
- **SC-2.2**: The data format shall support versioning for patch compatibility
  detection.
- **SC-2.3**: User-generated mods are NOT required in v1.

---

## Performance Requirements

### PF-1: Target Platform

- **PF-1.1**: Primary target is Web (HTML5/WebAssembly).
- **PF-1.2**: Desktop (Windows, macOS, Linux) is supported for development and
  testing.
- **PF-1.3**: The system shall maintain ≥30 FPS in Web export.

### PF-2: Load Time

- **PF-2.1**: Initial data load shall complete within 10 seconds on Web
  platform.
- **PF-2.2**: All game data (characters, moves, type chart, status effects)
  shall be preloaded at startup.

### PF-3: Runtime Calculation

- **PF-3.1**: No strict per-frame calculation time requirement for data lookups.
- **PF-3.2**: Type effectiveness resolution and damage calculation are O(1)
  operations and do not require optimization beyond standard practices.

---

## Security Requirements

### SE-1: Data Protection

- **SE-1.1**: No sensitive user data is stored (no accounts, no PII, no payment
  information).
- **SE-1.2**: All player data is stored locally in Godot's user data directory
  (sandboxed by browser).

### SE-2: Save Data Integrity

- **SE-2.1**: Save files shall include basic checksum validation to detect
  corruption.
- **SE-2.2**: Encrypted save files are NOT required (single-player offline).
- **SE-2.3**: Server-authoritative validation is NOT required (no online
  multiplayer).

---

## Reliability Requirements

### RE-1: Error Handling

- **RE-1.1**: Data loading shall use standard error handling — log warnings for
  invalid entries, skip invalid data, continue loading.
- **RE-1.2**: The system shall NOT crash on individual data entry errors.
- **RE-1.3**: Warning messages shall include the entity ID and specific
  validation failure for debugging.

### RE-2: Automated Testing

- **RE-2.1**: Unit tests shall be implemented for all validation rules.
- **RE-2.2**: Test coverage shall include:
  - Character data rules (CR-1 through CR-4)
  - Move data rules (MR-1 through MR-7)
  - Type chart rules (TR-1 through TR-3)
  - Status effect rules (SR-1 through SR-5)
  - Data validation rules (VR-1 through VR-3)
- **RE-2.3**: Integration tests for the data layer are NOT required in v1.

---

## Maintainability Requirements

### MA-1: Project Lifespan

- **MA-1.1**: The project is expected to be maintained for 1-3 years with
  periodic updates.
- **MA-1.2**: The data structure shall be designed for clarity and ease of
  modification.

### MA-2: Team Size

- **MA-2.1**: The data layer is maintained by a solo developer.
- **MA-2.2**: Code and data shall be self-documenting with minimal external
  documentation.

---

## Usability Requirements

### US-1: Data Editing

- **US-1.1**: Game data is edited by developers using the Godot Editor.
- **US-1.2**: Non-technical designer tooling is NOT required in v1.
- **US-1.3**: External spreadsheet import pipelines are NOT required in v1.

### US-2: Localization

- **US-2.1**: The data structure shall support multi-language (3+ languages).
- **US-2.2**: Character names and descriptions shall use Godot's translation key
  system.
- **US-2.3**: The initial implementation includes Japanese and English.

---

## Traceability

| NFR ID | Source Question | Requirement Source                               |
| ------ | --------------- | ------------------------------------------------ |
| SC-1   | S1              | Functional Design — initial roster 9+ characters |
| SC-2   | S2              | Balance patches only                             |
| PF-1   | Already decided | FR-1.2, FR-1.3, CON-3, NFR-1.1                   |
| PF-2   | Already decided | NFR-1.2                                          |
| PF-3   | P3              | No strict requirement                            |
| SE-1   | Already decided | NFR-4.1, NFR-4.2                                 |
| SE-2   | SEC2            | Basic checksums                                  |
| RE-1   | R1              | Standard error handling                          |
| RE-2   | R2              | Unit tests for validation                        |
| MA-1   | M1              | Medium-term (1-3 years)                          |
| MA-2   | M2              | Solo developer                                   |
| US-1   | U1              | Developers only                                  |
| US-2   | U2              | Multi-language (3+)                              |
