## Moves command - move assignment list.
import ../parser/character
import ../parser/move
import ../output/table
import ../output/csv
import ../output/html

const CATEGORIES = ["Physical", "Arts"]

proc runMoves*(moves: seq[MoveData], format: string, output: string) =
  ## Display move assignment list.
  if moves.len == 0:
    echo "No moves found."
    return

  case format
  of "csv":
    let headers = @["id", "name", "type", "power", "accuracy", "effect",
                     "effect_chance", "category", "hit_count", "recoil", "healing"]
    var rows: seq[seq[string]] = @[]
    for moveData in moves:
      let catLabel = if moveData.damageCategory >= 0 and moveData.damageCategory < CATEGORIES.len:
        CATEGORIES[moveData.damageCategory]
      else:
        "?"
      rows.add(@[
        moveData.id, moveData.name, TYPES[moveData.`type`], $moveData.power, $moveData.accuracy,
        $moveData.effect, $moveData.effectChance, catLabel,
        $moveData.hitCount, $moveData.recoil, $moveData.healing
      ])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Move List")
    html &= "<h1>Move Assignment List</h1>\n"
    html &= "<p>Total: " & $moves.len & " moves</p>\n"
    
    let headers = @["ID", "Name", "Type", "Power", "Accuracy", "Effect", "Category"]
    var rows: seq[seq[string]] = @[]
    for moveData in moves:
      let catLabel = if moveData.damageCategory >= 0 and moveData.damageCategory < CATEGORIES.len:
        CATEGORIES[moveData.damageCategory]
      else:
        "?"
      rows.add(@[
        moveData.id, moveData.name, TYPES[moveData.`type`], $moveData.power, $moveData.accuracy,
        $moveData.effect, catLabel
      ])
    html &= htmlTable(headers, rows)
    html &= htmlFooter()
    
    if output.len > 0:
      writeHTML(output, html)
    else:
      echo html
  
  else: # table
    var table = newTableOutput(
      @["ID", "Name", "Type", "Power", "Acc", "Effect", "Category"],
      @[14, 12, 8, 5, 4, 6, 10]
    )
    for moveData in moves:
      let catLabel = if moveData.damageCategory >= 0 and moveData.damageCategory < CATEGORIES.len:
        CATEGORIES[moveData.damageCategory]
      else:
        "?"
      table.addRow(@[
        moveData.id, moveData.name, TYPES[moveData.`type`], $moveData.power, $moveData.accuracy,
        $moveData.effect, catLabel
      ])
    printTable(table)
    echo "\nTotal: ", moves.len, " moves"
