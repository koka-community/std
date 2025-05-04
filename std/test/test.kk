/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module test/test

// The toplevel `test` effect for defining test groups and cases
pub effect test
  val current-scope: maybe<scope>
  fun register-test(test-identity: test-identity, body: () -> <expect,io> ()): ()

// The effect available within a test, for making expectations / assertions
pub effect expect
  ctl test-expect(v: expect-value<a>): a
  fun test-hint(hint: string): ()

value struct location
  mod: string
  line: string
  
fun location/show(l: location): string
  l.mod ++ ":" ++ l.line

struct scope
  scope-id: int
  parent: maybe<scope>
  scope-name: string
  scope-indent: string
  location: location

fun scope/show(s: scope): div string
  "Scope("++s.scope-id.show ++", "++s.parent.show ++ ", " ++ s.scope-name++")"

// A test, possibly within group / scopes
abstract struct test-identity
  test-id: int
  scope: maybe<scope>
  name: string
  location: location
  
pub fun test-identity/show(t: test-identity): div string
  "Test-identity("++t.test-id.show ++", "++t.scope.show ++ ", " ++ t.name ++ ")"

abstract value struct suite-summary
  failures: int
  successes: int

pub fun suite-summary(): suite-summary
  Suite-summary(0, 0)

pub fun summary/any-failures(summary: suite-summary): bool
  summary.failures > 0

pub effect test-report
  fun report-skipped<a>(test: test-identity): ()
  fun report-start<a>(test: test-identity): ()
  fun report-hint<a>(test: test-identity, hint: string): ()
  fun report-failure<a>(test: test-identity, expectation: expect-value<a>): ()
  fun report-end<a>(test: test-identity, failures: int): ()
  fun report-summary<a>(summary: suite-summary): ()

fun indentation(scope: maybe<scope>): total string
  scope.map(fn(s) s.scope-indent).default("")

fun scope/full-name(scope: scope): div string
  scope.parent.map(fn(p) p.full-name ++ " ").default("") ++ scope.scope-name

pub fun test/full-name(test: test-identity): div string
  test.scope.map(fn(s) s.full-name ++ " ").default("") ++ test.name

fun report-scope-once(reported-scopes: ref<global, list<int>>, scope: maybe<scope>, report: (scope) -> <st<global>,div|e> ()): <st<global>,div|e> ()
  match scope
    Nothing -> ()
    Just(scope) ->
      report-scope-once(reported-scopes, scope.parent, report)
      val reported = !reported-scopes
      if reported.find(fn(id) -> id == scope.scope-id).is-nothing then
        reported-scopes := Cons(scope.scope-id, reported)
        report(scope)

pub fun plain-reporter(action: () -> <test-report,io|e> ()): <io|e> ()
  var current-failures := 0
  val reported-scopes = ref([])

  with handler <test-report>
    fun report-skipped(test)
      ()

    fun report-start(test)
      current-failures := 0
      val infomsg = test.scope.indentation ++ test.name
      report-scope-once(reported-scopes, test.scope) fn(scope)
        println(scope.parent.indentation ++ scope.scope-name ++ ":")
      println(infomsg ++ "(" ++ test.location.show ++ ")...")

    fun report-hint(test, hint)
      println(test.scope.indentation ++ hint)

    fun report-end(test, failures: int)
      val infomsg = test.scope.indentation ++ test.name ++ "(" ++ test.location.show ++ "):"
      val result = if failures == 0 then "OK" else "FAIL"
      println(infomsg ++ " " ++ result)

    fun report-failure(test: test-identity, failed-expectation)
      current-failures := current-failures + 1
      val b = failed-expectation.expectation
      val location = failed-expectation.location
      val showa = failed-expectation.show
      val err = failed-expectation.details
      match failed-expectation.run-value
        Error(e) ->
          println(test.scope.indentation() ++ "  Expect(" ++ location ++ ") == " ++ b.show(?show=showa) ++ ": threw an exception: " ++ e.exn/show ++ err.map(fn(e1) "\n    Details: " ++ e1).default(""))
        Ok(a) ->
          println(test.scope.indentation() ++ "  Expect(" ++ location ++ ") == " ++ b.show(?show=showa) ++ ": but got: " ++ a.showa ++ err.map(fn(e) "\n    Details: " ++ e).default(""))

    fun report-summary(summary: suite-summary)
      println(summary.failures.show ++ " failures, " ++ summary.successes.show ++ " successes")

  mask<local>(action)

