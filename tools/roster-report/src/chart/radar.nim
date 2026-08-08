## SVG Radar Chart generator.
## Generates radar charts for character stat visualization.
import std/[strutils, math]
import ../parser/character

const
  CHART_SIZE = 400
  CENTER = CHART_SIZE / 2
  RADIUS = 150.0
  STAT_LABELS = ["HP", "ATK", "DEF", "SPD", "INT", "SPR"]
  MAX_STAT = 200.0  # Normalization value

proc polarToCartesian(cx, cy, r, angle: float): (float, float) =
  ## Convert polar coordinates to Cartesian.
  let rad = angle * PI / 180.0
  return (cx + r * cos(rad), cy + r * sin(rad))

proc generatePolygonPoints*(cx, cy, r: float, values: array[6, float],
                           maxValue: float): string =
  ## Generate SVG polygon points for a radar chart.
  var points: seq[string] = @[]
  
  for i in 0..<6:
    let angle = 90.0 + (60.0 * i.float)  # Start from top, go clockwise
    let normalizedValue = min(values[i] / maxValue, 1.0)
    let (x, y) = polarToCartesian(cx, cy, r * normalizedValue, angle)
    points.add($x & "," & $y)
  
  return points.join(" ")

proc generateAxisLines*(cx, cy, r: float): string =
  ## Generate SVG lines for radar chart axes.
  var lines = ""
  for i in 0..<6:
    let angle = 90.0 + (60.0 * i.float)
    let (x, y) = polarToCartesian(cx, cy, r, angle)
    lines &= "<line x1=\"" & $cx & "\" y1=\"" & $cy & "\" " &
             "x2=\"" & $x & "\" y2=\"" & $y & "\" " &
             "stroke=\"#ddd\" stroke-width=\"1\"/>\n"
  return lines

proc generateAxisLabels*(cx, cy, r: float): string =
  ## Generate SVG text labels for radar chart axes.
  var labels = ""
  for i in 0..<6:
    let angle = 90.0 + (60.0 * i.float)
    let (x, y) = polarToCartesian(cx, cy, r + 20, angle)
    labels &= "<text x=\"" & $x & "\" y=\"" & $y & "\" " &
              "text-anchor=\"middle\" dominant-baseline=\"middle\" " &
              "font-size=\"12\" fill=\"#666\">" & STAT_LABELS[i] & "</text>\n"
  return labels

proc generateGridCircles*(cx, cy, r: float, levels: int = 4): string =
  ## Generate concentric grid circles.
  var circles = ""
  for i in 1..levels:
    let radius = r * (i.float / levels.float)
    circles &= "<circle cx=\"" & $cx & "\" cy=\"" & $cy & "\" " &
               "r=\"" & $radius & "\" fill=\"none\" stroke=\"#eee\" stroke-width=\"1\"/>\n"
  return circles

proc getCharacterColor*(index: int): string =
  ## Get a color for a character based on index.
  let colors = [
    "#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6",
    "#1abc9c", "#e67e22", "#34495e", "#e91e63", "#00bcd4"
  ]
  return colors[index mod colors.len]

proc generateRadarChart*(avgStats: array[6, float],
                         characters: seq[CharacterData]): string =
  ## Generate a complete SVG radar chart.
  var svg = "<svg width=\"" & $CHART_SIZE & "\" height=\"" & $CHART_SIZE & "\" " &
            "viewBox=\"0 0 " & $CHART_SIZE & " " & $CHART_SIZE & "\">\n"
  
  # Background
  svg &= "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>\n"
  
  # Grid
  svg &= generateGridCircles(CENTER, CENTER, RADIUS)
  
  # Axes
  svg &= generateAxisLines(CENTER, CENTER, RADIUS)
  
  # Labels
  svg &= generateAxisLabels(CENTER, CENTER, RADIUS)
  
  # Average polygon (blue, semi-transparent)
  let avgPoints = generatePolygonPoints(CENTER, CENTER, RADIUS, avgStats, MAX_STAT)
  svg &= "<polygon points=\"" & avgPoints & "\" " &
          "fill=\"rgba(74, 144, 217, 0.3)\" stroke=\"#4a90d9\" stroke-width=\"2\"/>\n"
  
  # Individual character polygons
  for i, c in characters:
    var charStats: array[6, float]
    charStats[0] = c.stats.hp.float
    charStats[1] = c.stats.attack.float
    charStats[2] = c.stats.defense.float
    charStats[3] = c.stats.speed.float
    charStats[4] = c.stats.intelligence.float
    charStats[5] = c.stats.spirit.float
    
    let color = getCharacterColor(i)
    let points = generatePolygonPoints(CENTER, CENTER, RADIUS, charStats, MAX_STAT)
    svg &= "<polygon points=\"" & points & "\" " &
            "fill=\"rgba(" & color[1..6] & ", 0.1)\" stroke=\"" & color & "\" stroke-width=\"1\"/>\n"
  
  svg &= "</svg>\n"
  return svg
