module std/test/report
import std/test/test
import std/pretty/printer

pub fun report-scope-once(reported-scopes: ref<global, list<int>>, scope: maybe<test-scope>, report: (test-scope) -> <st<global>,div|e> ()): <st<global>,div|e> ()
  match scope
    Nothing -> ()
    Just(scope) ->
      report-scope-once(reported-scopes, scope.parent, report)
      val reported = !reported-scopes
      if reported.find(fn(id) -> id == scope.scope-id).is-nothing then
        reported-scopes := Cons(scope.scope-id, reported)
        report(scope)

pub fun plain-reporter(action: () -> <test-report,io|e> ()): <io|e> ()
  val reported-scopes = ref([])

  with handler <test-report>
    fun report-skipped(test)
      ()

    fun report-iteration(test)
      ()

    fun report-start(test)
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
      println(test.scope.indentation() ++ "  " ++ failed-expectation.show-failed())

    fun report-summary(summary: suite-summary)
      println(summary.failures.show ++ " failures, " ++ summary.successes.show ++ " successes")

  mask<local>(action)

pub fun color-reporter(action: () -> <test-report,io|e> ()): <io|e> ()
  val reported-scopes = ref([])
  var failed-test-names := []
  var hint-buffer-rev := []

  with ansi-printer
  with handler <test-report>
    fun report-skipped(test)
      ()

    fun report-start(test)
      hint-buffer-rev := []
      report-scope-once(reported-scopes, test.scope) fn(scope)
        println-colored(scope.parent.indentation ++ scope.scope-name ++ ":", Cyan)
      println-colored(test.scope.indentation ++ test.name ++ "(" ++ test.location.show ++ ")...", Cyan)

    fun report-hint(test, hint)
      // accumulate and only output on failure
      hint-buffer-rev := Cons(hint, hint-buffer-rev)

    fun report-iteration(test)
      hint-buffer-rev := []

    fun report-end(test, failures: int)
      if failures == 0 then
        println-colored(test.scope.indentation ++ "- ok", Green)
      else
        hint-buffer-rev.reverse.foreach fn(hint)
          println-colored(test.scope.indentation ++ hint, Yellow)

        println-colored(test.scope.indentation ++ "- failed\n", Red)
        failed-test-names := Cons(test.full-name, failed-test-names)

    fun report-failure(test: test-identity, failed-expectation)
      println-colored(test.scope.indentation() ++ failed-expectation.show-failed(), Red)

    fun report-summary(summary: suite-summary)
      val color = if summary.failures > 0 then Red else Green
      println-colored(
        summary.failures.show ++ " failures, " ++ summary.successes.show ++ " successes"
        ++ (if summary.skipped > 0 then " (" ++ summary.skipped.show ++ " skipped)" else "")
      , color)

      if summary.failures > 0 then
        println-colored("\nFailed tests:", Red)
        failed-test-names.foreach fn(name)
          println-colored(" - " ++ name, Red)

  with mask<printer>
  with mask<coloredPrinter>
  with mask<local>
  action()