pub alias test-reporter<e> = (action: () -> <test-report|e> ()) -> e ()

pub fun color-reporter(action: () -> <test-report,io|e> ()): <io|e> ()
  var total-successes := 0
  var total-skipped := 0
  val reported-scopes = ref([])
  val green = "\u001b[0;32m"
  val cyan = "\u001b[0;36m"
  val red = "\u001b[0;31m"
  val yellow = "\u001b[0;33m"
  val reset = "\u001b[0m"
  var failed-test-names := []
  var hint-buffer-rev := []

  with handler <test-report>
    fun report-skipped(test)
      total-skipped := total-skipped + 1

    fun report-start(test)
      hint-buffer-rev := []
      report-scope-once(reported-scopes, test.scope) fn(scope)
        println(scope.parent.indentation ++ cyan ++ scope.scope-name ++ ":" ++ reset)
      println(cyan ++ test.scope.indentation ++ test.name ++ "(" ++ test.location.show ++ ")..." ++ reset)

    fun report-hint(test, hint)
      // accumulate and only output on failure
      hint-buffer-rev := Cons(hint, hint-buffer-rev)

    fun report-end(test, failures: int)
      if failures == 0 then
        println(test.scope.indentation ++ green ++ "- ok" ++ reset)
      else
        hint-buffer-rev.reverse.foreach fn(hint)
          println(test.scope.indentation ++ yellow ++ hint ++ reset)

        println(test.scope.indentation ++ red ++ "- failed\n" ++ reset)
        failed-test-names := Cons(test.full-name, failed-test-names)

    fun report-failure(test: test-identity, failed-expectation)
      val b = failed-expectation.expectation
      val location = failed-expectation.location
      val showa = failed-expectation.show
      val err = failed-expectation.details
      match failed-expectation.run-value
        Error(e) ->
          println(red ++ test.scope.indentation() ++ "Expect(" ++ location ++ ") == " ++ b.show(?show=showa) ++ ": threw an exception: " ++ e.exn/show ++ err.map(fn(e1) "\n    Details: " ++ e1).default("") ++ reset)
        Ok(a) ->
          println(red ++ test.scope.indentation() ++ "Expect(" ++ location ++ ") == " ++ b.show(?show=showa) ++ ": but got: " ++ a.showa ++ err.map(fn(e) "\n    Details: " ++ e).default("") ++ reset)

    fun report-summary(summary: suite-summary)
      val color = if summary.failures > 0 then red else green
      println(
        color ++
        summary.failures.show ++ " failures, " ++ summary.successes.show ++ " successes"
        ++ (if total-skipped > 0 then " (" ++ total-skipped.show ++ " skipped)" else "")
        ++ reset
        )

      if summary.failures > 0 then
        println(red ++ "\nFailed tests:")
        failed-test-names.foreach fn(name)
          println(" - " ++ name)
        println(reset)

  mask<local>(action)

value type expectation<a>
  ExpectedValue(a: a)
  ExpectedError(str: string)
  ExpectedAssertion(str: string)

fun show(a: expectation<a>, ?show: a -> div string): div string
  match a
    ExpectedValue(a) -> a.show
    ExpectedError(a) -> "error: " ++ a
    ExpectedAssertion(a) -> "assertion: " ++ a

// An expected value for a test
struct expect-value<a>
  run-value: error<a> // The value of the computation when run
  expectation: expectation<a> // The expected value
  details: maybe<string> // An additional error message providing context of the expectation
  continue-on-error: bool // Whether to continue with the expected value (test recovery!)
  location: string // The line where the expectation was made
  eq: (a,a) -> div bool // The equality function for the value
  show: (a) -> div string; // The show function for the value

// Expects a computation to return a value
//
// The expected type must have an `(==)` function as well as a `show` function defined for it
pub fun expect-result(expected: a, run: () -> <exn,expect|e> a, details: string = "", continue-on-error=True, ?(==): (a,a) -> div bool, ?show: (a) -> div string, ?kk-line: string, ?kk-module: string): <expect|e> a
  val res = try({run()})
  test-expect(Expect-value(
    res, 
    ExpectedValue(expected), 
    if details == "" then Nothing else Just(details), 
    continue-on-error,
    ?kk-module ++ ":" ++ ?kk-line, 
    (==), show))

