## Anomalies command - detect data anomalies.
## Validation rules mirror `extensions/core/src/validator.rs` (MR-* for moves,
## CR-* for characters) plus cross-entity checks such as duplicate IDs and
## unreferenced moves.
import std/[sets, tables]
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

proc isValidIdFormat*(id: string): bool =
  ## Validate lowercase snake_case ID format (mirrors Rust validator).
  if id.len == 0 or id.len > MAX_ID_LENGTH:
    return false
  if not (id[0] in {'a'..'z'}):
    return false
  for c in id:
    if not (c in {'a'..'z', '0'..'9', '_'}):
      return false
  return true

proc isInRange(value, minVal, maxVal: int): bool =
  ## Return true when value is within the inclusive range.
  return value >= minVal and value <= maxVal

proc detectAnomalies*(characters: seq[CharacterData],
                      moves: seq[MoveData]): seq[Anomaly] =
  ## Detect anomalies in game data.
  result = @[]
  
  # Move ID set and power lookup used for reference checks.
  var moveIds = initHashSet[string]()
  var movePowerMap = initTable[string, int]()
  var seenMoveIds = initHashSet[string]()

  # --- Move validation (MR rules) ---
  for moveEntry in moves:
    if seenMoveIds.contains(moveEntry.id):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Duplicate move ID: " & moveEntry.id
      ))
    seenMoveIds.incl(moveEntry.id)
    moveIds.incl(moveEntry.id)
    movePowerMap[moveEntry.id] = moveEntry.power

    # MR-1: ID format and name length
    if not isValidIdFormat(moveEntry.id):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Invalid ID format (must be lowercase snake_case): " & moveEntry.id
      ))
    if moveEntry.name.len == 0 or moveEntry.name.len > MAX_NAME_LENGTH:
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Name must be 1-" & $MAX_NAME_LENGTH & " characters"
      ))

    # MR-2: Power and accuracy
    if not isInRange(moveEntry.power, 0, MAX_POWER):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Power must be in range [0, " & $MAX_POWER & "], got " & $moveEntry.power
      ))
    if not isInRange(moveEntry.accuracy, 1, MAX_ACCURACY):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Accuracy must be in range [1, " & $MAX_ACCURACY & "], got " & $moveEntry.accuracy
      ))

    # MR-3: Effect type and chance
    if not isInRange(moveEntry.effect, 0, EFFECT_COUNT - 1):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Invalid effect type: " & $moveEntry.effect
      ))
    if not isInRange(moveEntry.effectChance, 0, MAX_EFFECT_CHANCE):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Effect chance must be in range [0, " & $MAX_EFFECT_CHANCE & "], got " &
          $moveEntry.effectChance
      ))
    if moveEntry.effect == 0 and moveEntry.effectChance != 0:
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Effect chance must be 0 when effect is None"
      ))
    if moveEntry.effect != 0 and moveEntry.effectChance == 0:
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Effect chance must be > 0 when effect is not None"
      ))

    # MR-4: Stat modification
    if moveEntry.statModStat >= 0 and moveEntry.statModStage != 0:
      if not isInRange(moveEntry.statModStat, 0, STAT_MOD_STAT_COUNT - 1):
        result.add(Anomaly(
          severity: "error",
          entity: moveEntry.id,
          message: "Invalid stat for modification: " & $moveEntry.statModStat
        ))
      if not isInRange(moveEntry.statModStage, -MAX_STAT_MOD_STAGE, MAX_STAT_MOD_STAGE):
        result.add(Anomaly(
          severity: "error",
          entity: moveEntry.id,
          message: "Stat mod stage must be in range [-" & $MAX_STAT_MOD_STAGE & ", " &
            $MAX_STAT_MOD_STAGE & "], got " & $moveEntry.statModStage
        ))

    # MR-5: Hit count
    if not isInRange(moveEntry.hitCount, 1, MAX_HIT_COUNT):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Hit count must be in range [1, " & $MAX_HIT_COUNT & "], got " &
          $moveEntry.hitCount
      ))

    # MR-6: Recoil
    if not isInRange(moveEntry.recoil, 0, MAX_RECOIL):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Recoil must be in range [0, " & $MAX_RECOIL & "], got " & $moveEntry.recoil
      ))
    if moveEntry.recoil > 0 and moveEntry.power == 0:
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Recoil requires power > 0"
      ))

    # MR-7: Healing
    if not isInRange(moveEntry.healing, 0, MAX_HEALING):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Healing must be in range [0, " & $MAX_HEALING & "], got " & $moveEntry.healing
      ))

    # MR-10: Type validity
    if not isInRange(moveEntry.`type`, 0, TYPE_COUNT - 1):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Invalid move type: " & $moveEntry.`type`
      ))

    # Damage category validity
    if not isInRange(moveEntry.damageCategory, 0, CATEGORY_COUNT - 1):
      result.add(Anomaly(
        severity: "error",
        entity: moveEntry.id,
        message: "Invalid damage category: " & $moveEntry.damageCategory
      ))

  # --- Character validation (CR rules) ---
  var seenCharacterIds = initHashSet[string]()
  var referencedMoveIds = initHashSet[string]()

  for character in characters:
    # CR-1: ID uniqueness, format, and name length
    if seenCharacterIds.contains(character.id):
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Duplicate character ID: " & character.id
      ))
    seenCharacterIds.incl(character.id)
    if not isValidIdFormat(character.id):
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Invalid ID format (must be lowercase snake_case): " & character.id
      ))
    if character.name.len == 0 or character.name.len > MAX_NAME_LENGTH:
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Name must be 1-" & $MAX_NAME_LENGTH & " characters"
      ))

    # CR-2: Stats
    let statNames = ["hp", "attack", "defense", "speed", "intelligence", "spirit"]
    let statValues = [character.stats.hp, character.stats.attack, character.stats.defense,
                      character.stats.speed, character.stats.intelligence,
                      character.stats.spirit]
    for statIdx in 0..<statNames.len:
      if not isInRange(statValues[statIdx], MIN_STAT, MAX_INDIVIDUAL_STAT):
        result.add(Anomaly(
          severity: "error",
          entity: character.id,
          message: statNames[statIdx] & " must be in range [" & $MIN_STAT & ", " &
            $MAX_INDIVIDUAL_STAT & "], got " & $statValues[statIdx]
        ))
      if statValues[statIdx] > SOFT_STAT_CAP:
        result.add(Anomaly(
          severity: "error",
          entity: character.id,
          message: statNames[statIdx] & " exceeds maximum of " & $SOFT_STAT_CAP &
            ", got " & $statValues[statIdx]
        ))
    let total = statSum(character)
    if total > MAX_STAT_SUM:
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Stat sum " & $total & " exceeds maximum " & $MAX_STAT_SUM
      ))

    # CR-3: Type assignment
    if not isInRange(character.`type`, 0, TYPE_COUNT - 1):
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Invalid primary type: " & $character.`type`
      ))
    if character.secondary != -1:
      if not isInRange(character.secondary, 0, TYPE_COUNT - 1):
        result.add(Anomaly(
          severity: "error",
          entity: character.id,
          message: "Invalid secondary type: " & $character.secondary
        ))
      elif character.secondary == character.`type`:
        result.add(Anomaly(
          severity: "error",
          entity: character.id,
          message: "Secondary type same as primary (" & $character.`type` & ")"
        ))

    # CR-4: Move assignment
    if character.moves.len != REQUIRED_MOVE_COUNT:
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Must have exactly " & $REQUIRED_MOVE_COUNT & " moves, got " &
          $character.moves.len
      ))

    var seenCharacterMoves = initHashSet[string]()
    var hasDamagingMove = false
    for moveId in character.moves:
      if seenCharacterMoves.contains(moveId):
        result.add(Anomaly(
          severity: "error",
          entity: character.id,
          message: "Duplicate move reference: " & moveId
        ))
      seenCharacterMoves.incl(moveId)
      referencedMoveIds.incl(moveId)
      if not moveIds.contains(moveId):
        result.add(Anomaly(
          severity: "error",
          entity: character.id,
          message: "References undefined move: " & moveId
        ))
      elif movePowerMap[moveId] > 0:
        hasDamagingMove = true
    if not hasDamagingMove and character.moves.len == REQUIRED_MOVE_COUNT:
      result.add(Anomaly(
        severity: "error",
        entity: character.id,
        message: "Must have at least one move with power > 0"
      ))

  # --- Unreferenced moves (warning) ---
  for moveEntry in moves:
    if not referencedMoveIds.contains(moveEntry.id):
      result.add(Anomaly(
        severity: "warning",
        entity: moveEntry.id,
        message: "Move is not referenced by any character: " & moveEntry.id
      ))

