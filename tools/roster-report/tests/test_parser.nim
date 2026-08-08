## Unit tests for the .tres parser modules.
import std/[unittest, os, strutils, tables]
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
    let c = parseCharacter(text)
    check c.id == "test_char"
    check c.name == "テスト"
    check c.`type` == 6
    check c.secondary == 4
    check c.stats.hp == 135
    check c.stats.attack == 75
    check c.stats.defense == 80
    check c.stats.speed == 85
    check c.stats.intelligence == 110
    check c.stats.spirit == 105
    check c.moves.len == 4
    check c.moves[0] == "move1"
    check c.moves[3] == "move4"

  test "typeLabel returns correct labels":
    check typeLabel(0, -1) == "WOOD"
    check typeLabel(6, 4) == "YIN+WATER"
    check typeLabel(1, -1) == "FIRE"

  test "statSum calculates total":
    let c = CharacterData(
      stats: Stats(hp: 100, attack: 50, defense: 60, speed: 70, intelligence: 80, spirit: 90)
    )
    check statSum(c) == 450

  test "parseCharacter handles missing secondary_type":
    let text = """
id = "no_secondary"
type = 2
"""
    let c = parseCharacter(text)
    check c.secondary == -1

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
    let m = parseMove(text)
    check m.id == "fire_strike"
    check m.name == "炎撃"
    check m.`type` == 1
    check m.power == 80
    check m.accuracy == 95
    check m.effect == 1
    check m.effectChance == 30
    check m.hitCount == 1
    check m.damageCategory == 0

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

when isMainModule:
  echo "Running parser tests..."
