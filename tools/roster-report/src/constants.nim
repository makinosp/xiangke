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

## Number of effect types (None, Burn, Poison, Confusion, Chain, Charm).
## Mirrors `EffectType::ALL.len()` in the Rust core.
const EFFECT_COUNT* = 6

## Number of modifiable stat values (Attack, Defense, Speed, Intelligence,
## Spirit). Mirrors `Stat::ALL.len()` in the Rust core (HP is not modifiable).
const STAT_MOD_STAT_COUNT* = 5

## Human-readable labels for the element types, indexed by type value.
const TYPE_LABELS* = ["WOOD", "FIRE", "EARTH", "METAL", "WATER", "YANG", "YIN"]

## Human-readable labels for the damage categories, indexed by category value.
const CATEGORY_LABELS* = ["Physical", "Arts"]

## Human-readable labels for the effect types, indexed by effect value.
const EFFECT_LABELS* = ["None", "Burn", "Poison", "Confusion", "Chain", "Charm"]

# --- Validation limits (mirror `extensions/core/src/validator.rs`) ---------

## Maximum length for a move/character ID.
const MAX_ID_LENGTH* = 50

## Maximum length for a move/character name.
const MAX_NAME_LENGTH* = 20

## Maximum power value for a move (0 = status move).
const MAX_POWER* = 255

## Maximum accuracy value for a move (percentage).
const MAX_ACCURACY* = 100

## Maximum effect chance percentage.
const MAX_EFFECT_CHANCE* = 100

## Maximum stat modification stage (absolute value).
const MAX_STAT_MOD_STAGE* = 3

## Maximum hit count for multi-hit moves.
const MAX_HIT_COUNT* = 5

## Maximum recoil percentage.
const MAX_RECOIL* = 100

## Maximum healing percentage.
const MAX_HEALING* = 100

## Minimum value for an individual stat.
const MIN_STAT* = 1

## Maximum value for an individual stat.
const MAX_INDIVIDUAL_STAT* = 999

## Maximum sum of all stats combined.
const MAX_STAT_SUM* = 3000

## Soft cap for an individual stat.
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
