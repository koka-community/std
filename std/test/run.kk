/*----------------------------------------------------------------------------
   Copyright 2025, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module test/run
import test/test
import std/os/env
import std/os/flags

type test-action
  Run
  List

fun test-action/show(x: test-action) : string
  match x
    Run -> "Run"
    List -> "List"

pub value type test-filter
  All
  Include(patterns: list<string>)

fun test-filter/show(x: test-filter) : string
  match x
    All -> "*"
    Include(p) -> "Include(" ++ p.show ++")"

fun filter-from(args: list<string>)
  if args.is-nil then
    All
  else
    Include(args)

value struct testopts
  includes: test-filter = All
  action: test-action = Run

pub fun testopts/show(opts: testopts) : string
  "Testopts("++opts.includes.show ++ ", " ++ opts.action.show ++ ")"

fun testopts/should-include(opts: testopts, test: test-identity)
  match opts.includes
    All -> True
    Include(patterns) ->
      patterns.any fn(pattern)
        test.full-name.contains(pattern)

fun execute-tests(opts: testopts, tests: list<test-case<io>>): <test-report,io> ()
  tests.foreach fn(test)
    // TODO: run async tests in parallel
    val tid = test.identity
    if not(opts.should-include(tid)) then
      report-skipped(tid)
      return ()
    test.execute()


// Parse commandline arguments
pub fun parse-opts(args = get-args()): io testopts
  fun set-list(opts: testopts, do-list)
    val action = if do-list then List else Run
    opts(action = action)

  val flags = [
    Flag("l", ["list"], Bool(set-list), "list test names" )
  ]
  val (opts, remainder, errs) = parse(Testopts(), flags, get-args())
  if not(errs.is-nil) then
    println(errs.join("\n") ++ "\n" ++ flags.usage)
    throw("Invalid options")
  opts(includes = filter-from(remainder))

// Main entrypoint for running tests. Parses CLI arguments and runs the relevant tests
// TODO: extend this to discover tests across multiple files
pub fun run-tests(f: () -> <test,io> (), reporter: test-reporter<io> = color-reporter): io ()
  val opts = parse-opts()
  val tests = collect-tests(f)

  match opts.action()
    Run ->
      with reporter
      execute-tests(opts, tests)
    List ->
      tests.foreach fn(t)
        println(t.identity.full-name)

// Some simple examples
fun main(): io ()
  // custom reporter
  run-tests(reporter = plain-reporter)
    test("OK")
      ()
  println("----")

  // default color-reporter
  with run-tests()
  group("Basics")
    with group("A subgroup")
    test("Returns continue tests")
      val res = expect-result(1)
                  2
      hint("Continued!")
      expect(2)
        1 + res
      expect(2)
        1
  group("Other")
    test("Wrong expect")
      expect(1)
        2
    test("Additional info")
      expect(1, details="Really expected 1!")
        throw("Some error somewhere")
