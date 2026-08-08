## Types command - type distribution analysis.
import ../constants
import ../parser/character
import ../output/table
import ../output/csv
import ../output/html

proc runTypes*(characters: seq[CharacterData], format: string,
               output: string): bool =
  ## Display type distribution analysis. Returns false when output fails.
  if characters.len == 0:
    echo "No characters found."
    return true

  var
    primary: array[TYPE_COUNT, int]
    secondary: array[TYPE_COUNT, int]
    typeSums: array[TYPE_COUNT, int]
    typeCounts: array[TYPE_COUNT, int]

  for character in characters:
    if character.`type` >= 0 and character.`type` < TYPE_COUNT:
      inc primary[character.`type`]
      typeSums[character.`type`] += statSum(character)
      inc typeCounts[character.`type`]
    if character.secondary >= 0 and character.secondary < TYPE_COUNT:
      inc secondary[character.secondary]

  case format
  of "csv":
    let headers = @["type", "primary_count", "secondary_count", "avg_sum"]
    var rows: seq[seq[string]] = @[]
    for typeIdx in 0..<TYPE_COUNT:
      let avg = if typeCounts[typeIdx] > 0: typeSums[typeIdx] div typeCounts[typeIdx] else: 0
      rows.add(@[TYPE_LABELS[typeIdx], $primary[typeIdx], $secondary[typeIdx], $avg])
    return writeCSV(headers, rows, output)
  
  of "html":
    var html = htmlHeader("Type Distribution")
    html &= "<h1>Type Distribution Analysis</h1>\n"
    html &= "<p>Total: " & $characters.len & " characters</p>\n"
    
    let headers = @["Type", "Primary", "With Secondary", "Avg Stat Sum"]
    var rows: seq[seq[string]] = @[]
    for typeIdx in 0..<TYPE_COUNT:
      let avg = if typeCounts[typeIdx] > 0: typeSums[typeIdx] div typeCounts[typeIdx] else: 0
      rows.add(@[TYPE_LABELS[typeIdx], $primary[typeIdx], $secondary[typeIdx], $avg])
    html &= htmlTable(headers, rows)
    html &= htmlFooter()
    
    if output.len > 0:
      return writeHTML(output, html)
    else:
      echo html
      return true
  
  else: # table
    var table = newTableOutput(
      @["Type", "Primary", "Secondary", "Avg Sum"],
      @[8, 8, 10, 8]
    )
    for typeIdx in 0..<TYPE_COUNT:
      let avg = if typeCounts[typeIdx] > 0: typeSums[typeIdx] div typeCounts[typeIdx] else: 0
      table.addRow(@[TYPE_LABELS[typeIdx], $primary[typeIdx], $secondary[typeIdx], $avg])
    if output.len > 0:
      return writeTableFile(table, output)
    else:
      echo "=== Type distribution (primary / with secondary) ==="
      printTable(table)
      echo "\nTotal: ", characters.len, " characters"
      return true
