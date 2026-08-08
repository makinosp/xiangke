## Radar command - generate HTML radar chart.
import ../parser/character
import ../chart/radar
import ../output/html

proc runRadar*(characters: seq[CharacterData], format: string, output: string) =
  ## Display radar chart for character stats.
  if characters.len == 0:
    echo "No characters found."
    return

  # Calculate average stats
  var avgStats: array[6, float]
  for c in characters:
    avgStats[0] += c.stats.hp.float
    avgStats[1] += c.stats.attack.float
    avgStats[2] += c.stats.defense.float
    avgStats[3] += c.stats.speed.float
    avgStats[4] += c.stats.intelligence.float
    avgStats[5] += c.stats.spirit.float
  
  let n = characters.len.float
  for i in 0..<6:
    avgStats[i] /= n

  # Generate HTML with radar chart
  var html = htmlHeader("Radar Chart")
  html &= "<h1>Character Stats Radar Chart</h1>\n"
  html &= "<p>Average stats across " & $characters.len & " characters</p>\n"
  
  # Generate radar chart SVG
  html &= "<div class=\"chart-container\">\n"
  html &= generateRadarChart(avgStats, characters)
  html &= "</div>\n"
  
  # Add legend
  html &= "<div class=\"legend\">\n"
  html &= "<div class=\"legend-item\"><span class=\"legend-color\" style=\"background: #4a90d9;\"></span> Average</div>\n"
  for i, c in characters:
    let color = getCharacterColor(i)
    html &= "<div class=\"legend-item\"><span class=\"legend-color\" style=\"background: " & color & ";\"></span> " & escapeHTML(c.name) & "</div>\n"
  html &= "</div>\n"
  
  html &= htmlFooter()
  
  if output.len > 0:
    writeHTML(output, html)
  else:
    echo html
