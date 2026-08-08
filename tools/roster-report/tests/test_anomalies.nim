## Unit tests for anomaly detection rules.
import std/[unittest, strutils]
import ../src/parser/character
import ../src/parser/move
import ../src/commands/anomalies

proc validStats(): Stats =
  ## Return stats that satisfy all character stat rules.
  return Stats(hp: 100, attack: 80, defense: 70, speed: 90,
               intelligence: 85, spirit: 75)

proc validCharacter(id = "test_char", name = "テスト", `type` = 0,
                    moves: seq[string] = @["fire_strike", "water_surge",
                                           "earth_barrier", "metal_slash"]): CharacterData =
  ## Return a character that passes all domain rules.
  return CharacterData(
    id: id,
    name: name,
    `type`: `type`,
    secondary: -1,
    stats: validStats(),
    moves: moves,
  )

proc validMove(id = "fire_strike", name = "炎撃", `type` = 1,
               power = 80): MoveData =
  ## Return a move that passes all domain rules.
  return MoveData(
    id: id,
    name: name,
    `type`: `type`,
    power: power,
    accuracy: 95,
    effect: 1,
    effectChance: 30,
    statModStat: -1,
    statModStage: 0,
    hitCount: 1,
    recoil: 0,
    healing: 0,
    damageCategory: 0,
  )

proc severityCount(anomalies: seq[Anomaly], severity: string): int =
  ## Count anomalies with the given severity.
  for anomaly in anomalies:
    if anomaly.severity == severity:
      inc result

proc hasAnomaly(anomalies: seq[Anomaly], substring: string): bool =
  ## Return true when any anomaly message contains the substring.
  for anomaly in anomalies:
    if anomaly.message.contains(substring):
      return true
  return false

suite "anomalies.nim - valid data":
  test "no anomalies for valid characters and moves":
    let chars = @[validCharacter(), validCharacter(id = "test_char2")]
    let moves = @[
      validMove(),
      validMove(id = "water_surge", name = "水撃", `type` = 4),
      validMove(id = "earth_barrier", name = "土壁", `type` = 2, power = 0),
      validMove(id = "metal_slash", name = "斬鉄", `type` = 3),
    ]
    let anomalies = detectAnomalies(chars, moves)
    check anomalies.len == 0

suite "anomalies.nim - character ID and name":
  test "duplicate character IDs detected":
    let chars = @[validCharacter(), validCharacter()]
    let anomalies = detectAnomalies(chars, @[])
    check hasAnomaly(anomalies, "Duplicate character ID")

  test "invalid ID format detected":
    let chars = @[validCharacter(id = "Bad-ID")]
    let anomalies = detectAnomalies(chars, @[])
    check hasAnomaly(anomalies, "Invalid ID format")

  test "empty name detected":
    let chars = @[validCharacter(name = "")]
    let anomalies = detectAnomalies(chars, @[])
    check hasAnomaly(anomalies, "Name must be 1-20 characters")

suite "anomalies.nim - character stats":
  test "stat below minimum detected":
    var character = validCharacter()
    character.stats.hp = 0
    let anomalies = detectAnomalies(@[character], @[])
    check hasAnomaly(anomalies, "hp must be in range [1, 999]")

  test "stat above individual maximum detected":
    var character = validCharacter()
    character.stats.attack = 1000
    let anomalies = detectAnomalies(@[character], @[])
    check hasAnomaly(anomalies, "attack must be in range [1, 999]")

  test "stat above soft cap detected":
    var character = validCharacter()
    character.stats.defense = 600
    let anomalies = detectAnomalies(@[character], @[])
    check hasAnomaly(anomalies, "defense exceeds maximum of 500")

  test "stat sum above maximum detected":
    var character = validCharacter()
    character.stats.hp = 1000
    character.stats.attack = 1000
    character.stats.defense = 1000
    character.stats.speed = 100
    character.stats.intelligence = 100
    character.stats.spirit = 100
    let anomalies = detectAnomalies(@[character], @[])
    check hasAnomaly(anomalies, "Stat sum")

