## Context

The existing `tools/roster_report.go` is a Go tool that parses `.tres` files
with regex and outputs character roster tables and type distribution. This
design builds a new CLI tool in Nim with subcommand architecture, integrating
reporting and visualization. `roster_report.go` serves as a reference
implementation.

Related specs: `openspec/specs/data-verify/spec.md` (verification pipeline),
`openspec/specs/domain/spec.md` (domain rules)

## Goals / Non-Goals

**Goals:**

- Parse `.tres` directly without Godot dependency, streamlining routine data
  checks
- Provide multi-angle reports via six subcommands
- Support three output formats: text table, CSV, HTML
- Embed Radar Chart as SVG in HTML reports
- Fully encompass existing `roster_report.go` functionality

**Non-Goals:**

- JSON export via Godot (existing `verify-data` scope)
- Real-time data monitoring
- Battle simulation
- Production deployment

## Decisions

### 1. Implementation Language: Nim

**Choice**: Nim

**Rationale**:

- Python-like readable syntax for high development efficiency
- Single binary output, no GC (`--gc:refc` available if GC is desired)
- Rich standard library: regex (`re`), HTML templates, CSV, streams
- Fast builds, compiles to C for good performance
- Godot project affinity (future integration possible via Nim → C → GDExtension)
- Good memory efficiency

**Alternatives considered**:

- **Go**: `roster_report.go` exists, but Nim's development efficiency and
  standard library richness are superior
- **Rust**: Integrable with `xiangke-core`, but type redefinition overhead makes
  it cost-ineffective
- **Zig**: Low-level control possible, but string manipulation and template
  generation are verbose
- **Crystal**: Ruby-like, but LLVM dependency at build time and high memory
  consumption

### 2. CLI Framework: Manual Dispatch with `parseopt`

**Choice**: `std/parseopt` (Nim standard library) with manual subcommand
dispatch

**Rationale**:

- Lightweight, no external dependencies
- Full control over argument parsing and help text
- Subcommand dispatch implemented manually in `main.nim`
- `cligen` was considered but manual dispatch proved simpler for six subcommands

**Alternatives considered**:

- **`cligen`**: Generates CLI from procedure definitions, but adds unnecessary
  complexity for this use case
- **`argparse`**: Equivalent to cligen, but no project track record

### 3. .tres Parsing: Regex-Based Extraction

**Choice**: Nim standard `re` module to extract `key = value` patterns

**Rationale**:

- Reimplements `roster_report.go` approach in Nim
- Godot `.tres` format is stable (`gd_resource` format)
- Nim's `re` module is PCRE-compatible and high-performance
- No external libraries required

**Known Limitations**:

- Parsing deeply nested objects (`sub_resource`) is complex
- Currently not an issue since characters/moves/status effects use flat format

### 4. HTML Report: Nim Standard Templates + Inline SVG

**Choice**: Generate HTML with Nim's `std/htmlgen` and `std/streams`, embedding
Radar Chart as inline SVG

**Rationale**:

- No external dependencies
- SVG renders directly in browsers
- Nim's HTML generation is intuitive via string operations

**Radar Chart Implementation**:

- Hexagonal SVG with 6 axes (HP, ATK, DEF, SPD, INT, SPR)
- Average polygon overlaid with per-character polygons
- CSS styling (color coding, legend)

### 5. Project Structure

```
tools/data_report_cli/
├── data_report_cli.nimble   Package definition
├── src/
│   ├── main.nim             Entry point, CLI setup
│   ├── parser/
│   │   ├── tres.nim         .tres file parser
│   │   ├── character.nim    CharacterData type definition
│   │   ├── move.nim         MoveData type definition
│   │   └── status_effect.nim StatusEffectData type definition
│   ├── commands/
│   │   ├── roster.nim       roster subcommand
│   │   ├── types.nim        types subcommand
│   │   ├── moves.nim        moves subcommand
│   │   ├── anomalies.nim    anomalies subcommand
│   │   ├── ranking.nim      ranking subcommand
│   │   └── radar.nim        radar subcommand
│   ├── output/
│   │   ├── table.nim        Text table output
│   │   ├── csv.nim          CSV output
│   │   └── html.nim         HTML output
│   └── chart/
│       └── radar.nim        SVG Radar Chart generation
└── tests/
    └── test_parser.nim      Parser unit tests
```

## Risks / Trade-offs

| Risk                                    | Mitigation                                              |
| --------------------------------------- | ------------------------------------------------------- |
| `.tres` format changes break parser     | Detect via tests; modular parser design for easy fixes  |
| Feature overlap with `roster_report.go` | Integration/removal planned after feature parity        |
| SVG Radar Chart rendering accuracy      | Normalize against existing stat range (1-999)           |
| Nim ecosystem smaller than Go           | Standard library covers needs; minimal external deps    |
| Nim installation in CI/CD               | Package management via nimble; GitHub Actions Nim setup |

## Migration Plan

1. Create `tools/data_report_cli/` (Nim project structure)
2. Implement `parser/` referencing `roster_report.go` parsing logic
3. Implement subcommands sequentially
4. Add `report` recipe to `justfile`
5. After verification, remove `roster_report.go` (or deprecate in README)
