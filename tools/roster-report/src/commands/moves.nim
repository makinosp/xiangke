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
    for m in moves:
      let catLabel = if m.damageCategory >= 0 and m.damageCategory < CATEGORIES.len:
        CATEGORIES[m.damageCategory]
      else:
        "?"
      rows.add(@[
        m.id, m.name, TYPES[m.`type`], $m.power, $m.accuracy,
        $m.effect, $m.effectChance, catLabel,
        $m.hitCount, $m.recoil, $m.healing
      ])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Move List")
    html &= "<h1>Move Assignment List</h1>\n"
    html &= "<p>Total: " & $moves.len & " moves</p>\n"
    
    let headers = @["ID", "Name", "Type", "Power", "Accuracy", "Effect", "Category"]
    var rows: seq[seq[string]] = @[]
    for m in moves:
      let catLabel = if m.damageCategory >= 0 and m.damageCategory < CATEGORIES.len:
        CATEGORIES[m.damageCategory]
      else:
        "?"
      rows.add(@[
        m.id, m.name, TYPES[m.`type`], $m.power, $m.accuracy,
        $m.effect, catLabel
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
    for m in moves:
      let catLabel = if m.damageCategory >= 0 and m.damageCategory < CATEGORIES.len:
        CATEGORIES[m.damageCategory]
      else:
        "?"
      table.addRow(@[
        m.id, m.name, TYPES[m.`type`], $m.power, $m.accuracy,
        $m.effect, catLabel
      ])
    printTable(table)
    echo "\nTotal: ", moves.len, " moves"
