## Diagnostic types shared across parsing, validation, and output.
## Aggregated diagnostics let the CLI report load/parse failures instead of
## silently substituting defaults, so partial reports are never mistaken for
## complete ones.

type
  Diagnostic* = object
    severity*: string  ## "error" or "warning"
    file*: string      ## Source file path ("" when not file-specific).
    entity*: string    ## Entity ID when known ("" otherwise).
    message*: string

proc newDiagnostic*(severity, file, entity, message: string): Diagnostic =
  ## Create a diagnostic with the given fields.
  return Diagnostic(
    severity: severity,
    file: file,
    entity: entity,
    message: message,
  )

proc countErrors*(diagnostics: seq[Diagnostic]): int =
  ## Count diagnostics with error severity.
  for diag in diagnostics:
    if diag.severity == "error":
      inc result

proc hasErrors*(diagnostics: seq[Diagnostic]): bool =
  ## Return true if any diagnostic has error severity.
  return countErrors(diagnostics) > 0

proc printDiagnostics*(diagnostics: seq[Diagnostic]) =
  ## Print all diagnostics to stderr, keeping stdout machine-readable.
  if diagnostics.len == 0:
    return
  stderr.writeLine("=== Data load diagnostics ===")
  for diag in diagnostics:
    var context = ""
    if diag.file.len > 0:
      context = diag.file
    if diag.entity.len > 0:
      if context.len > 0:
        context &= " "
      context &= "(entity: " & diag.entity & ")"
    if context.len > 0:
      stderr.writeLine("  [" & diag.severity & "] " & context & ": " & diag.message)
    else:
      stderr.writeLine("  [" & diag.severity & "] " & diag.message)
  stderr.writeLine("  (" & $diagnostics.len & " diagnostics, " & $countErrors(diagnostics) & " errors)")
