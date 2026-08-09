## Character data parser for .tres files.
## Parses CharacterData resources into structured Nim types.
import std/[strutils]
import ../constants
import ../diagnostics
import tres

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
  if primary >= 0 and primary < TYPE_LABELS.len:
    label = TYPE_LABELS[primary]
  if secondary >= 0 and secondary < TYPE_LABELS.len:
    label &= "+" & TYPE_LABELS[secondary]
  return label

proc statSum*(character: CharacterData): int =
  ## Calculate total of all stats.
  return character.stats.hp + character.stats.attack + character.stats.defense +
         character.stats.speed + character.stats.intelligence + character.stats.spirit

proc parseCharacterDiag*(text: string, file: string,
                         diags: var seq[Diagnostic]): CharacterData =
  ## Parse a single character from .tres text content, recording diagnostics
  ## for missing or invalid fields instead of silently substituting defaults.
  result = CharacterData()
  
  let (id, idFound) = getValue(text, "id")
  if not idFound:
    diags.add(newDiagnostic("error", file, "", "Missing required field: id"))
    return result
  result.id = id

  let (name, _) = getValue(text, "name")
  result.name = name

  let (typeStr, _) = getValue(text, "type")
  result.`type` = parseIntChecked(typeStr, "type", file, diags, 0)

  let (secStr, secFound) = getValue(text, "secondary_type")
  if secFound:
    result.secondary = parseIntChecked(secStr, "secondary_type", file, diags, -1)
  else:
    result.secondary = -1
    diags.add(newDiagnostic("warning", file, "",
                            "Missing field 'secondary_type', using default -1"))

  result.stats = Stats(
    hp: parseIntChecked(mustGet(text, "hp"), "hp", file, diags, 0),
    attack: parseIntChecked(mustGet(text, "attack"), "attack", file, diags, 0),
    defense: parseIntChecked(mustGet(text, "defense"), "defense", file, diags, 0),
    speed: parseIntChecked(mustGet(text, "speed"), "speed", file, diags, 0),
    intelligence: parseIntChecked(mustGet(text, "intelligence"), "intelligence", file, diags, 0),
    spirit: parseIntChecked(mustGet(text, "spirit"), "spirit", file, diags, 0),
  )

  # Parse moves from PackedStringArray("move1", "move2", ...)
  let (movesRaw, movesFound) = getValue(text, "moves")
  if not movesFound:
    diags.add(newDiagnostic("warning", file, "", "Missing field 'moves', using empty list"))
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

proc parseCharacter*(text: string): CharacterData =
  ## Lenient parse of a single character; diagnostics are discarded.
  ## Prefer `parseCharacterDiag` when the caller needs failure visibility.
  var diags: seq[Diagnostic] = @[]
  return parseCharacterDiag(text, "", diags)

proc parseCharacters*(globPattern: string):
    tuple[characters: seq[CharacterData], diagnostics: seq[Diagnostic]] =
  ## Parse all character .tres files matching the glob pattern.
  ## Returns parsed characters plus aggregated load/parse diagnostics so
  ## missing or corrupted files are never silently dropped.
  result.characters = @[]
  result.diagnostics = @[]
  for path in globTres(globPattern):
    let text = readTresFileDiag(path, result.diagnostics)
    if text.len == 0:
      continue
    let character = parseCharacterDiag(text, path, result.diagnostics)
    if character.id.len > 0:
      result.characters.add(character)
