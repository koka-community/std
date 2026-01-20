import std/test
import std/exn/ctx

fun expect-ex(expected: string, action: () -> <exn,div|e> ()): <div,expect|e> ()
  match try({ mask<expect>(action) })
    Ok(_) -> fail("Test didn't throw an error")
    Error(e) -> expect(expected) { show-with-ctx(e) }

fun raise() { throw("File not found") }

fun main() { run-tests(suite) }

pub fun suite()
  fun multi-context()
    val config-file = "~/.some-config"
    with error-ctx("Program failed")
    with error-ctx { "Initialization error" }
    with error-ctx { "Error loading " ++ config-file }
    raise()

  test("ctx-list")
    expect([
      "Program failed",
      "Initialization error",
      "Error loading ~/.some-config",
      "File not found"
    ])
      try({ multi-context(); [] }, ctx-list)

  group("rendering exception context")
    test("no-context")
      expect-ex("Error: File not found", raise)

    test("single-context")
      expect-ex("Error: Can't load settings\n\nCaused by:\n  File not found")
        with error-ctx { "Can't load settings" }
        raise()

    test("multiple context")
      expect-ex(r#"
Error: Program failed

Caused by:
  1. Initialization error
  2. Error loading ~/.some-config
  3. File not found
      "#.trim, multi-context)

