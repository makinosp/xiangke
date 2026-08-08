## Character data parser for .tres files.
## Parses CharacterData resources into structured Nim types.
import std/[strutils]
import tres

const TYPES* = ["WOOD", "FIRE", "EARTH", "METAL", "WATER", "YANG", "YIN"]

type
  Stats* = object
    hp*: int
    attack*: int
    defense*: int
    speed*: int
    intelligence*: int
    spirit*: int

  CharacterData* = object
    id*: string
    name*: string
    `type`*: int
    secondary*: int  ## -1 = none
    stats*: Stats
    moves*: seq[string]

proc typeLabel*(primary, secondary: int): string =
  ## Convert type indices to human-readable label.
  var label = "?"
  if primary >= 0 and primary < TYPES.len:
    label = TYPES[primary]
  if secondary >= 0 and secondary < TYPES.len:
    label &= "+" & TYPES[secondary]
  return label

proc statSum*(character: CharacterData): int =
  ## Calculate total of all stats.
  return character.stats.hp + character.stats.attack + character.stats.defense +
         character.stats.speed + character.stats.intelligence + character.stats.spirit

proc parseCharacter*(text: string): CharacterData =
  ## Parse a single character from .tres text content.
  result = CharacterData()
  
  let (id, idFound) = getValue(text, "id")
  if not idFound:
    return result
  result.id = id

  let (name, _) = getValue(text, "name")
  result.name = name

  let (typeStr, _) = getValue(text, "type")
  result.`type` = parseIntOr(typeStr, 0)

  let (secStr, secFound) = getValue(text, "secondary_type")
  result.secondary = if secFound: parseIntOr(secStr, -1) else: -1

  result.stats = Stats(
    hp: parseIntOr(mustGet(text, "hp"), 0),
    attack: parseIntOr(mustGet(text, "attack"), 0),
    defense: parseIntOr(mustGet(text, "defense"), 0),
    speed: parseIntOr(mustGet(text, "speed"), 0),
    intelligence: parseIntOr(mustGet(text, "intelligence"), 0),
    spirit: parseIntOr(mustGet(text, "spirit"), 0),
  )

  # Parse moves from PackedStringArray("move1", "move2", ...)
  let (movesRaw, _) = getValue(text, "moves")
  if movesRaw.len > 0:
    var movesText = movesRaw
    # Remove PackedStringArray wrapper if present
    if movesText.startsWith("PackedStringArray(") and movesText.endsWith(")"):
      movesText = movesText[18..^2]
    # Extract quoted strings using simple parsing
    var pos = 0
    while pos < movesText.len:
      if movesText[pos] == '"':
        # Found start of quoted string
        let startPos = pos + 1
        var endPos = startPos
        while endPos < movesText.len and movesText[endPos] != '"':
          endPos += 1
        if endPos < movesText.len:
          result.moves.add(movesText[startPos..<endPos])
          pos = endPos + 1
        else:
          break
      else:
        pos += 1

proc parseCharacters*(globPattern: string): seq[CharacterData] =
  ## Parse all character .tres files matching the glob pattern.
  result = @[]
  for path in globTres(globPattern):
    let text = readTresFile(path)
    if text.len == 0:
      continue
    let character = parseCharacter(text)
    if character.id.len > 0:
      result.add(character)
