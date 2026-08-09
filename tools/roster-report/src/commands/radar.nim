## Radar command - generate HTML radar chart.
import ../constants
import ../parser/character
import ../chart/radar
import ../output/html

proc runRadar*(characters: seq[CharacterData], format: string,
               output: string): bool =
  ## Display radar chart for character stats. Returns false when output fails.
  if characters.len == 0:
    echo "No characters found."
    return true

  # Calculate average stats
  var avgStats: array[STAT_COUNT, float]
  for character in characters:
    avgStats[0] += character.stats.hp.float
    avgStats[1] += character.stats.attack.float
    avgStats[2] += character.stats.defense.float
    avgStats[3] += character.stats.speed.float
    avgStats[4] += character.stats.intelligence.float
    avgStats[5] += character.stats.spirit.float
  
  let charCount = characters.len.float
  for statIdx in 0..<STAT_COUNT:
    avgStats[statIdx] /= charCount

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
  for charIdx, character in characters:
    let color = getCharacterColor(charIdx)
    html &= "<div class=\"legend-item\"><span class=\"legend-color\" style=\"background: " & color & ";\"></span> " & escapeHTML(character.name) & "</div>\n"
  html &= "</div>\n"
  
  html &= htmlFooter()
  
  if output.len > 0:
    return writeHTML(output, html)
  else:
    echo html
    return true