pub fun assert-error(assertion: string, ?kk-line: string, ?kk-module: string)
  test-expect(Expect-value(Ok(False), ExpectedValue(True), Just("Assertion failed: " ++ assertion), False, ?kk-module ++ ":" ++ ?kk-line, (==), show))
  ()

pub fun expect-that(assertion: string, predicate: (a) -> <exn|e> bool, run: () -> <exn,expect|e> a, details: string = "", ?(==): (a,a) -> div bool, ?show: (a) -> div string, ?kk-line: string, ?kk-module: string): <expect|e> a
  val res = try({run()})
  match res
    Ok(res) -> 
      val good = try({mask<expect>{predicate(res)}})
      test-expect(Expect-value(
        Ok(res), 
        ExpectedAssertion(assertion), 
        if details == "" then Nothing else Just(details), 
        False,
        ?kk-module ++ ":" ++ ?kk-line, 
        (==), show))
    Error(e) ->
      test-expect(Expect-value(
        Error(e), 
        ExpectedAssertion(assertion), 
        if details == "" then Nothing else Just(details), 
        False,
        ?kk-module ++ ":" ++ ?kk-line, 
        (==), show))

// Same as expect-result but does not return the result of the computation, and defaults to not continue on error
pub fun expect(expected: a, run: () -> <exn,expect|e> a, details: string = "", continue-on-error=False, ?(==): (a,a) -> div bool, ?show: (a) -> div string, ?kk-line: string, ?kk-module: string): <expect|e> ()
  expect-result(expected, run, details, continue-on-error)
  ()

val next-id-ref: delayed<st<global>, ref<global,int>> = delay { ref(0) }
fun gen-id(): st<global> int
  next-id-ref.force.modify fn(r)
    val id = r
    r := r + 1
    id

// group of tests, requires (and overrides) test-scope
pub fun group(name: string, f: () -> <test,io|e> (), ?kk-module: string, ?kk-line: string): <test,io|e> ()
  val scope = Scope(
    scope-id = gen-id(),
    parent = current-scope,
    scope-name = name,
    scope-indent = current-scope.indentation() ++ "  ",
    location = Location(?kk-module, ?kk-line)
  )
  with override<test>
    val current-scope = Just(scope)
    fun register-test(test-identity, body)
      register-test(test-identity, body)
  f()

pub fun hint(value: string): expect ()
  test-hint(value)

pub fun test(name: string, f: () -> <expect,io> (), ?kk-module: string, ?kk-line: string): <test,io> ()
  register-test(Test-identity(gen-id(), current-scope, name, Location(?kk-module, ?kk-line)), f)

pub value struct test-case<e>
  identity: test-identity
  body: () -> <expect|e> ()

// run at the top level to execute tests, requires a reporter
// TODO lazy stream instead of an eager list
pub fun collect-tests(f: () -> <test,io> ()): io list<test-case<io>>
  var tests-rev := []
  handle<test>(f) {
    val current-scope = Nothing

    fun register-test(test, body) {
      tests-rev := Cons(Test-case(test, body), tests-rev)
    }
  }
  tests-rev.reverse

// Executes a single test. Returns an updated suite summary
pub fun execute(summary: suite-summary, test: test-case<io>): <test-report,io> suite-summary
  val tid = test.identity
  report-start(tid)
  var fail-count := 0
  fun result()
    if fail-count == 0 then
      summary(successes = summary.successes + 1)
    else
      summary(failures = summary.failures + fail-count)

  with finally { report-end(tid, fail-count) }
  with handler<expect> {
    fun test-hint(v)
      report-hint(tid, v)

    ctl test-expect(v)
      val a = v.run-value
      val b = v.expectation
      match a
        Error(_) ->
          fail-count := fail-count + 1
          report-failure(tid, v)
          if v.continue-on-error then
            match b
              ExpectedValue(b') -> resume(b')
              _ -> result()
          else result()
        Ok(a') ->
          val good = match b
            ExpectedValue(b') -> (v.eq)(a', b')
            ExpectedError(_) -> False
            ExpectedAssertion(_) -> True
          if good then
            resume(a')
          else
            fail-count := fail-count + 1
            report-failure(tid, v)
            if v.continue-on-error then
              match b
                ExpectedValue(b') -> resume(b')
                _ -> result()
            else result()
  }
  with mask<test-report>
  (test.body)()
  result()
