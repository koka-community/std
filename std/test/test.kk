/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module test/test
// The test effect
pub effect test
  ctl test-expect(v: expect-value<a>): a

pub effect test-scope
  val scope-name: string
  val indentation: string
  fun report-fail(): ()

type expectation<a>
  ExpectedValue(a: a)
  ExpectedError(str: string)
  ExpectedAssertion(str: string)

fun show(a: expectation<a>, ?show: a -> pure string): pure string
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
  eq: (a,a) -> pure bool // The equality function for the value
  show: (a) -> pure string; // The show function for the value

// Expects a computation to return a value
//
// The expected type must have an `(==)` function as well as a `show` function defined for it
pub fun expect-result(expected: a, run: () -> <exn,test|e> a, details: string = "", continue-on-error=True, ?(==): (a,a) -> pure bool, ?show: (a) -> pure string, ?kk-line: string, ?kk-module: string): <test|e> a
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

pub fun expect-that(assertion: string, predicate: (a) -> <exn|e> bool, run: () -> <exn,test|e> a, details: string = "", ?(==): (a,a) -> pure bool, ?show: (a) -> pure string, ?kk-line: string, ?kk-module: string): <test|e> a
  val res = try({run()})
  match res
    Ok(res) -> 
      val good = try({mask<test>{predicate(res)}})
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
pub fun expect(expected: a, run: () -> <exn,test|e> a, details: string = "", continue-on-error=False, ?(==): (a,a) -> pure bool, ?show: (a) -> pure string, ?kk-line: string, ?kk-module: string): <test|e> ()
  expect-result(expected, run, details, continue-on-error)
  ()

// A top level group of tests
pub fun group(name: string, f: () -> <test-scope,console|e> (), is-test: bool = False, ?kk-module: string, ?kk-line: string): <console|e> ()
  val sname = if is-test then "test" else "group"
  val infomsg = sname ++ "("  ++ name ++ " : " ++ ?kk-module ++ ":" ++ ?kk-line ++ "):"
  println(infomsg ++ "... ")
  var anyfail := False
  with handler
    val indentation = "  "
    val scope-name = name
    fun report-fail() 
      anyfail := True
    return(x)
      if !anyfail then println(infomsg ++ " passed!")
      else println(infomsg ++ " failed!")
  mask<local>{f()}

// A scoped grouping of tests with some name (could be a single test, or a subgroup of tests) 
fun istest/scope(name: string, is-test: bool, f: () -> <test-scope,console|e> (), ?kk-module: string, ?kk-line: string): <test-scope,console|e> ()
  val sname = if is-test then "test" else "group"
  val infomsg = indentation ++ sname ++ "(" ++ name ++ " : " ++ ?kk-module ++ ":" ++ ?kk-line ++ "):" 
  println(infomsg ++ "... ")
  var anyfail := False
  with override
    val indentation = indentation ++ "  "
    val scope-name = name
    fun report-fail() 
      anyfail := True
      report-fail()
    return(x)
      if !anyfail then println(infomsg ++ " passed!")
      else println(infomsg ++ " failed!")
  f()

// A subgroup of tests
pub fun subgroup(name: string, f: () -> <test-scope,console|e> (), is-test: bool = False, ?kk-module: string, ?kk-line: string): <test-scope,console|e> ()
  scope(name, is-test, f)

// A test 
pub fun test(name: string, f: () -> <test,test-scope,console,pure|e> (), ?kk-module: string, ?kk-line: string): <console,test-scope,pure|e> ()
  subgroup(name, {test_(f)}, is-test=True)

// Runs a test function and prints the first failure including details or "Passed" if all expectations pass in the test
fun test_(f: () -> <test,test-scope,console,pure|e> (), ?kk-module: string, ?kk-line: string): <console,test-scope,pure|e> ()
  with handler
    ctl test-expect(v)
      val Expect-value(a, b, err, cont, location, eq, showa) = v
      match a
        Error(e) ->
          println(indentation ++ "  Expect(" ++ location ++ ") == " ++ b.show(?show=showa) ++ ": threw an exception: " ++ e.exn/show ++ err.map(fn(e1) "\n    Details: " ++ e1).default(""))
          report-fail()
          if cont then 
            match b
              ExpectedValue(b') -> resume(b') 
              _ -> ()
          else ()
        Ok(a') ->
          val good = match b
            ExpectedValue(b') -> a'.eq(b')
            ExpectedError(_) -> False
            ExpectedAssertion(_) -> True 
          if good then 
            resume(a')
          else
            report-fail()
            println(indentation ++ "  Expect(" ++ location ++ ") == " ++ b.show(?show=showa) ++ ": but got: " ++ a'.showa ++ err.map(fn(e) "\n    Details: " ++ e).default(""))
            if cont then 
              match b
                ExpectedValue(b') -> resume(b') 
                _ -> ()
            else ()
  f()

// Some simple examples
fun test-tests(): <console,pure|e> ()
  group("Basics")
    with subgroup("A subgroup")
    test("Returns continue tests")
      val res = expect-result(1) 
                  2
      println("Continued!")
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