## Unit tests for the .tres parser modules.
import std/[unittest, os, strutils, tables]
import ../src/diagnostics
import ../src/parser/[tres, character, move, status_effect]

suite "tres.nim - Common parser":
  test "getValue extracts simple value":
    let text = "id = \"test_id\"\nname = \"Test Name\""
    let (value, found) = getValue(text, "id")
    check found == true
    check value == "test_id"

  test "getValue extracts numeric value":
    let text = "hp = 135\nattack = 75"
    let (value, found) = getValue(text, "hp")
    check found == true
    check value == "135"

  test "getValue returns false for missing key":
    let text = "id = \"test\""
    let (_, found) = getValue(text, "missing")
    check found == false

  test "parseIntOr returns default on empty string":
    check parseIntOr("", 42) == 42

  test "parseIntOr parses valid integer":
    check parseIntOr("135", 0) == 135

  test "parseIntOr returns default on invalid input":
    check parseIntOr("abc", 42) == 42

suite "character.nim - Character parser":
  test "parseCharacter extracts all fields":
    let text = """
[resource]
id = "test_char"
name = "テスト"
type = 6
secondary_type = 4
hp = 135
attack = 75
defense = 80
speed = 85
intelligence = 110
spirit = 105
moves = PackedStringArray("move1", "move2", "move3", "move4")
"""
    let character = parseCharacter(text)
    check character.id == "test_char"
    check character.name == "テスト"
    check character.`type` == 6
    check character.secondary == 4
    check character.stats.hp == 135
    check character.stats.attack == 75
    check character.stats.defense == 80
    check character.stats.speed == 85
    check character.stats.intelligence == 110
    check character.stats.spirit == 105
    check character.moves.len == 4
    check character.moves[0] == "move1"
    check character.moves[3] == "move4"

  test "typeLabel returns correct labels":
    check typeLabel(0, -1) == "WOOD"
    check typeLabel(6, 4) == "YIN+WATER"
    check typeLabel(1, -1) == "FIRE"

  test "statSum calculates total":
    let character = CharacterData(
      stats: Stats(hp: 100, attack: 50, defense: 60, speed: 70, intelligence: 80, spirit: 90)
    )
    check statSum(character) == 450

  test "parseCharacter handles missing secondary_type":
    let text = """
id = "no_secondary"
type = 2
"""
    let character = parseCharacter(text)
    check character.secondary == -1

suite "move.nim - Move parser":
  test "parseMove extracts all fields":
    let text = """
[resource]
id = "fire_strike"
name = "炎撃"
type = 1
power = 80
accuracy = 95
effect = 1
effect_chance = 30
stat_mod_stat = -1
stat_mod_stage = 0
hit_count = 1
recoil = 0
healing = 0
damage_category = 0
"""
    let moveData = parseMove(text)
    check moveData.id == "fire_strike"
    check moveData.name == "炎撃"
    check moveData.`type` == 1
    check moveData.power == 80
    check moveData.accuracy == 95
    check moveData.effect == 1
    check moveData.effectChance == 30
    check moveData.hitCount == 1
    check moveData.damageCategory == 0

  test "getMovePowerMap creates correct mapping":
    let moves = @[
      MoveData(id: "fire_strike", power: 80),
      MoveData(id: "water_surge", power: 70),
    ]
    let powerMap = getMovePowerMap(moves)
    check powerMap["fire_strike"] == 80
    check powerMap["water_surge"] == 70

suite "status_effect.nim - Status effect parser":
  test "parseStatusEffect extracts fields":
    let text = """
[resource]
effect_type = 1
name = "Burn"
damage_per_turn = 0.125
escalating = false
stat_mod_stat = 0
stat_mod_multiplier = 0.5
"""
    let se = parseStatusEffect(text)
    check se.effectType == 1
    check se.name == "Burn"
    check se.damagePerTurn == 0.125
    check se.escalating == false
    check se.statModStat == 0
    check se.statModMultiplier == 0.5

  test "effectLabel returns correct labels":
    check effectLabel(0) == "None"
    check effectLabel(1) == "Burn"
    check effectLabel(5) == "Charm"

proc hasAnomalyDiag(diags: seq[Diagnostic], field: string): bool =
  ## Return true when a diagnostic mentions the given field.
  for diag in diags:
    if diag.message.contains(field):
      return true
  return false

proc makeTempDir(name: string): string =
  ## Create a fresh temporary directory for tests.
  let path = getTempDir() / name
  removeDir(path)
  createDir(path)
  return path

suite "diagnostics.nim - parse diagnostics":
  test "parseCharacterDiag reports missing id":
    var diags: seq[Diagnostic] = @[]
    let character = parseCharacterDiag("name = \"No ID\"", "char.tres", diags)
    check character.id.len == 0
    check hasErrors(diags)
    check diags[0].severity == "error"
    check diags[0].message.contains("id")

  test "parseCharacterDiag reports invalid integer":
    let text = "id = \"broken\"\nhp = abc\nattack = 80"
    var diags: seq[Diagnostic] = @[]
    let character = parseCharacterDiag(text, "char.tres", diags)
    check character.stats.hp == 0
    check hasErrors(diags)
    check hasAnomalyDiag(diags, "hp")

  test "parseCharacterDiag warns on missing optional field":
    let text = "id = \"no_secondary\"\ntype = 2\nname = \"Test\""
    var diags: seq[Diagnostic] = @[]
    let character = parseCharacterDiag(text, "char.tres", diags)
    check character.secondary == -1
    check hasAnomalyDiag(diags, "secondary_type")

  test "parseMoveDiag reports invalid integer":
    let text = "id = \"broken\"\npower = abc"
    var diags: seq[Diagnostic] = @[]
    let moveData = parseMoveDiag(text, "move.tres", diags)
    check moveData.power == 0
    check hasErrors(diags)

  test "parseCharacters aggregates diagnostics across files":
    let tmpDir = makeTempDir("roster_parse_agg")
    defer: removeDir(tmpDir)
    let charsDir = tmpDir / "characters"
    createDir(charsDir)
    writeFile(charsDir / "good.tres",
      "id = \"good_char\"\nname = \"Good\"\ntype = 0\nhp = 100\nattack = 80\n")
    writeFile(charsDir / "bad.tres",
      "id = \"bad_char\"\nname = \"Bad\"\ntype = 0\nhp = not_a_number\n")
    let (characters, diags) = parseCharacters(charsDir / "*.tres")
    check characters.len == 2
    check hasErrors(diags)
    check hasAnomalyDiag(diags, "hp")

  test "readTresFileDiag reports unreadable file":
    var diags: seq[Diagnostic] = @[]
    let content = readTresFileDiag(getTempDir() / "definitely_missing_file.tres", diags)
    check content.len == 0
    check hasErrors(diags)

when isMainModule:
  echo "Running parser tests..."
