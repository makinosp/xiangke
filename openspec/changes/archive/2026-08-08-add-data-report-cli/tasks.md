## 1. Project Setup

- [x] 1.1 Create `tools/data_report_cli/` directory structure
- [x] 1.2 Initialize package with `nimble init` (`data_report_cli.nimble`)
- [x] 1.3 Implement CLI entry point with subcommand dispatch in `src/main.nim`
- [x] 1.4 Verify Nim installation and nimble setup

## 2. .tres Parser

- [x] 2.1 `src/parser/tres.nim` — Common `.tres` parser (`key = value`
      extraction)
- [x] 2.2 `src/parser/character.nim` — CharacterData type definition and parse
      function
- [x] 2.3 `src/parser/move.nim` — MoveData type definition and parse function
- [x] 2.4 `src/parser/status_effect.nim` — StatusEffectData type definition and
      parse function
- [x] 2.5 Parser unit tests (`tests/test_parser.nim`, validated against existing
      `.tres` files)

## 3. Output Infrastructure

- [x] 3.1 `src/output/table.nim` — Text table output utility
- [x] 3.2 `src/output/csv.nim` — CSV output utility
- [x] 3.3 `src/output/html.nim` — HTML template output infrastructure

## 4. Subcommand Implementation

- [x] 4.1 `src/commands/roster.nim` — Character roster table (stat totals, type
      display)
- [x] 4.2 `src/commands/types.nim` — Type distribution and balance analysis
      (primary/secondary stats)
- [x] 4.3 `src/commands/moves.nim` — Move assignment list (with power display)
- [x] 4.4 `src/commands/anomalies.nim` — Stat anomaly detection (overflows,
      unrefed moves, integrity errors)
- [x] 4.5 `src/commands/ranking.nim` — Stat total ranking (top/bottom)
- [x] 4.6 `src/commands/radar.nim` — Radar Chart command (HTML output trigger)

## 5. Radar Chart

- [x] 5.1 `src/chart/radar.nim` — SVG Radar Chart generation (6 axes: HP, ATK,
      DEF, SPD, INT, SPR)
- [x] 5.2 Average polygon and per-character polygon overlay
- [x] 5.3 Embed Radar Chart in HTML template

## 6. Integration & Polish

- [x] 6.1 `--format` flag to switch between table/csv/html
- [x] 6.2 Add `report` recipe to `justfile` (run via `nim c -r`)
- [x] 6.3 `--help` display setup
- [x] 6.4 Error handling (file not found, parse errors, etc.)
- [x] 6.5 Feature comparison test with existing `roster_report.go`
