## Status effect data parser for .tres files.
## Parses StatusEffectData resources into structured Nim types.
import std/[strutils]
import tres

const EFFECT_NAMES* = ["None", "Burn", "Poison", "Confusion", "Chain", "Charm"]

type
  StatusEffectData* = object
    effectType*: int
    name*: string
    damagePerTurn*: float
    escalating*: bool
    statModStat*: int
    statModMultiplier*: float

proc effectLabel*(effectType: int): string =
  ## Convert effect type index to human-readable label.
  if effectType >= 0 and effectType < EFFECT_NAMES.len:
    return EFFECT_NAMES[effectType]
  return "Unknown"

proc parseStatusEffect*(text: string): StatusEffectData =
  ## Parse a single status effect from .tres text content.
  result = StatusEffectData()
  
  let (effStr, effFound) = getValue(text, "effect_type")
  if not effFound:
    return result
  result.effectType = parseIntOr(effStr, 0)

  let (name, _) = getValue(text, "name")
  result.name = name

  let (dmgStr, _) = getValue(text, "damage_per_turn")
  if dmgStr.len > 0:
    try:
      result.damagePerTurn = parseFloat(dmgStr)
    except ValueError:
      result.damagePerTurn = 0.0

  let (escStr, _) = getValue(text, "escalating")
  result.escalating = escStr == "true"

  let (modStatStr, _) = getValue(text, "stat_mod_stat")
  result.statModStat = parseIntOr(modStatStr, -1)

  let (multStr, _) = getValue(text, "stat_mod_multiplier")
  if multStr.len > 0:
    try:
      result.statModMultiplier = parseFloat(multStr)
    except ValueError:
      result.statModMultiplier = 1.0
  else:
    result.statModMultiplier = 1.0

proc parseStatusEffects*(globPattern: string): seq[StatusEffectData] =
  ## Parse all status effect .tres files matching the glob pattern.
  result = @[]
  for path in globTres(globPattern):
    let text = readTresFile(path)
    if text.len == 0:
      continue
    let se = parseStatusEffect(text)
    if se.name.len > 0:
      result.add(se)
