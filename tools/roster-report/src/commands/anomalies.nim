## Anomalies command - detect data anomalies.
import std/[sets]
import ../constants
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
  for moveEntry in moves:
    moveIds.incl(moveEntry.id)
  
  # Check characters
  for character in characters:
    # Check stat sum limit
    let total = statSum(character)
    if total > MAX_STAT_SUM:
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Stat sum exceeds " & $MAX_STAT_SUM & ": " & $total
      ))
    
    # Check individual stat limits
    if character.stats.hp > SOFT_STAT_CAP:
      result.add(Anomaly(
        severity: "warning",
        entity: character.id,
        message: "HP exceeds " & $SOFT_STAT_CAP & ": " & $character.stats.hp
      ))
    if character.stats.attack > SOFT_STAT_CAP:
      result.add(Anomaly(
        severity: "warning",
        entity: character.id,
        message: "Attack exceeds " & $SOFT_STAT_CAP & ": " & $character.stats.attack
      ))
    if character.stats.defense > SOFT_STAT_CAP:
      result.add(Anomaly(
        severity: "warning",
        entity: character.id,
        message: "Defense exceeds " & $SOFT_STAT_CAP & ": " & $character.stats.defense
      ))
    if character.stats.speed > SOFT_STAT_CAP:
      result.add(Anomaly(
        severity: "warning",
        entity: character.id,
        message: "Speed exceeds " & $SOFT_STAT_CAP & ": " & $character.stats.speed
      ))
    if character.stats.intelligence > SOFT_STAT_CAP:
      result.add(Anomaly(
        severity: "warning",
        entity: character.id,
        message: "Intelligence exceeds " & $SOFT_STAT_CAP & ": " & $character.stats.intelligence
      ))
    if character.stats.spirit > SOFT_STAT_CAP:
      result.add(Anomaly(
        severity: "warning",
        entity: character.id,
        message: "Spirit exceeds " & $SOFT_STAT_CAP & ": " & $character.stats.spirit
      ))
    
    # Check move count
    if character.moves.len != REQUIRED_MOVE_COUNT:
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Move count is " & $character.moves.len & ", expected " & $REQUIRED_MOVE_COUNT
      ))
    
    # Check for undefined move references
    for moveId in character.moves:
      if not moveIds.contains(moveId):
        result.add(Anomaly(
          severity: "error",
          entity: character.id,
          message: "References undefined move: " & moveId
        ))
    
    # Check for at least one damaging move
    var hasDamagingMove = false
    for moveRef in character.moves:
      for moveEntry in moves:
        if moveEntry.id == moveRef and moveEntry.power > 0:
          hasDamagingMove = true
          break
      if hasDamagingMove:
        break
    if not hasDamagingMove:
      result.add(Anomaly(
        severity: "warning",
        entity: character.id,
        message: "No damaging moves"
      ))

  # Check for duplicate move IDs
  var seenMoves = initHashSet[string]()
  for moveEntry in moves:
    if seenMoves.contains(moveEntry.id):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Duplicate move ID"
      ))
    seenMoves.incl(moveEntry.id)

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
    for anomaly in anomalies:
      rows.add(@[anomaly.severity, anomaly.entity, anomaly.message])
    printCSV(headers, rows)
  
  of "html":
    var html = htmlHeader("Data Anomalies")
    html &= "<h1>Data Anomalies</h1>\n"
    html &= "<p>Found " & $anomalies.len & " anomalies</p>\n"
    
    let headers = @["Severity", "Entity", "Message"]
    var rows: seq[seq[string]] = @[]
    for anomaly in anomalies:
      rows.add(@[anomaly.severity, anomaly.entity, anomaly.message])
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
    for anomaly in anomalies:
      table.addRow(@[anomaly.severity, anomaly.entity, anomaly.message])
    printTable(table)
    echo "\nFound ", anomalies.len, " anomalies"
