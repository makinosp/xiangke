## Common .tres file parser utilities.
## Provides functions to extract key=value pairs from Godot .tres resource files.
import std/[re, strutils, os, algorithm]
import ../diagnostics

proc getValue*(text, key: string): (string, bool) =
  ## Extract a value for the given key from .tres text content.
  ## Returns (value, found) tuple.
  let pattern = "(?m)^" & escapeRe(key) & r" = ([^\n]+)"
  let regex = re(pattern)
  var matches: array[1, string]
  if text.find(regex, matches) >= 0:
    var value = matches[0].strip()
    # Remove surrounding quotes if present
    if value.len >= 2 and value[0] == '"' and value[^1] == '"':
      value = value[1..^2]
    return (value, true)
  return ("", false)

proc mustGet*(text, key: string): string =
  ## Get value for key, returning empty string if not found.
  let (value, _) = getValue(text, key)
  return value

proc parseIntOr*(strValue: string, default: int): int =
  ## Parse string to int, returning default on failure.
  if strValue == "":
    return default
  try:
    return parseInt(strValue)
  except ValueError:
    return default

proc parseIntChecked*(strValue: string, field, file: string,
                      diags: var seq[Diagnostic], default: int): int =
  ## Parse an integer, recording a warning when the value is missing and an
  ## error when it is invalid. Returns `default` in both cases so a partial
  ## report can still be produced, but the failure is never silent.
  if strValue == "":
    diags.add(newDiagnostic("warning", file, "",
                            "Missing field '" & field & "', using default " & $default))
    return default
  try:
    return parseInt(strValue)
  except ValueError:
    diags.add(newDiagnostic("error", file, "",
                            "Invalid integer for field '" & field & "': '" & strValue & "'"))
    return default

proc readTresFile*(path: string): string =
  ## Read a .tres file and return its content.
  ## Returns empty string on error.
  try:
    return readFile(path)
  except IOError:
    return ""

proc readTresFileDiag*(path: string, diags: var seq[Diagnostic]): string =
  ## Read a .tres file, recording an error diagnostic on failure.
  try:
    return readFile(path)
  except IOError as e:
    diags.add(newDiagnostic("error", path, "", "Failed to read file: " & e.msg))
    return ""

proc globTres*(pattern: string): seq[string] =
  ## Find all .tres files matching the glob pattern.
  ## Returns sorted list of file paths.
  var paths: seq[string] = @[]
  for path in walkFiles(pattern):
    paths.add(path)
  paths.sort()
  return paths
