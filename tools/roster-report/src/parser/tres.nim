## Common .tres file parser utilities.
## Provides functions to extract key=value pairs from Godot .tres resource files.
import std/[re, strutils, os, algorithm]

proc getValue*(text, key: string): (string, bool) =
  ## Extract a value for the given key from .tres text content.
  ## Returns (value, found) tuple.
  let pattern = "(?m)^" & escapeRe(key) & r" = ([^\n]+)"
  let regex = re(pattern)
  var matches: array[1, string]
  if text.find(regex, matches) >= 0:
    var v = matches[0].strip()
    # Remove surrounding quotes if present
    if v.len >= 2 and v[0] == '"' and v[^1] == '"':
      v = v[1..^2]
    return (v, true)
  return ("", false)

proc mustGet*(text, key: string): string =
  ## Get value for key, returning empty string if not found.
  let (v, _) = getValue(text, key)
  return v

proc parseIntOr*(s: string, default: int): int =
  ## Parse string to int, returning default on failure.
  if s == "":
    return default
  try:
    return parseInt(s)
  except ValueError:
    return default

proc readTresFile*(path: string): string =
  ## Read a .tres file and return its content.
  ## Returns empty string on error.
  try:
    return readFile(path)
  except IOError:
    return ""

proc globTres*(pattern: string): seq[string] =
  ## Find all .tres files matching the glob pattern.
  ## Returns sorted list of file paths.
  var paths: seq[string] = @[]
  for path in walkFiles(pattern):
    paths.add(path)
  paths.sort()
  return paths
