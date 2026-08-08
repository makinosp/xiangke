## CSV output utilities.
## Provides functions to format data as CSV.
import std/[strutils, streams]

proc escapeCSV*(value: string): string =
  ## Escape a value for CSV output.
  ## Wraps in quotes if the value contains commas, quotes, or newlines.
  if value.contains(',') or value.contains('"') or value.contains('\n'):
    return "\"" & value.replace("\"", "\"\"") & "\""
  return value

proc writeCSVRow*(stream: Stream, row: seq[string]) =
  ## Write a single CSV row to the stream.
  var escapedRow: seq[string] = @[]
  for cell in row:
    escapedRow.add(escapeCSV(cell))
  stream.write(escapedRow.join(",") & "\n")

proc writeCSV*(headers: seq[string], rows: seq[seq[string]], output: string = "") =
  ## Write CSV data to stdout or a file.
  var stream: Stream
  if output.len > 0:
    stream = newFileStream(output, fmWrite)
    if stream == nil:
      echo "Error: Cannot open file for writing: ", output
      return
  else:
    stream = newFileStream(stdout)
  
  defer:
    if stream != nil:
      stream.close()
  
  # Write header
  writeCSVRow(stream, headers)
  
  # Write data rows
  for row in rows:
    writeCSVRow(stream, row)

proc printCSV*(headers: seq[string], rows: seq[seq[string]]) =
  ## Print CSV data to stdout.
  writeCSV(headers, rows)
