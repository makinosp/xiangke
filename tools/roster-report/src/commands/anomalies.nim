## Anomalies command - detect data anomalies.
import std/[sets]
import ../parser/character
import ../parser/move
import ../output/table
import ../output/csv
import ../output/html

type
  Anomaly* = object
    severity*: string  ## "error" or "warning"
    entity*: string
    message*: string

proc detectAnomalies*(characters: seq[CharacterData],
                      moves: seq[MoveData]): seq[Anomaly] =
  ## Detect anomalies in game data.
  result = @[]
  
  # Build move ID set for reference checking
  var moveIds = initHashSet[string]()
  for m in moves:
    moveIds.incl(m.id)
  
  # Check characters
  for c in characters:
    # Check stat sum limit (max 3000)
    let total = statSum(c)
    if total > 3000:
      result.add(Anomaly(
        severity: "error",
        entity: c.id,
        message: "Stat sum exceeds 3000: " & $total
      ))
    
    # Check individual stat limits (max 500)
    if c.stats.hp > 500:
      result.add(Anomaly(
        severity: "warning",
        entity: c.id,
        message: "HP exceeds 500: " & $c.stats.hp
      ))
    if c.stats.attack > 500:
      result.add(Anomaly(
        severity: "warning",
        entity: c.id,
        message: "Attack exceeds 500: " & $c.stats.attack
      ))
    if c.stats.defense > 500:
      result.add(Anomaly(
        severity: "warning",
        entity: c.id,
        message: "Defense exceeds 500: " & $c.stats.defense
      ))
    if c.stats.speed > 500:
      result.add(Anomaly(
        severity: "warning",
        entity: c.id,
        message: "Speed exceeds 500: " & $c.stats.speed
      ))
    if c.stats.intelligence > 500:
      result.add(Anomaly(
        severity: "warning",
        entity: c.id,
        message: "Intelligence exceeds 500: " & $c.stats.intelligence
      ))
    if c.stats.spirit > 500:
      result.add(Anomaly(
        severity: "warning",
        entity: c.id,
        message: "Spirit exceeds 500: " & $c.stats.spirit
      ))
    
    # Check move count (should be exactly 4)
    if c.moves.len != 4:
      result.add(Anomaly(
        severity: "error",
        entity: c.id,
        message: "Move count is " & $c.moves.len & ", expected 4"
      ))
    
    # Check for undefined move references
    for m in c.moves:
      if not moveIds.contains(m):
        result.add(Anomaly(
          severity: "error",
          entity: c.id,
          message: "References undefined move: " & m
        ))
    
    # Check for at least one damaging move
    var hasDamagingMove = false
    for mId in c.moves:
      for m in moves:
        if m.id == mId and m.power > 0:
          hasDamagingMove = true
          break
      if hasDamagingMove:
        break
    if not hasDamagingMove:
      result.add(Anomaly(
        severity: "warning",
        entity: c.id,
        message: "No damaging moves"
      ))

  # Check for duplicate move IDs
  var seenMoves = initHashSet[string]()
  for m in moves:
    if seenMoves.contains(m.id):
      result.add(Anomaly(
        severity: "error",
        entity: m.id,
        message: "Duplicate move ID"
      ))
    seenMoves.incl(m.id)

proc runAnomalies*(characters: seq[CharacterData], moves: seq[MoveData],
                   format: string, output: string) =
  ## Display detected anomalies.
  let anomalies = detectAnomalies(characters, moves)
  
  if anomalies.len == 0:
    echo "No anomalies detected."
    return
  
  case format
  of "csv":
    let headers = @["severity", "entity", "message"]
    var rows: seq[seq[string]] = @[]
    for a in anomalies:
      rows.add(@[a.severity, a.entity, a.message])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Data Anomalies")
    html &= "<h1>Data Anomalies</h1>\n"
    html &= "<p>Found " & $anomalies.len & " anomalies</p>\n"
    
    let headers = @["Severity", "Entity", "Message"]
    var rows: seq[seq[string]] = @[]
    for a in anomalies:
      rows.add(@[a.severity, a.entity, a.message])
    html &= htmlTable(headers, rows)
    html &= htmlFooter()
    
    if output.len > 0:
      writeHTML(output, html)
    else:
      echo html
  
  else: # table
    echo "=== Data Anomalies ==="
    var table = newTableOutput(
      @["Severity", "Entity", "Message"],
      @[10, 18, 50]
    )
    for a in anomalies:
      table.addRow(@[a.severity, a.entity, a.message])
    printTable(table)
    echo "\nFound ", anomalies.len, " anomalies"
