## Ranking command - stat total ranking.
import std/[algorithm]
import ../parser/character
import ../output/table
import ../output/csv
import ../output/html

proc runRanking*(characters: seq[CharacterData], format: string, output: string) =
  ## Display stat total ranking.
  if characters.len == 0:
    echo "No characters found."
    return

  # Sort by stat sum descending
  var sortedChars = characters
  sortedChars.sort(proc (a, b: CharacterData): int =
    return statSum(b) - statSum(a)
  )

  case format
  of "csv":
    let headers = @["rank", "id", "name", "type", "sum",
                     "hp", "attack", "defense", "speed", "intelligence", "spirit"]
    var rows: seq[seq[string]] = @[]
    for i, c in sortedChars:
      rows.add(@[
        $(i + 1), c.id, c.name, typeLabel(c.`type`, c.secondary),
        $statSum(c),
        $c.stats.hp, $c.stats.attack, $c.stats.defense,
        $c.stats.speed, $c.stats.intelligence, $c.stats.spirit
      ])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Stat Ranking")
    html &= "<h1>Stat Total Ranking</h1>\n"
    html &= "<p>Total: " & $characters.len & " characters</p>\n"
    
    let headers = @["Rank", "ID", "Name", "Type", "Sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR"]
    var rows: seq[seq[string]] = @[]
    for i, c in sortedChars:
      rows.add(@[
        $(i + 1), c.id, c.name, typeLabel(c.`type`, c.secondary),
        $statSum(c),
        $c.stats.hp, $c.stats.attack, $c.stats.defense,
        $c.stats.speed, $c.stats.intelligence, $c.stats.spirit
      ])
    html &= htmlTable(headers, rows)
    html &= htmlFooter()
    
    if output.len > 0:
      writeHTML(output, html)
    else:
      echo html
  
  else: # table
    var table = newTableOutput(
      @["Rank", "ID", "Name", "Type", "Sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR"],
      @[4, 18, 6, 12, 4, 3, 3, 3, 3, 3, 3]
    )
    for i, c in sortedChars:
      table.addRow(@[
        $(i + 1), c.id, c.name, typeLabel(c.`type`, c.secondary),
        $statSum(c),
        $c.stats.hp, $c.stats.attack, $c.stats.defense,
        $c.stats.speed, $c.stats.intelligence, $c.stats.spirit
      ])
    printTable(table)
    echo "\nTotal: ", characters.len, " characters"