proc runAnomalies*(characters: seq[CharacterData], moves: seq[MoveData],
                   format: string,
                   output: string): tuple[reportOk: bool, errorCount: int] =
  ## Display detected anomalies. Returns whether the report was written
  ## successfully and how many error-severity anomalies were found.
  let anomalies = detectAnomalies(characters, moves)

  var errorCount = 0
  for anomaly in anomalies:
    if anomaly.severity == "error":
      inc errorCount

  if anomalies.len == 0:
    echo "No anomalies detected."
    return (true, 0)

  case format
  of "csv":
    let headers = @["severity", "entity", "message"]
    var rows: seq[seq[string]] = @[]
    for anomaly in anomalies:
      rows.add(@[anomaly.severity, anomaly.entity, anomaly.message])
    return (writeCSV(headers, rows, output), errorCount)

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
      return (writeHTML(output, html), errorCount)
    else:
      echo html
      return (true, errorCount)

  else: # table
    echo "=== Data Anomalies ==="
    var table = newTableOutput(
      @["Severity", "Entity", "Message"],
      @[10, 18, 50]
    )
    for anomaly in anomalies:
      table.addRow(@[anomaly.severity, anomaly.entity, anomaly.message])
    if output.len > 0:
      return (writeTableFile(table, output), errorCount)
    else:
      printTable(table)
      echo "\nFound ", anomalies.len, " anomalies"
      return (true, errorCount)
