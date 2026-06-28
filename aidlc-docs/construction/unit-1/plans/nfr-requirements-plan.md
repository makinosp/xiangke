# NFR Requirements Plan — Unit 1: Resources (Shared Data)

## Status

- [x] Step 1: Analyze Functional Design
- [x] Step 2: Create NFR Requirements Plan (this file)
- [x] Step 3: Generate Context-Appropriate Questions
- [x] Step 4: Store Plan
- [ ] Step 5: Collect and Analyze Answers
- [ ] Step 6: Generate NFR Requirements Artifacts
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

### Scalability Requirements

#### Question S1

How many characters and moves are expected in the initial release, and what is
the projected growth over time?

A) Small roster (9-15 characters, ~40 moves), no planned growth

B) Medium roster (20-40 characters, ~80-160 moves), moderate DLC expansion

C) Large roster (50+ characters, 200+ moves), aggressive post-launch content

D) Other (please describe after [Answer]: tag below)

[Answer]: C

#### Question S2

Will the type chart and game data need to be modifiable post-launch (e.g.,
balance patches, user mods)?

A) Static data — no changes planned after release

B) Balance patches only — developer-controlled updates

C) User-modifiable — support for community mods

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Performance Requirements

#### Question P3

Are there runtime performance requirements for battle calculations (e.g., type
effectiveness resolution must complete within X ms)?

A) No strict requirement — calculations are simple enough

B) Must complete within 16ms (60fps budget)

C) Must complete within 33ms (30fps budget)

D) Other (please describe after [Answer]: tag below)

[Answer]:

### Security Requirements

#### Question SEC2

Are there anti-cheat or data integrity requirements for game saves?

A) No protection needed — single-player offline

B) Basic save file validation (checksums)

C) Encrypted save files to prevent tampering

D) Server-authoritative validation for online modes

E) Other (please describe after [Answer]: tag below)

[Answer]: B

### Tech Stack Selection

#### Question T2

What data format will be used for storing character and move resources?

A) Godot .tres resource files (native)

B) JSON files (portable, human-readable)

C) CSV files (spreadsheet-friendly)

D) Custom binary format (performance-optimized)

E) Other (please describe after [Answer]: tag below)

[Answer]: A

#### Question T3

Is there a preference for how game data is loaded into the engine?

A) Preloaded at startup (all resources in memory)

B) Lazy loading (load on demand)

C) Streaming (load as needed during gameplay)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Reliability Requirements

#### Question R1

What level of error handling and logging is expected for data loading?

A) Basic — crash on invalid data with error message

B) Standard — log warnings, skip invalid entries, continue

C) Robust — detailed error reporting, graceful degradation, recovery

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question R2

Are there automated tests required for the data layer?

A) No automated tests needed

B) Unit tests for validation logic only

C) Full test suite (unit + integration + data integrity)

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Maintainability Requirements

#### Question M1

What is the expected project lifespan and maintenance frequency?

A) Short-term (1 year or less, no major updates)

B) Medium-term (1-3 years, periodic updates)

C) Long-term (3+ years, active development)

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question M2

How many developers will be working on this data layer?

A) Solo developer

B) Small team (2-5 developers)

C) Medium team (5-15 developers)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Usability Requirements

#### Question U1

Will non-technical designers need to edit game data directly?

A) Developers only — no special tooling needed

B) Designers use Godot Editor with .tres files

C) External tool/spreadsheet import pipeline required

D) Other (please describe after [Answer]: tag below)

[Answer]: A

#### Question U2

Is localization/internationalization required for character names and
descriptions?

A) Japanese only (single language)

B) Japanese + English

C) Multi-language support (3+ languages)

D) Other (please describe after [Answer]: tag below)

[Answer]: C
