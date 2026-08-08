## CSV output utilities.
## Provides functions to format data as CSV.
import std/[strutils, streams]

proc escapeCSV*(value: string): string =
  ## Escape a value for CSV output.
  ## Wraps in quotes if the value contains commas, quotes, or newlines.
  if value.contains(',') or value.contains('"') or value.contains('\n'):
    return "\"" & value.replace("\"", "\"\"") & "\""
  return value

proc writeCSVRow*(s: Stream, row: seq[string]) =
  ## Write a single CSV row to the stream.
  var escapedRow: seq[string] = @[]
  for cell in row:
    escapedRow.add(escapeCSV(cell))
  s.write(escapedRow.join(",") & "\n")

proc writeCSV*(headers: seq[string], rows: seq[seq[string]], output: string = "") =
  ## Write CSV data to stdout or a file.
  var s: Stream
  if output.len > 0:
    s = newFileStream(output, fmWrite)
    if s == nil:
      echo "Error: Cannot open file for writing: ", output
      return
  else:
    s = newFileStream(stdout)
  
  defer:
    if s != nil:
      s.close()
  
  # Write header
  writeCSVRow(s, headers)
  
  # Write data rows
  for row in rows:
    writeCSVRow(s, row)

proc printCSV*(headers: seq[string], rows: seq[seq[string]]) =
  ## Print CSV data to stdout.
  writeCSV(headers, rows)
