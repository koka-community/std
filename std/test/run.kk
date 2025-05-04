/*----------------------------------------------------------------------------
   Copyright 2025, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/test/run
import std/test/test
import std/test/report
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


// TODO: use core/std/exit after https://github.com/koka-lang/koka/pull/703 is released
extern exit(i: int): io-noexn ()
  c inline "exit(kk_integer_clamp32(#1, kk_context()))"
  js inline "throw(`Exited with code: ${#1}`)"

fun execute-tests(opts: testopts, tests: list<test-case<io>>): <test-report,io> ()
  var summary := suite-summary()
  tests.foreach fn(test)
    val tid = test.identity
    if opts.should-include(tid) then
      summary := summary.execute(test)
    else
      report-skipped(tid)
      summary := summary(skipped = summary.skipped + 1)
  report-summary(summary)
  if summary.any-failures then
    exit(1)

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

// Main entrypoint for running tests. Parses CLI arguments and runs the relevant tests.
// Exits the process with a nonzero exit code if any tests fail.
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
