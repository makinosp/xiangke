## Move data parser for .tres files.
## Parses MoveData resources into structured Nim types.
import std/[tables]
import ../diagnostics
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

proc parseMoveDiag*(text: string, file: string,
                    diags: var seq[Diagnostic]): MoveData =
  ## Parse a single move from .tres text content, recording diagnostics
  ## for missing or invalid fields instead of silently substituting defaults.
  result = MoveData()
  
  let (id, idFound) = getValue(text, "id")
  if not idFound:
    diags.add(newDiagnostic("error", file, "", "Missing required field: id"))
    return result
  result.id = id

  let (name, _) = getValue(text, "name")
  result.name = name

  let (typeStr, _) = getValue(text, "type")
  result.`type` = parseIntChecked(typeStr, "type", file, diags, 0)

  let (powerStr, _) = getValue(text, "power")
  result.power = parseIntChecked(powerStr, "power", file, diags, 0)

  let (accStr, _) = getValue(text, "accuracy")
  result.accuracy = parseIntChecked(accStr, "accuracy", file, diags, 100)

  let (effStr, _) = getValue(text, "effect")
  result.effect = parseIntChecked(effStr, "effect", file, diags, 0)

  let (chStr, _) = getValue(text, "effect_chance")
  result.effectChance = parseIntChecked(chStr, "effect_chance", file, diags, 0)

  let (modStatStr, _) = getValue(text, "stat_mod_stat")
  result.statModStat = parseIntChecked(modStatStr, "stat_mod_stat", file, diags, -1)

  let (modStageStr, _) = getValue(text, "stat_mod_stage")
  result.statModStage = parseIntChecked(modStageStr, "stat_mod_stage", file, diags, 0)

  let (hitStr, _) = getValue(text, "hit_count")
  result.hitCount = parseIntChecked(hitStr, "hit_count", file, diags, 1)

  let (recoilStr, _) = getValue(text, "recoil")
  result.recoil = parseIntChecked(recoilStr, "recoil", file, diags, 0)

  let (healStr, _) = getValue(text, "healing")
  result.healing = parseIntChecked(healStr, "healing", file, diags, 0)

  let (catStr, _) = getValue(text, "damage_category")
  result.damageCategory = parseIntChecked(catStr, "damage_category", file, diags, 0)

proc parseMove*(text: string): MoveData =
  ## Lenient parse of a single move; diagnostics are discarded.
  ## Prefer `parseMoveDiag` when the caller needs failure visibility.
  var diags: seq[Diagnostic] = @[]
  return parseMoveDiag(text, "", diags)

proc parseMoves*(globPattern: string):
    tuple[moves: seq[MoveData], diagnostics: seq[Diagnostic]] =
  ## Parse all move .tres files matching the glob pattern.
  ## Returns parsed moves plus aggregated load/parse diagnostics so missing
  ## or corrupted files are never silently dropped.
  result.moves = @[]
  result.diagnostics = @[]
  for path in globTres(globPattern):
    let text = readTresFileDiag(path, result.diagnostics)
    if text.len == 0:
      continue
    let moveData = parseMoveDiag(text, path, result.diagnostics)
    if moveData.id.len > 0:
      result.moves.add(moveData)

proc getMovePowerMap*(moves: seq[MoveData]): Table[string, int] =
  ## Create a lookup table from move ID to power.
  result = initTable[string, int]()
  for moveEntry in moves:
    result[moveEntry.id] = moveEntry.power
