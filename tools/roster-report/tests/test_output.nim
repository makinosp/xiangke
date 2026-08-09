## Unit tests for output utilities (CSV, table, HTML).
import std/[unittest, os, strutils]
import ../src/output/[csv, table, html]

proc makeTempDir(name: string): string =
  ## Create a fresh temporary directory for tests.
  let path = getTempDir() / name
  removeDir(path)
  createDir(path)
  return path

suite "csv.nim - CSV escaping":
  test "escapeCSV leaves plain values untouched":
    check escapeCSV("cao_cao") == "cao_cao"
    check escapeCSV("曹操") == "曹操"

  test "escapeCSV quotes values with commas":
    check escapeCSV("a,b") == "\"a,b\""

  test "escapeCSV quotes values with double quotes and doubles them":
    check escapeCSV("say \"hi\"") == "\"say \"\"hi\"\"\""

  test "escapeCSV quotes values with LF newline":
    check escapeCSV("line1\nline2") == "\"line1\nline2\""

  test "escapeCSV quotes values with CR newline":
    check escapeCSV("line1\rline2") == "\"line1\rline2\""

suite "csv.nim - column consistency":
  test "writeCSV rejects rows with wrong column count":
    let headers = @["a", "b", "c"]
    let rows = @[@["1", "2"], @["1", "2", "3"]]
    check writeCSV(headers, rows) == false

  test "writeCSV accepts matching rows":
    let headers = @["a", "b"]
    let rows = @[@["1", "2"]]
    check writeCSV(headers, rows) == true

  test "writeCSV writes file content":
    let tmpDir = makeTempDir("roster_test_csv")
    defer: removeDir(tmpDir)
    let path = tmpDir / "out.csv"
    let headers = @["id", "name"]
    let rows = @[@["1", "曹操"]]
    check writeCSV(headers, rows, path) == true
    let content = readFile(path)
    check content == "id,name\n1,曹操\n"

  test "writeCSV fails when file cannot be opened":
    # Path inside a non-existent directory.
    let path = getTempDir() / "roster_missing_dir" / "out.csv"
    check writeCSV(@["a"], @[@["1"]], path) == false

suite "table.nim - table output":
  test "writeTableFile writes rendered table":
    let tmpDir = makeTempDir("roster_test_table")
    defer: removeDir(tmpDir)
    let path = tmpDir / "out.txt"
    var table = newTableOutput(@["ID", "Name"], @[4, 10])
    table.addRow(@["1", "曹操"])
    check writeTableFile(table, path) == true
    let content = readFile(path)
    check content.contains("曹操")
    check content.contains("ID")

  test "writeTableFile fails when file cannot be opened":
    let path = getTempDir() / "roster_missing_dir" / "out.txt"
    var table = newTableOutput(@["ID"], @[4])
    table.addRow(@["1"])
    check writeTableFile(table, path) == false

suite "html.nim - HTML output":
  test "escapeHTML escapes special characters":
    check escapeHTML("<b>&\"'") == "&lt;b&gt;&amp;&quot;&#39;"

  test "htmlTable escapes cell content":
    let html = htmlTable(@["Name"], @[@["<script>alert(1)</script>"]])
    check html.contains("&lt;script&gt;alert(1)&lt;/script&gt;")

  test "writeHTML writes file content":
    let tmpDir = makeTempDir("roster_test_html")
    defer: removeDir(tmpDir)
    let path = tmpDir / "out.html"
    check writeHTML(path, "<html><body>hi</body></html>") == true
    check readFile(path) == "<html><body>hi</body></html>"

  test "writeHTML fails when file cannot be opened":
    let path = getTempDir() / "roster_missing_dir" / "out.html"
    check writeHTML(path, "<html></html>") == false

when isMainModule:
  echo "Running output tests..."
