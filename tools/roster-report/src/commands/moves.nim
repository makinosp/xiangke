## Moves command - move assignment list.
import ../labels
import ../parser/move
import ../output/table
import ../output/csv
import ../output/html

proc runMoves*(moves: seq[MoveData], format: string, output: string): bool =
  ## Display move assignment list. Returns false when output fails.
  if moves.len == 0:
    echo "No moves found."
    return true

  case format
  of "csv":
    let headers = @["id", "name", "type", "power", "accuracy", "effect",
                     "effect_chance", "category", "hit_count", "recoil", "healing"]
    var rows: seq[seq[string]] = @[]
    for moveData in moves:
      rows.add(@[
        moveData.id, moveData.name, moveTypeLabel(moveData.`type`), $moveData.power, $moveData.accuracy,
        $moveData.effect, $moveData.effectChance, categoryLabel(moveData.damageCategory),
        $moveData.hitCount, $moveData.recoil, $moveData.healing
      ])
    return writeCSV(headers, rows, output)
  
  of "html":
    var html = htmlHeader("Move List")
    html &= "<h1>Move Assignment List</h1>\n"
    html &= "<p>Total: " & $moves.len & " moves</p>\n"
    
    let headers = @["ID", "Name", "Type", "Power", "Accuracy", "Effect", "Category"]
    var rows: seq[seq[string]] = @[]
    for moveData in moves:
      rows.add(@[
        moveData.id, moveData.name, moveTypeLabel(moveData.`type`), $moveData.power, $moveData.accuracy,
        $moveData.effect, categoryLabel(moveData.damageCategory)
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
      @["ID", "Name", "Type", "Power", "Acc", "Effect", "Category"],
      @[14, 12, 8, 5, 4, 6, 10]
    )
    for moveData in moves:
      table.addRow(@[
        moveData.id, moveData.name, moveTypeLabel(moveData.`type`), $moveData.power, $moveData.accuracy,
        $moveData.effect, categoryLabel(moveData.damageCategory)
      ])
    if output.len > 0:
      return writeTableFile(table, output)
    else:
      printTable(table)
      echo "\nTotal: ", moves.len, " moves"
      return true
