## Roster command - character roster table.
import std/[strutils, tables]
import ../labels
import ../parser/character
import ../parser/move
import ../output/table
import ../output/csv
import ../output/html

proc runRoster*(characters: seq[CharacterData], moves: seq[MoveData],
                format: string, output: string): bool =
  ## Display character roster table. Returns false when output fails.
  if characters.len == 0:
    echo "No characters found."
    return true

  let movePowerMap = getMovePowerMap(moves)
  
  case format
  of "csv":
    let headers = @["id", "name", "type", "secondary", "sum",
                     "hp", "attack", "defense", "speed", "intelligence", "spirit", "moves"]
    var rows: seq[seq[string]] = @[]
    for character in characters:
      var moveStrs: seq[string] = @[]
      for moveId in character.moves:
        if movePowerMap.hasKey(moveId):
          moveStrs.add(moveId & "(" & $movePowerMap[moveId] & ")")
        else:
          moveStrs.add(moveId & "(?)")
      let secondaryLabel = if character.secondary >= 0:
        moveTypeLabel(character.secondary)
      else:
        ""
      rows.add(@[
        character.id, character.name, moveTypeLabel(character.`type`), secondaryLabel,
        $statSum(character),
        $character.stats.hp, $character.stats.attack, $character.stats.defense,
        $character.stats.speed, $character.stats.intelligence, $character.stats.spirit,
        moveStrs.join(", ")
      ])
    return writeCSV(headers, rows, output)
  
  of "html":
    var html = htmlHeader("Character Roster")
    html &= "<h1>Character Roster</h1>\n"
    html &= "<p>Total: " & $characters.len & " characters</p>\n"
    
    let headers = @["ID", "Name", "Type", "Sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR", "Moves"]
    var rows: seq[seq[string]] = @[]
    for character in characters:
      var moveStrs: seq[string] = @[]
      for moveId in character.moves:
        if movePowerMap.hasKey(moveId):
          moveStrs.add(moveId & "(" & $movePowerMap[moveId] & ")")
        else:
          moveStrs.add(moveId & "(?)")
      rows.add(@[
        character.id, character.name, typeLabel(character.`type`, character.secondary),
        $statSum(character),
        $character.stats.hp, $character.stats.attack, $character.stats.defense,
        $character.stats.speed, $character.stats.intelligence, $character.stats.spirit,
        moveStrs.join(", ")
      ])
    html &= htmlTable(headers, rows)
    html &= htmlFooter()
    
    if output.len > 0:
      return writeHTML(output, html)
    else:
      echo html
      return true
  
  else: # table
    var table = newTableOutput(
      @["ID", "Name", "Type", "Sum", "HP", "ATK", "DEF", "SPD", "INT", "SPR"],
      @[18, 6, 12, 4, 3, 3, 3, 3, 3, 3]
    )
    for character in characters:
      table.addRow(@[
        character.id, character.name, typeLabel(character.`type`, character.secondary),
        $statSum(character),
        $character.stats.hp, $character.stats.attack, $character.stats.defense,
        $character.stats.speed, $character.stats.intelligence, $character.stats.spirit
      ])
    if output.len > 0:
      return writeTableFile(table, output)
    else:
      printTable(table)
      echo "\nTotal: ", characters.len, " characters"
      return true
