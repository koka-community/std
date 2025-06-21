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
import std/core-extras

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

reference struct testopts
  help: bool = False
  includes: test-filter = All
  action: test-action = Run
  sample-count: int = 100
  seed: maybe<int> = Nothing
  fail-fast: bool = False

pub fun testopts/show(opts: testopts) : string
  "Testopts(" ++
    "includes=" ++ opts.includes.show ++
    ", action=" ++ opts.action.show ++
    ", sample-count=" ++ opts.sample-count.show ++
    ", seed=" ++ opts.seed.show ++
    ", fail-fast=" ++ opts.fail-fast.show ++
  ")"

fun testopts/should-include(opts: testopts, test: test-identity)
  match opts.includes
    All -> True
    Include(patterns) ->
      patterns.any fn(pattern)
        test.full-name.contains(pattern)


fun execute-tests<e>(opts: testopts, tests: list<test-case<<io|e>>>): <test-report,io-noexn|e> ()
  var summary := suite-summary()
  tests.foreach fn(test)
    if opts.fail-fast && summary.any-failures then return ()
    val tid = test.identity
    if opts.should-include(tid) then
      val s = summary
      summary := mask<local> { s.execute(test, seed=opts.seed) }
    else
      report-skipped(tid)
      summary := summary(skipped = summary.skipped + 1)
  report-summary(summary)
  if summary.any-failures then
    core-extras/exit(1)

// Parse commandline arguments
pub fun parse-opts(args = get-args()): io testopts
  fun set-list(opts: testopts, do-list)
    val action = if do-list then List else Run
    opts(action = action)

  fun set-sample-count(opts: testopts, c: maybe<string>)
    val count = match c
      Just(s) -> s.parse-int().maybe/default(opts.sample-count)
      Nothing -> opts.sample-count

    opts(sample-count = count)

  fun set-seed(opts: testopts, s: maybe<string>)
    match s
      Just(str) -> opts(seed = str.parse-int())
      Nothing -> opts

  val flags = [
    Flag("h", ["help"], Bool(fn(opts: testopts, v) opts(help=True)), "print usage" ),
    Flag("l", ["list"], Bool(set-list), "list test names" ),
    Flag("f", ["fail-fast"], Bool(fn(opts,v) opts(fail-fast=v)), "stop on first failure" ),
    Flag("", ["samples"], Opt(set-sample-count, "COUNT"), "set default sample count for prop-tests" ),
    Flag("", ["seed"], Opt(set-seed, "INT"), "set RNG seed (for each test; only use to reproduce failures)" ),
  ]

  val (opts, remainder, errs) = parse(Testopts(), flags, get-args())
  if opts.help || not(errs.is-nil) then
    println(errs.join("\n") ++ "\n" ++ flags.usage)
    if opts.help then
      core-extras/exit(0)
    else
      throw("Invalid options")
  opts(includes = filter-from(remainder))

// Main entrypoint for running tests. Parses CLI arguments and runs the relevant tests.
// Exits the process with a nonzero exit code if any tests fail.
pub fun run-tests(f: () -> <test<<io|e>>,io|e> (), reporter: test-reporter<<io|e>> = color-reporter): <io-noexn|e> ()
  // convert exceptions to exit(), for consistency (and so this function can be io-noexn)
  with fn(action)
    try(action) fn(e)
      println(e.message)
      core-extras/exit(1)

  val opts = parse-opts()
  val tests = collect-tests(opts.sample-count, f)

  match opts.action()
    Run ->
      with reporter
      with mask<exn>
      execute-tests(opts, tests)
    List ->
      tests.foreach fn(t)
        println(t.identity.full-name)
