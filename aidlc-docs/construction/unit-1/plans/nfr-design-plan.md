# NFR Design Plan — Unit 1: Resources (Shared Data)

## Status

- [x] Step 1: Analyze NFR Requirements
- [x] Step 2: Create NFR Design Plan (this file)
- [x] Step 3: Generate Context-Appropriate Questions
- [x] Step 4: Store Plan
- [x] Step 5: Collect and Analyze Answers
- [x] Step 6: Generate NFR Design Artifacts
- [x] Step 7: Present Completion Message
- [x] Step 8: Wait for Explicit Approval
- [x] Step 9: Record Approval and Update Progress

## NFR Design Questions

### Resilience Patterns

#### Question RP-1

How should the data loader handle a completely missing or corrupted .tres file?

A) Crash with a fatal error — the game cannot run without valid data

B) Log a critical warning and use default/placeholder data

C) Log a critical warning and skip the missing file, continue loading others

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question RP-2

Should the validation system report all errors at once, or stop on the first
error?

A) Stop on first error — fix immediately before proceeding

B) Report all errors at once — collect all violations, then display summary

C) Report errors by category — show all character errors, then all move errors,
etc.

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Scalability Patterns

#### Question SP-1

How should new character and move files be discovered at runtime?

A) Explicit registry — a master file lists all character/move IDs

B) Directory scanning — scan `resources/characters/` and `resources/moves/` at
load

C) Hybrid — directory scanning with a cache file for quick startup

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question SP-2

Should the data system support loading additional content packs (DLC) at
runtime?

A) No — all content is baked into the initial build

B) Yes — load additional .tres directories from a DLC folder

C) Yes — with a manifest system for dependency resolution

D) Other (please describe after [Answer]: tag below)

[Answer]: B

### Performance Patterns

#### Question PP-1

Should type effectiveness resolution use a precomputed lookup table or calculate
on the fly?

A) Precomputed 2D array (7×7 matrix) — fastest lookup, minimal memory

B) Calculated on the fly — more flexible but slower

C) Precomputed with caching — build matrix at startup, cache results

D) Other (please describe after [Answer]: tag below)

[Answer]: A

#### Question PP-2

How should the 50+ character and 200+ move resources be organized in memory?

A) Flat dictionary — all characters in one `Dictionary`, all moves in another

B) Indexed array — maintain arrays with ID-to-index mapping

C) Godot resource cache — rely on Godot's built-in resource caching

D) Other (please describe after [Answer]: tag below)

[Answer]: A

### Security Patterns

#### Question SEC-P-1

What checksum algorithm should be used for save file validation?

A) CRC32 — fast, sufficient for corruption detection

B) MD5 — widely supported, moderate collision resistance

C) SHA-256 — strong collision resistance, slower

D) No checksum needed — rely on Godot's serialization

E) Other (please describe after [Answer]: tag below)

[Answer]: A

### Logical Components

#### Question LC-1

Should the validation logic be centralized or distributed?

A) Centralized — single `DataValidator` class validates all data types

B) Distributed — each resource type has its own validation method

C) Hybrid — shared validation utilities with type-specific rules

D) Other (please describe after [Answer]: tag below)

[Answer]: C

#### Question LC-2

How should localization keys be stored in character/move .tres files?

A) Direct translation key (e.g., `name = "CHAR_ZHUGE_LIANG_NAME"`) — resolved at
runtime

B) Default text with optional translation key (e.g., `name = "諸葛亮"`,
`name_translation_key = "CHAR_ZHUGE_LIANG_NAME"`)

C) Only default text — localization handled externally

D) Other (please describe after [Answer]: tag below)

[Answer]: B

#### Question LC-3

Should the data version be stored per-file or as a global constant?

A) Per-file version — each .tres file has its own version field

B) Global constant — single `DATA_VERSION` constant in a script

C) Hybrid — global version for compatibility, per-file version for detailed
tracking

D) Other (please describe after [Answer]: tag below)

[Answer]: C
