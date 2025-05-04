/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/test/test

pub alias test-reporter<e> = (action: () -> <test-report|e> ()) -> e ()

pub effect test-report
  fun report-skipped<a>(test: test-identity): ()
  fun report-start<a>(test: test-identity): ()
  fun report-hint<a>(test: test-identity, hint: string): ()
  fun report-failure<a>(test: test-identity, expectation: expect-value<a>): ()
  fun report-end<a>(test: test-identity, failures: int): ()
  fun report-summary<a>(summary: suite-summary): ()

// The toplevel `test` effect for defining test groups and cases
pub effect test
  val current-scope: maybe<test-scope>
  fun register-test(test-identity: test-identity, body: () -> <expect,io> ()): ()

// The effect available within a test, for making expectations / assertions
pub effect expect
  ctl test-expect(v: expect-value<a>): a
  fun test-hint(hint: string): ()

abstract value struct location
  mod: string
  line: string
  
pub fun location/show(l: location): string
  l.mod ++ ":" ++ l.line

pub struct test-scope
  scope-id: int
  parent: maybe<test-scope>
  scope-name: string
  location: location

fun scope/show(s: test-scope): div string
  "Scope("++s.scope-id.show ++", "++s.parent.show ++ ", " ++ s.scope-name++")"

// A test, possibly within group / scopes
pub struct test-identity
  test-id: int
  scope: maybe<test-scope>
  name: string
  location: location
  
pub fun test-identity/show(t: test-identity): div string
  "Test-identity("++t.test-id.show ++", "++t.scope.show ++ ", " ++ t.name ++ ")"

pub value struct suite-summary
  failures: int
  successes: int
  skipped: int

pub fun suite-summary(): suite-summary
  Suite-summary(0, 0, 0)

pub fun summary/any-failures(summary: suite-summary): bool
  summary.failures > 0

pub fun indentation(scope: maybe<test-scope>): div string
  scope.map(fn(s) s.parent.indentation ++ "  ").default("")

pub fun scope/full-name(scope: test-scope): div string
  scope.parent.map(fn(p) p.full-name ++ " ").default("") ++ scope.scope-name

pub fun test/full-name(test: test-identity): div string
  test.scope.map(fn(s) s.full-name ++ " ").default("") ++ test.name

pub value type expectation<a>
  ExpectedValue(a: a)
  ExpectedError(str: string)
  ExpectedAssertion(str: string)

pub fun show(a: expectation<a>, ?show: a -> div string): div string
  match a
    ExpectedValue(a) -> a.show
    ExpectedError(a) -> "error: " ++ a
    ExpectedAssertion(a) -> "assertion: " ++ a

// An expected value for a test
abstract struct expect-value<a>
  run-value: error<a> // The value of the computation when run
  expectation: expectation<a> // The expected value
  details: maybe<string> // An additional error message providing context of the expectation
  continue-on-error: bool // Whether to continue with the expected value (test recovery!)
  location: string // The line where the expectation was made
  eq: (a,a) -> div bool // The equality function for the value
  show: (a) -> div string; // The show function for the value

pub fun show-failed(failed: expect-value<a>): div string
  val b = failed.expectation
  val location = failed.location
  val showa = failed.show
  val err = failed.details
  val actual = match failed.run-value
    Error(e) ->
      "threw an exception: " ++ e.exn/show
    Ok(a) ->
      "but got: " ++ a.showa
  "Expect(" ++ location ++ ") == " ++ b.show(?show=showa) ++ ": " ++ actual ++ err.map(fn(e) "\nDetails: " ++ e).default("")

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
  val scope = Test-scope(
    scope-id = gen-id(),
    parent = current-scope,
    scope-name = name,
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
