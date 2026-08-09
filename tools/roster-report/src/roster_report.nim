## Roster Report CLI for xiangke game data.
## Provides subcommands to analyze and report on .tres resource files.
import std/[parseopt, os]
import constants
import diagnostics
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
  --output=<path>  Write the report to a file (table/csv/html)
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

  # Parse data, collecting load/parse diagnostics for missing or corrupted
  # files instead of silently dropping them.
  let (characters, charDiags) = parseCharacters(dir / "characters" / "*.tres")
  let (movesData, moveDiags) = parseMoves(dir / "moves" / "*.tres")
  let diagnostics = charDiags & moveDiags

  # Report load/parse diagnostics before running the command so failures are
  # visible even when a partial report is still produced.
  printDiagnostics(diagnostics)

  # Dispatch command
  var failed = false
  case cmd
  of "roster":
    failed = not runRoster(characters, movesData, format, output)
  of "types":
    failed = not runTypes(characters, format, output)
  of "moves":
    failed = not runMoves(movesData, format, output)
  of "anomalies":
    let (reportOk, errorCount) = runAnomalies(characters, movesData, format, output)
    failed = not reportOk or errorCount > 0
  of "ranking":
    failed = not runRanking(characters, format, output)
  of "radar":
    failed = not runRadar(characters, format, output)
  of "":
    echo "Error: No command specified."
    echo "Run with --help for usage information."
    quit(1)
  else:
    echo "Error: Unknown command: ", cmd
    echo "Run with --help for usage information."
    quit(1)

  # Exit non-zero on any data load/parse error or output failure so callers
  # never mistake a partial report for a successful one.
  if failed or hasErrors(diagnostics):
    quit(1)

when isMainModule:
  main()
