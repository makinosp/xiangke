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
  for colIdx in 0..<headers.len:
    result.columns.add(TableColumn(
      header: headers[colIdx],
      width: if colIdx < widths.len: widths[colIdx] else: 10,
      align: "left"
    ))

proc addRow*(tbl: var TableOutput, row: seq[string]) =
  ## Add a row to the table.
  tbl.rows.add(row)

proc formatCell*(value: string, width: int, align: string): string =
  ## Format a cell value with padding.
  if align == "right":
    return value.align(width)
  else:
    return value.alignLeft(width)

proc renderTable*(tbl: TableOutput): string =
  ## Render the table as a formatted string.
  var output = ""
  
  # Header
  var headerLine = ""
  for col in tbl.columns:
    headerLine &= formatCell(col.header, col.width, "left") & " "
  output.add(headerLine.strip() & "\n")
  
  # Separator
  var sepLine = ""
  for col in tbl.columns:
    sepLine &= "-".repeat(col.width) & " "
  output.add(sepLine.strip() & "\n")
  
  # Rows
  for row in tbl.rows:
    var line = ""
    for colIdx in 0..<tbl.columns.len:
      let value = if colIdx < row.len: row[colIdx] else: ""
      line &= formatCell(value, tbl.columns[colIdx].width, tbl.columns[colIdx].align) & " "
    output.add(line.strip() & "\n")
  
  return output

proc printTable*(tbl: TableOutput) =
  ## Print the table to stdout.
  echo renderTable(tbl)
