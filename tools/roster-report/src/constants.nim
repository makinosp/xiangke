## Centralized constants for the roster-report CLI.
## Values mirror the authoritative definitions in the Rust core
## (`extensions/core/src/validator.rs`, `extensions/core/src/types.rs`)
## and the Godot type enums (`scripts/type_enums.gd`).

# --- Domain counts ---------------------------------------------------------

## Number of element types (Wood, Fire, Earth, Metal, Water, Yang, Yin).
## Mirrors `TypeElement::COUNT` in the Rust core.
const TYPE_COUNT* = 7

## Number of character stats (HP, Attack, Defense, Speed, Intelligence, Spirit).
const STAT_COUNT* = 6

## Number of damage categories (Physical, Arts).
const CATEGORY_COUNT* = 2

## Human-readable labels for the element types, indexed by type value.
const TYPE_LABELS* = ["WOOD", "FIRE", "EARTH", "METAL", "WATER", "YANG", "YIN"]

## Human-readable labels for the damage categories, indexed by category value.
const CATEGORY_LABELS* = ["Physical", "Arts"]

# --- Validation limits (mirror `extensions/core/src/validator.rs`) ---------

## Maximum sum of all stats combined.
const MAX_STAT_SUM* = 3000

## Soft cap for an individual stat (warning threshold).
const SOFT_STAT_CAP* = 500

## Required number of moves per character.
const REQUIRED_MOVE_COUNT* = 4

# --- Radar chart constants --------------------------------------------------

## SVG canvas size (width and height) in pixels.
const CHART_SIZE* = 400

## Center of the chart canvas.
const CHART_CENTER* = CHART_SIZE / 2

## Radius of the radar chart in pixels.
const CHART_RADIUS* = 150.0

## Normalization value for stat values when plotting.
const MAX_STAT* = 200.0

## Angle step between adjacent stat axes in degrees (360 / STAT_COUNT).
const AXIS_ANGLE_STEP* = 360.0 / STAT_COUNT.float

## Starting angle (degrees) for the first stat axis (top of the chart).
const AXIS_START_ANGLE* = 90.0

## Offset (pixels) used to place axis labels outside the chart radius.
const AXIS_LABEL_OFFSET* = 20

## Number of concentric grid circles drawn on the radar chart.
const GRID_LEVELS* = 4

## Color palette used to distinguish characters in the radar chart.
const CHARACTER_COLORS* = [
  "#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6",
  "#1abc9c", "#e67e22", "#34495e", "#e91e63", "#00bcd4"
]

# --- Output constants -------------------------------------------------------

## Default column width used when a table column has no explicit width.
const DEFAULT_COLUMN_WIDTH* = 10

# --- CLI ---------------------------------------------------------------------

## Tool version, kept in sync with `roster-report.nimble`.
const VERSION* = "0.1.0"
