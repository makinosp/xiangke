## Why

A lightweight CLI tool is needed to verify game data (.tres files) integrity and
balance during development. The existing `verify-data` pipeline requires Godot
headless, making it too heavy for routine data checks. We extend the
`roster_report.go`-style Godot-independent approach and integrate reporting and
visualization capabilities.

## What Changes

- Add a new CLI tool under `tools/data_report_cli`
- Godot-independent `.tres` file parsing via regex
- Six subcommands for multi-angle data reporting:
  - `roster`: Character roster table (stat totals, type display)
  - `types`: Type distribution and balance analysis (primary/secondary stats)
  - `moves`: Move assignment list (with power display)
  - `anomalies`: Stat anomaly detection (overflows, unrefed moves, integrity
    errors)
  - `ranking`: Stat total ranking (top/bottom)
  - `radar`: Stat Radar Chart (embedded SVG in HTML)
- Three output formats: text table, CSV, HTML
- Add `report` recipe to `justfile`

## Capabilities

### New Capabilities

_(none — pure tool addition, no spec changes)_

### Modified Capabilities

_(none)_

## Impact

- **New files**: `tools/data_report_cli/` directory tree
- **Existing tools**: `roster_report.go` is a replacement target (to be removed
  or kept for compatibility after feature integration)
- **justfile**: Add `report` recipe
- **Dependencies**: No external dependencies (Go stdlib only, or Rust stdlib
  only)
- **CI/CD**: No impact (development tool only)
