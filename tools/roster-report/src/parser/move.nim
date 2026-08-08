## Move data parser for .tres files.
## Parses MoveData resources into structured Nim types.
import std/[tables]
import tres

type
  MoveData* = object
    id*: string
    name*: string
    `type`*: int
    power*: int
    accuracy*: int
    effect*: int
    effectChance*: int
    statModStat*: int
    statModStage*: int
    hitCount*: int
    recoil*: int
    healing*: int
    damageCategory*: int

proc parseMove*(text: string): MoveData =
  ## Parse a single move from .tres text content.
  result = MoveData()
  
  let (id, idFound) = getValue(text, "id")
  if not idFound:
    return result
  result.id = id

  let (name, _) = getValue(text, "name")
  result.name = name

  let (typeStr, _) = getValue(text, "type")
  result.`type` = parseIntOr(typeStr, 0)

  let (powerStr, _) = getValue(text, "power")
  result.power = parseIntOr(powerStr, 0)

  let (accStr, _) = getValue(text, "accuracy")
  result.accuracy = parseIntOr(accStr, 0)

  let (effStr, _) = getValue(text, "effect")
  result.effect = parseIntOr(effStr, 0)

  let (chStr, _) = getValue(text, "effect_chance")
  result.effectChance = parseIntOr(chStr, 0)

  let (modStatStr, _) = getValue(text, "stat_mod_stat")
  result.statModStat = parseIntOr(modStatStr, -1)

  let (modStageStr, _) = getValue(text, "stat_mod_stage")
  result.statModStage = parseIntOr(modStageStr, 0)

  let (hitStr, _) = getValue(text, "hit_count")
  result.hitCount = parseIntOr(hitStr, 1)

  let (recoilStr, _) = getValue(text, "recoil")
  result.recoil = parseIntOr(recoilStr, 0)

  let (healStr, _) = getValue(text, "healing")
  result.healing = parseIntOr(healStr, 0)

  let (catStr, _) = getValue(text, "damage_category")
  result.damageCategory = parseIntOr(catStr, 0)

proc parseMoves*(globPattern: string): seq[MoveData] =
  ## Parse all move .tres files matching the glob pattern.
  result = @[]
  for path in globTres(globPattern):
    let text = readTresFile(path)
    if text.len == 0:
      continue
    let moveData = parseMove(text)
    if moveData.id.len > 0:
      result.add(moveData)

proc getMovePowerMap*(moves: seq[MoveData]): Table[string, int] =
  ## Create a lookup table from move ID to power.
  result = initTable[string, int]()
  for moveEntry in moves:
    result[moveEntry.id] = moveEntry.power
