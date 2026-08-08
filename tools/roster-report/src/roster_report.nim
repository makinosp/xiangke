## Roster Report CLI for xiangke game data.
## Provides subcommands to analyze and report on .tres resource files.
import std/[parseopt, os]
import constants
import parser/[character, move]
import commands/[roster, types, moves, anomalies, ranking, radar]

proc usage() =
  echo """
Usage: roster-report <command> [options]

Commands:
  roster      Show character roster table
  types       Show type distribution analysis
  moves       Show move assignment list
  anomalies   Detect data anomalies
  ranking     Show stat total ranking
  radar       Generate HTML radar chart

Options:
  --format=<fmt>   Output format: table (default), csv, html
  --dir=<path>     Resource directory (default: ../../resources)
  --help           Show this help message
  --version        Show version

Examples:
  roster-report roster
  roster-report roster --format=csv
  roster-report types
  roster-report radar --format=html --output=report.html
"""

proc getVersion(): string =
  return VERSION

proc main() =
  var
    cmd = ""
    format = "table"
    dir = ""
    output = ""
    showHelp = false
    showVersion = false

  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      cmd = key
    of cmdLongOption, cmdShortOption:
      case key
      of "format", "f":
        format = val
      of "dir", "d":
        dir = val
      of "output", "o":
        output = val
      of "help", "h":
        showHelp = true
      of "version", "v":
        showVersion = true
      else:
        echo "Unknown option: ", key
        quit(1)
    of cmdEnd:
      discard

  if showHelp:
    usage()
    quit(0)

  if showVersion:
    echo "roster-report version ", getVersion()
    quit(0)

  # Resolve resource directory
  if dir == "":
    # Default: assume running from tools/roster-report, resources is at project root
    dir = getCurrentDir() / ".." / ".." / "resources"
  
  if not dirExists(dir):
    echo "Error: Resource directory not found: ", dir
    quit(1)

  # Parse data
  let characters = parseCharacters(dir / "characters" / "*.tres")
  let movesData = parseMoves(dir / "moves" / "*.tres")
  # let statusEffects = parseStatusEffects(dir / "status_effects" / "*.tres")

  # Dispatch command
  case cmd
  of "roster":
    runRoster(characters, movesData, format, output)
  of "types":
    runTypes(characters, format, output)
  of "moves":
    runMoves(movesData, format, output)
  of "anomalies":
    runAnomalies(characters, movesData, format, output)
  of "ranking":
    runRanking(characters, format, output)
  of "radar":
    runRadar(characters, format, output)
  of "":
    echo "Error: No command specified."
    echo "Run with --help for usage information."
    quit(1)
  else:
    echo "Error: Unknown command: ", cmd
    echo "Run with --help for usage information."
    quit(1)

when isMainModule:
  main()
