## Text table output utilities.
## Provides functions to format data as aligned text tables.
import std/[strutils, unicode]

type
  TableColumn* = object
    header*: string
    width*: int
    align*: string  ## "left" or "right"

  TableOutput* = object
    columns*: seq[TableColumn]
    rows*: seq[seq[string]]

proc newTableOutput*(headers: seq[string], widths: seq[int]): TableOutput =
  ## Create a new table output with headers and column widths.
  result = TableOutput(columns: @[], rows: @[])
  for i in 0..<headers.len:
    result.columns.add(TableColumn(
      header: headers[i],
      width: if i < widths.len: widths[i] else: 10,
      align: "left"
    ))

proc addRow*(t: var TableOutput, row: seq[string]) =
  ## Add a row to the table.
  t.rows.add(row)

proc formatCell*(value: string, width: int, align: string): string =
  ## Format a cell value with padding.
  if align == "right":
    return value.align(width)
  else:
    return value.alignLeft(width)

proc renderTable*(t: TableOutput): string =
  ## Render the table as a formatted string.
  var output = ""
  
  # Header
  var headerLine = ""
  for col in t.columns:
    headerLine &= formatCell(col.header, col.width, "left") & " "
  output.add(headerLine.strip() & "\n")
  
  # Separator
  var sepLine = ""
  for col in t.columns:
    sepLine &= "-".repeat(col.width) & " "
  output.add(sepLine.strip() & "\n")
  
  # Rows
  for row in t.rows:
    var line = ""
    for i in 0..<t.columns.len:
      let value = if i < row.len: row[i] else: ""
      line &= formatCell(value, t.columns[i].width, t.columns[i].align) & " "
    output.add(line.strip() & "\n")
  
  return output

proc printTable*(t: TableOutput) =
  ## Print the table to stdout.
  echo renderTable(t)
