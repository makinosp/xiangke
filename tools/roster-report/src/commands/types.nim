## Types command - type distribution analysis.
import ../parser/character
import ../output/table
import ../output/csv
import ../output/html

proc runTypes*(characters: seq[CharacterData], format: string, output: string) =
  ## Display type distribution analysis.
  if characters.len == 0:
    echo "No characters found."
    return

  var
    primary: array[7, int]
    secondary: array[7, int]
    typeSums: array[7, int]
    typeCounts: array[7, int]

  for c in characters:
    if c.`type` >= 0 and c.`type` < 7:
      inc primary[c.`type`]
      typeSums[c.`type`] += statSum(c)
      inc typeCounts[c.`type`]
    if c.secondary >= 0 and c.secondary < 7:
      inc secondary[c.secondary]

  case format
  of "csv":
    let headers = @["type", "primary_count", "secondary_count", "avg_sum"]
    var rows: seq[seq[string]] = @[]
    for i in 0..<7:
      let avg = if typeCounts[i] > 0: typeSums[i] div typeCounts[i] else: 0
      rows.add(@[TYPES[i], $primary[i], $secondary[i], $avg])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Type Distribution")
    html &= "<h1>Type Distribution Analysis</h1>\n"
    html &= "<p>Total: " & $characters.len & " characters</p>\n"
    
    let headers = @["Type", "Primary", "With Secondary", "Avg Stat Sum"]
    var rows: seq[seq[string]] = @[]
    for i in 0..<7:
      let avg = if typeCounts[i] > 0: typeSums[i] div typeCounts[i] else: 0
      rows.add(@[TYPES[i], $primary[i], $secondary[i], $avg])
    html &= htmlTable(headers, rows)
    html &= htmlFooter()
    
    if output.len > 0:
      writeHTML(output, html)
    else:
      echo html
  
  else: # table
    echo "=== Type distribution (primary / with secondary) ==="
    var table = newTableOutput(
      @["Type", "Primary", "Secondary", "Avg Sum"],
      @[8, 8, 10, 8]
    )
    for i in 0..<7:
      let avg = if typeCounts[i] > 0: typeSums[i] div typeCounts[i] else: 0
      table.addRow(@[TYPES[i], $primary[i], $secondary[i], $avg])
    printTable(table)
    echo "\nTotal: ", characters.len, " characters"