suite "anomalies.nim - character types":
  test "invalid primary type detected":
    let chars = @[validCharacter(`type` = 7)]
    let anomalies = detectAnomalies(chars, @[])
    check hasAnomaly(anomalies, "Invalid primary type")

  test "invalid secondary type detected":
    var character = validCharacter()
    character.secondary = 9
    let anomalies = detectAnomalies(@[character], @[])
    check hasAnomaly(anomalies, "Invalid secondary type")

  test "secondary same as primary detected":
    var character = validCharacter(`type` = 2)
    character.secondary = 2
    let anomalies = detectAnomalies(@[character], @[])
    check hasAnomaly(anomalies, "Secondary type same as primary")

suite "anomalies.nim - character moves":
  test "wrong move count detected":
    let chars = @[validCharacter(moves = @["fire_strike"])]
    let anomalies = detectAnomalies(chars, @[validMove()])
    check hasAnomaly(anomalies, "Must have exactly 4 moves")

  test "undefined move reference detected":
    let chars = @[validCharacter(moves = @["fire_strike", "missing_move",
                                           "earth_barrier", "metal_slash"])]
    let anomalies = detectAnomalies(chars, @[validMove()])
    check hasAnomaly(anomalies, "References undefined move")

  test "duplicate move reference detected":
    let chars = @[validCharacter(moves = @["fire_strike", "fire_strike",
                                           "earth_barrier", "metal_slash"])]
    let anomalies = detectAnomalies(chars, @[validMove()])
    check hasAnomaly(anomalies, "Duplicate move reference")

  test "missing damaging move detected":
    let chars = @[validCharacter(moves = @["fire_strike", "fire_strike",
                                           "earth_barrier", "metal_slash"])]
    let anomalies = detectAnomalies(chars, @[validMove(power = 0)])
    check hasAnomaly(anomalies, "at least one move with power > 0")

suite "anomalies.nim - move fields":
  test "duplicate move IDs detected":
    let moves = @[validMove(), validMove()]
    let anomalies = detectAnomalies(@[], moves)
    check hasAnomaly(anomalies, "Duplicate move ID")

  test "invalid move type detected":
    let moves = @[validMove(`type` = 99)]
    let anomalies = detectAnomalies(@[], moves)
    check hasAnomaly(anomalies, "Invalid move type")

  test "power out of range detected":
    let moves = @[validMove(power = 300)]
    let anomalies = detectAnomalies(@[], moves)
    check hasAnomaly(anomalies, "Power must be in range [0, 255]")

  test "accuracy out of range detected":
    var moveData = validMove()
    moveData.accuracy = 0
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Accuracy must be in range [1, 100]")

  test "invalid effect type detected":
    var moveData = validMove()
    moveData.effect = 6
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Invalid effect type")

  test "effect chance without effect detected":
    var moveData = validMove()
    moveData.effect = 0
    moveData.effectChance = 30
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Effect chance must be 0 when effect is None")

  test "effect without chance detected":
    var moveData = validMove()
    moveData.effectChance = 0
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Effect chance must be > 0 when effect is not None")

  test "stat mod stage out of range detected":
    var moveData = validMove()
    moveData.statModStat = 0
    moveData.statModStage = 5
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Stat mod stage must be in range [-3, 3]")

  test "hit count out of range detected":
    var moveData = validMove()
    moveData.hitCount = 6
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Hit count must be in range [1, 5]")

  test "recoil without power detected":
    var moveData = validMove(power = 0)
    moveData.recoil = 50
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Recoil requires power > 0")

  test "healing out of range detected":
    var moveData = validMove()
    moveData.healing = 150
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Healing must be in range [0, 100]")

  test "invalid damage category detected":
    var moveData = validMove()
    moveData.damageCategory = 5
    let anomalies = detectAnomalies(@[], @[moveData])
    check hasAnomaly(anomalies, "Invalid damage category")

  test "invalid move ID format detected":
    let moves = @[validMove(id = "Fire-Strike")]
    let anomalies = detectAnomalies(@[], moves)
    check hasAnomaly(anomalies, "Invalid ID format")

suite "anomalies.nim - unreferenced moves":
  test "unreferenced move is a warning":
    let moves = @[validMove(id = "unused_move")]
    let anomalies = detectAnomalies(@[], moves)
    check hasAnomaly(anomalies, "Move is not referenced by any character")
    check severityCount(anomalies, "warning") >= 1

when isMainModule:
  echo "Running anomaly tests..."
