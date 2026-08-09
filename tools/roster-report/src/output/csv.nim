## CSV output utilities.
## Provides functions to format data as CSV.
import std/[strutils, streams]

proc escapeCSV*(value: string): string =
  ## Escape a value for CSV output.
  ## Wraps in quotes if the value contains commas, quotes, CR or LF newlines.
  if value.contains(',') or value.contains('"') or
     value.contains('\n') or value.contains('\r'):
    return "\"" & value.replace("\"", "\"\"") & "\""
  return value

proc writeCSVRow*(stream: Stream, row: seq[string]) =
  ## Write a single CSV row to the stream.
  var escapedRow: seq[string] = @[]
  for cell in row:
    escapedRow.add(escapeCSV(cell))
  stream.write(escapedRow.join(",") & "\n")

proc writeCSV*(headers: seq[string], rows: seq[seq[string]],
               output: string = ""): bool =
  ## Write CSV data to stdout or a file. Returns false on failure.
  ## Status messages go to stderr so stdout stays machine-readable.
  ## Validates that every row matches the header column count.
  let expectedCols = headers.len
  for row in rows:
    if row.len != expectedCols:
      stderr.writeLine("Error: CSV row has " & $row.len & " columns, " &
                       "expected " & $expectedCols & " (header: " &
                       headers.join(",") & ")")
      return false

  var stream: Stream
  if output.len > 0:
    stream = newFileStream(output, fmWrite)
    if stream == nil:
      stderr.writeLine("Error: Cannot open file for writing: ", output)
      return false
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

  if output.len > 0:
    stderr.writeLine("CSV report written to: ", output)
  return true

proc printCSV*(headers: seq[string], rows: seq[seq[string]]) =
  ## Print CSV data to stdout.
  discard writeCSV(headers, rows)
