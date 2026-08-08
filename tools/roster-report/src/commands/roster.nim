## Roster command - character roster table.
import std/[strutils, tables]
import ../parser/character
import ../parser/move
import ../output/table
import ../output/csv
import ../output/html

proc runRoster*(characters: seq[CharacterData], moves: seq[MoveData],
                format: string, output: string) =
  ## Display character roster table.
  if characters.len == 0:
    echo "No characters found."
    return

  let movePowerMap = getMovePowerMap(moves)
  
  case format
  of "csv":
    let headers = @["id", "name", "type", "secondary", "sum",
                     "hp", "attack", "defense", "speed", "intelligence", "spirit", "moves"]
    var rows: seq[seq[string]] = @[]
    for c in characters:
      var moveStrs: seq[string] = @[]
      for m in c.moves:
        if movePowerMap.hasKey(m):
          moveStrs.add(m & "(" & $movePowerMap[m] & ")")
        else:
          moveStrs.add(m & "(?)")
      rows.add(@[
        c.id, c.name, typeLabel(c.`type`, c.secondary),
        $statSum(c),
        $c.stats.hp, $c.stats.attack, $c.stats.defense,
        $c.stats.speed, $c.stats.intelligence, $c.stats.spirit,
        moveStrs.join(", ")
      ])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Character Roster")
    html &= "<h1>Character Roster</h1>\n"
    html &= "<p>Total: " & $characters.len & " characters</p>\n"
    
    let headers = @["ID", "Name", "Type", "Sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR", "Moves"]
    var rows: seq[seq[string]] = @[]
    for c in characters:
      var moveStrs: seq[string] = @[]
      for m in c.moves:
        if movePowerMap.hasKey(m):
          moveStrs.add(m & "(" & $movePowerMap[m] & ")")
        else:
          moveStrs.add(m & "(?)")
      rows.add(@[
        c.id, c.name, typeLabel(c.`type`, c.secondary),
        $statSum(c),
        $c.stats.hp, $c.stats.attack, $c.stats.defense,
        $c.stats.speed, $c.stats.intelligence, $c.stats.spirit,
        moveStrs.join(", ")
      ])
    html &= htmlTable(headers, rows)
    html &= htmlFooter()
    
    if output.len > 0:
      writeHTML(output, html)
    else:
      echo html
  
  else: # table
    var table = newTableOutput(
      @["ID", "Name", "Type", "Sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR"],
      @[18, 6, 12, 4, 3, 3, 3, 3, 3, 3]
    )
    for c in characters:
      table.addRow(@[
        c.id, c.name, typeLabel(c.`type`, c.secondary),
        $statSum(c),
        $c.stats.hp, $c.stats.attack, $c.stats.defense,
        $c.stats.speed, $c.stats.intelligence, $c.stats.spirit
      ])
    printTable(table)
    echo "\nTotal: ", characters.len, " characters"
