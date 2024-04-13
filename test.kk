/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

// The test effect
pub effect test
  ctl test-expect(v: expect-value<a>): a

pub effect test-scope
  val scope-name: string
  val indentation: string
  fun report-fail(): ()

// An expected value for a test
struct expect-value<a>
  run-value: error<a> // The value of the computation when run
  expect-value: a // The expected value
  details: maybe<string> // An additional error message providing context of the expectation
  econtinue: bool // Whether to continue with the expected value
  location: string // The line where the expectation was made
  eq: (a,a) -> pure bool // The equality function for the value
  show: (a) -> pure string; // The show function for the value

// Expects a computation to return a value
//
// The expected type must have an `(==)` function as well as a `show` function defined for it
pub fun expect(expected: a, run: () -> <exn,test|e> a, details: string = "", econtinue=True, ?(==): (a,a) -> pure bool, ?show: (a) -> pure string, ?kk-line: string, ?kk-module: string): <test|e> a
  val res = try({run()})
  test-expect(Expect-value(
    res, 
    expected, 
    if details == "" then Nothing else Just(details), 
    True,
    ?kk-module ++ ":" ++ ?kk-line, 
    (==), show))

pub fun expect-fail(expected: a, run: () -> <exn,test|e> a, details: string = "", econtinue=False, ?(==): (a,a) -> pure bool, ?show: (a) -> pure string, ?kk-line: string, ?kk-module: string): <test|e> ()
  expect(expected, run, details, econtinue)
  ()

pub fun basic/test(name: string, f: () -> <test,test-scope,console,pure|e> (), ?kk-module: string, ?kk-line: string): <console,pure|e> ()
  basic/scope(
    name, 
    { test-scoped(name, f) }
    ,is-test=True
  )

fun istest/scope(name: string, is-test: bool, f: () -> <test-scope,console|e> (), ?kk-module: string, ?kk-line: string): <test-scope,console|e> ()
  val sname = if is-test then "Test" else "Scope"
  println(indentation ++ sname ++ "(" ++ ?kk-module ++ ":" ++ ?kk-line ++ "): " ++ name ++ " ... ")
  var anyfail := False
  with override
    val indentation = indentation ++ "  "
    val scope-name = name
    fun report-fail() 
      anyfail := True
      report-fail()
    return(x)
      if !anyfail then println("Passed!")
      else println("")
  f()

pub fun basic/scope(name: string, f: () -> <test-scope,console|e> (), is-test: bool = False, ?kk-module: string, ?kk-line: string): <console|e> ()
  val sname = if is-test then "Test" else "Scope"
  println(sname ++ "(" ++ ?kk-module ++ ":" ++ ?kk-line ++ "): " ++ name ++ " ... ")
  var anyfail := False
  with handler
    val indentation = "  "
    val scope-name = name
    fun report-fail() 
      anyfail := True
    return(x)
      if !anyfail then println("Passed!")
      else println("")
  mask<local>{f()}

pub fun basic-nested/scope(name: string, f: () -> <test-scope,console|e> (), is-test: bool = False, ?kk-module: string, ?kk-line: string): <test-scope,console|e> ()
  istest/scope(name, is-test, f)

pub fun scoped/test(name: string, f: () -> <test,test-scope,console,pure|e> (), ?kk-module: string, ?kk-line: string): <console,test-scope,pure|e> ()
  basic-nested/scope(name, {test-scoped(name, f)}, is-test=True)

// Runs a test function and prints the first failure including details or "Passed" if all expectations pass in the test
pub fun test-scoped(name: string, f: () -> <test,test-scope,console,pure|e> (), ?kk-module: string, ?kk-line: string): <console,test-scope,pure|e> ()
  with handler
    ctl test-expect(v)
      val Expect-value(a, b, err, cont, location, eq, showa) = v
      match a
        Error(e) ->
          println(indentation ++ "  Expect(" ++ location ++ ") == " ++ b.showa ++ ": threw an exception: " ++ e.exn/show ++ err.map(fn(e1) "\n    Details: " ++ e1).default(""))
          report-fail()
          if cont then resume(b)
          else ()
        Ok(a') ->
          if a'.eq(b) then
            resume(a')
          else
            report-fail()
            println(indentation ++ "  Expect(" ++ location ++ ") == " ++ b.showa ++ ": but got: " ++ a'.showa ++ err.map(fn(e) "\n    Details: " ++ e).default(""))
            if cont then resume(b) 
            else ()
  f()

// Some simple examples
fun test-tests()
  basic/scope("Basics")
    with basic-nested/scope("Another")
    scoped/test("Returns continue tests")
      val res = expect(1) fn() 2
      println("Continued!")
      expect-fail(2) fn() 1 + res
      expect-fail(2) fn() 1
  basic/test("Wrong expect")
    expect-fail(1) fn() 2
  basic/test("Additional info")
    expect-fail(1, {throw("Some error somewhere")}, details="Really expected 1 because I proved it!") 