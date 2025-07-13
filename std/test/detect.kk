// CLI to detect and execute tests.
//
// Test modules are discoverd from ./test/**/*-test.kk
// Each module MUST expose a `suite` function with effect `test,io`.
//   pub fun suite(): test ()
//
// This function body should NOT invoke `run-tests`, as that will
// embed a test suite within an IO, rather than merging tests across modules.
//
// Note: this spawns `koka` from your PATH, and does not yet
// handle special characters in arguments properly.
module std/test/detect

import std/test
import std/os/path
import std/os/env
import std/os/dir
import std/data/sort
import std/core/sslice
import std/os/path
import std/os/file
import std/os/process
import std/core-extras

pub fun main()
  val test-path = generate-test-runner()

  // run the generated tests, passing through any arguments
  val args = get-args().map fn(arg)
    // basic escaping effort, TODO a version of run-system that accepts a list of args
    "'" ++ arg ++ "'"
  .join(" ")
  val cmd = "koka -e " ++ test-path.string ++ " -- " ++ args

  println(" + " ++ cmd)
  val status = run-system(cmd)
  exit(status)

fun is-test-path(p: path)
  p.basename.ends-with("-test.kk").is-just && p.is-file

fun import-path(p: path)
  p.dirparts.join("/").trim-right(".kk")

// TODO: detect clashes if multiple paths map to the same module-name
fun module-name(path: string)
  path.replace-all("/","-").replace-all(".","-")

fun generate-test-runner()
  var import-lines := []
  var test-lines := []

  val test-files = path("test")
    .list-directory-recursive
    .filter(is-test-path)
    .map(import-path)
    .sort

  if test-files.is-empty then
    throw("No test files found!")

  test-files.foreach fn(f)
    import-lines := Cons("import " ++ f.module-name ++ " = " ++ f, import-lines)
    test-lines := test-lines ++ [
      "  group(\"" ++ f ++ ".kk\")",
      "    " ++ f.module-name ++ "/suite()",
      ""
    ]

  val lines = import-lines ++ [
      "import std/test",
      "fun main()",
      "  with run-tests"
    ] ++ test-lines

  // TODO: proper tempname to avoid clashes
  // TODO: delete this file afterwards
  val generated-path = tempdir() / "generated-tests.kk"
  write-text-file(generated-path, lines.join("\n"))
  return generated-path
