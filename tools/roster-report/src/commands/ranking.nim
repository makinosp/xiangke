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
  sortedChars.sort(proc (charA, charB: CharacterData): int =
    return statSum(charB) - statSum(charA)
  )

  case format
  of "csv":
    let headers = @["rank", "id", "name", "type", "sum",
                     "hp", "attack", "defense", "speed", "intelligence", "spirit"]
    var rows: seq[seq[string]] = @[]
    for rank, character in sortedChars:
      rows.add(@[
        $(rank + 1), character.id, character.name, typeLabel(character.`type`, character.secondary),
        $statSum(character),
        $character.stats.hp, $character.stats.attack, $character.stats.defense,
        $character.stats.speed, $character.stats.intelligence, $character.stats.spirit
      ])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Stat Ranking")
    html &= "<h1>Stat Total Ranking</h1>\n"
    html &= "<p>Total: " & $characters.len & " characters</p>\n"
    
    let headers = @["Rank", "ID", "Name", "Type", "Sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR"]
    var rows: seq[seq[string]] = @[]
    for rank, character in sortedChars:
      rows.add(@[
        $(rank + 1), character.id, character.name, typeLabel(character.`type`, character.secondary),
        $statSum(character),
        $character.stats.hp, $character.stats.attack, $character.stats.defense,
        $character.stats.speed, $character.stats.intelligence, $character.stats.spirit
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
    for rank, character in sortedChars:
      table.addRow(@[
        $(rank + 1), character.id, character.name, typeLabel(character.`type`, character.secondary),
        $statSum(character),
        $character.stats.hp, $character.stats.attack, $character.stats.defense,
        $character.stats.speed, $character.stats.intelligence, $character.stats.spirit
      ])
    printTable(table)
    echo "\nTotal: ", characters.len, " characters"
