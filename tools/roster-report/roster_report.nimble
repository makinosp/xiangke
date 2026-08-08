# Package
version       = "0.1.0"
author        = "xiangke"
description   = "Roster report CLI for xiangke game data"
license       = "MIT"
srcDir        = "src"
bin           = @["roster_report"]

# Dependencies
requires "nim >= 2.0.0"

task test, "Run the test suite":
  exec "nim c -r --hints:off tests/test_parser.nim"
  exec "nim c -r --hints:off tests/test_output.nim"
  exec "nim c -r --hints:off tests/test_anomalies.nim"
