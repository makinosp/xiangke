## SVG Radar Chart generator.
## Generates radar charts for character stat visualization.
import std/[strutils, math]
import ../constants
import ../parser/character

const
  STAT_LABELS = ["HP", "ATK", "DEF", "SPD", "INT", "SPR"]

proc polarToCartesian(cx, cy, radius, angle: float): (float, float) =
  ## Convert polar coordinates to Cartesian.
  let rad = angle * PI / 180.0
  return (cx + radius * cos(rad), cy + radius * sin(rad))

proc generatePolygonPoints*(cx, cy, radius: float, values: array[STAT_COUNT, float],
                           maxValue: float): string =
  ## Generate SVG polygon points for a radar chart.
  var points: seq[string] = @[]
  
  for statIdx in 0..<STAT_COUNT:
    let angle = AXIS_START_ANGLE + (AXIS_ANGLE_STEP * statIdx.float)  # Start from top, go clockwise
    let normalizedValue = min(values[statIdx] / maxValue, 1.0)
    let (coordX, coordY) = polarToCartesian(cx, cy, radius * normalizedValue, angle)
    points.add($coordX & "," & $coordY)
  
  return points.join(" ")

proc generateAxisLines*(cx, cy, radius: float): string =
  ## Generate SVG lines for radar chart axes.
  var lines = ""
  for statIdx in 0..<STAT_COUNT:
    let angle = AXIS_START_ANGLE + (AXIS_ANGLE_STEP * statIdx.float)
    let (coordX, coordY) = polarToCartesian(cx, cy, radius, angle)
    lines &= "<line x1=\"" & $cx & "\" y1=\"" & $cy & "\" " &
             "x2=\"" & $coordX & "\" y2=\"" & $coordY & "\" " &
             "stroke=\"#ddd\" stroke-width=\"1\"/>\n"
  return lines

proc generateAxisLabels*(cx, cy, radius: float): string =
  ## Generate SVG text labels for radar chart axes.
  var labels = ""
  for statIdx in 0..<STAT_COUNT:
    let angle = AXIS_START_ANGLE + (AXIS_ANGLE_STEP * statIdx.float)
    let (coordX, coordY) = polarToCartesian(cx, cy, radius + AXIS_LABEL_OFFSET, angle)
    labels &= "<text x=\"" & $coordX & "\" y=\"" & $coordY & "\" " &
              "text-anchor=\"middle\" dominant-baseline=\"middle\" " &
              "font-size=\"12\" fill=\"#666\">" & STAT_LABELS[statIdx] & "</text>\n"
  return labels

proc generateGridCircles*(cx, cy, radius: float, levels: int = GRID_LEVELS): string =
  ## Generate concentric grid circles.
  var circles = ""
  for level in 1..levels:
    let gridRadius = radius * (level.float / levels.float)
    circles &= "<circle cx=\"" & $cx & "\" cy=\"" & $cy & "\" " &
               "r=\"" & $gridRadius & "\" fill=\"none\" stroke=\"#eee\" stroke-width=\"1\"/>\n"
  return circles

proc getCharacterColor*(index: int): string =
  ## Get a color for a character based on index.
  return CHARACTER_COLORS[index mod CHARACTER_COLORS.len]

proc generateRadarChart*(avgStats: array[STAT_COUNT, float],
                         characters: seq[CharacterData]): string =
  ## Generate a complete SVG radar chart.
  var svg = "<svg width=\"" & $CHART_SIZE & "\" height=\"" & $CHART_SIZE & "\" " &
            "viewBox=\"0 0 " & $CHART_SIZE & " " & $CHART_SIZE & "\">\n"
  
  # Background
  svg &= "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>\n"
  
  # Grid
  svg &= generateGridCircles(CHART_CENTER, CHART_CENTER, CHART_RADIUS)
  
  # Axes
  svg &= generateAxisLines(CHART_CENTER, CHART_CENTER, CHART_RADIUS)
  
  # Labels
  svg &= generateAxisLabels(CHART_CENTER, CHART_CENTER, CHART_RADIUS)
  
  # Average polygon (blue, semi-transparent)
  let avgPoints = generatePolygonPoints(CHART_CENTER, CHART_CENTER, CHART_RADIUS, avgStats, MAX_STAT)
  svg &= "<polygon points=\"" & avgPoints & "\" " &
          "fill=\"rgba(74, 144, 217, 0.3)\" stroke=\"#4a90d9\" stroke-width=\"2\"/>\n"
  
  # Individual character polygons
  for charIdx, character in characters:
    var charStats: array[STAT_COUNT, float]
    charStats[0] = character.stats.hp.float
    charStats[1] = character.stats.attack.float
    charStats[2] = character.stats.defense.float
    charStats[3] = character.stats.speed.float
    charStats[4] = character.stats.intelligence.float
    charStats[5] = character.stats.spirit.float
    
    let color = getCharacterColor(charIdx)
    let points = generatePolygonPoints(CHART_CENTER, CHART_CENTER, CHART_RADIUS, charStats, MAX_STAT)
    svg &= "<polygon points=\"" & points & "\" " &
            "fill=\"rgba(" & color[1..6] & ", 0.1)\" stroke=\"" & color & "\" stroke-width=\"1\"/>\n"
  
  svg &= "</svg>\n"
  return svg
