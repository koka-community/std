import std/test
import std/num/int32
import std/num/int64
import std/async/async
import std/async/timer
import std/time/duration
import std/core-extras
import std/core/unsafe

// workaround for https://github.com/koka-community/std/issues/30
fun list/expect(x: list<a>, f: () -> <exn,expect|e> list<a>, ?(==): (a, a) -> bool, ?show: (a) -> string): <expect|e> ()
  test/expect(x, f, ?(==)=list/(==))
fun maybe/expect(x: maybe<a>, f: () -> <exn,expect|e> maybe<a>, ?(==): (a, a) -> bool, ?show: (a) -> string): <expect|e> ()
  test/expect(x, f, ?(==)=maybe/(==))

fun list/push(l, item)
  l ++ [item]

fun listref/push(lr: ref<_, list<a>>, item: a, ?show: (a) -> string)
  // println("PUSH: " ++ item.show)
  lr.modify fn(l)
    l := l.push(item)

val short-pause = 1.milli-seconds
val long-pause = 100.milli-seconds

// rbset doesn't have remove, and hashset doesn't work in JS
fun listset/add(l: list<v>, v: v, ?(==): (v, v) -> bool): list<v>
  if l.find(fn(i) i == v).is-just then l
  else Cons(v,l)

fun listset/remove(l: list<v>, v: v, ?(==): (v, v) -> bool): list<v>
  l.list/remove(fn(i) i == v)

fun noleaks(action: () -> <async,io|e> ()): <async,io|e> ()
  val pending: ref<global,list<(int, async/scope)>> = ref([])

  fun register(api, scope: async/scope)
    val id = unique()
    val entry = (id, scope)
    // println("[track-leaks " ++ api ++ "] -> [" ++ entry.show ++ "]")

    pending := (!pending).add(entry)
    fun done(result)
      // unsafe-total
      //   println("[track-leaks " ++ api ++ "] <- [" ++ entry.show ++ "] cancel=" ++ result.is-cancel.show)
      pending := (!pending).remove(entry)
    done

  with handler<async>
    fun do-await(setup, scope)
      val done = register("do-await", scope)
      val result = do-await(setup, scope)
      done(result)
      result

    fun no-await(setup,scope,f)
      val done = register("no-await", scope)
      no-await(setup, scope) fn(result)
        done(result)
        f(result)

    fun async-iox(f)
      async-iox(f)

    fun cancel-scope(scope)
      cancel-scope(scope)

    val async-scope = async-scope
    fun discontinue() discontinue()

  with mask behind<async>
  with finally
    if ! (!pending).is-empty then
      // println("[track-leaks] pending=" ++ (!pending).map(fst).show)
      throw("Test leaked " ++ (!pending).length.show ++ " async callbacks")
  action()

effect audit<a>
  fun record(value: a): ()
  fun records(): list<a>

// fun audit(action: () -> <audit<a>,expect,div|e> b, ?show: (a) -> div string): <div,expect|e> b
fun audit(action: () -> <audit<a>,expect,div,console|e> b, ?show: (a) -> div string): <div,console,expect|e> b
  var log := []
  handle(action)
    fun record(value)
      // TODO `hint` instead of println
      // println("record: " ++ value.show)
      log := log.push(value)
      ()
    fun records() -> log

fun error-message(err: error<_>): maybe<string>
  match err
    Error(ex) -> Just(ex.message)
    Ok(_) -> Nothing

fun noleak-test(name, body, ?kk-module, ?kk-line)
  // effectful-test("[vanilla] " ++ name, body) // rule out interference by noleaks itself
  effectful-test(name) { noleaks(body) }


effect flip
  ctl flip(): bool

fun both(f: () -> <flip|e> a): e list<a>
  handle(f)
    return(x) [x]
    ctl flip()
      resume(False) ++ resume(True)

fun main(): <io-noexn,async> ()
  run-tests
    group("noleaks")
      effectful-test("fails if a block leaks a callback")
        val result = try
          with noleaks
          no-await(fn (cb) { Nothing }, async-scope, fn(_) {})
        expect(Just("Test leaked 1 async callbacks")) { result.error-message }

      effectful-test("doesn't interfere with async execution")
        val result = try
          with noleaks
          wait(short-pause)
          throw("fail!")
        expect(Just("fail!")) { result.error-message }

    noleak-test("simple sleep")
      expect(123)
        wait(short-pause)
        123

    noleak-test("interleaved singleton")
      expect([1])
        fun action()
          wait(short-pause)
          1
        interleaved([action])

    noleak-test("interleaved singleton which throws")
      with audit
      fun action()
        with finally
          record("finally")
        wait(short-pause)
        throw("error")

      expect(Just("error"))
        try { interleaved([action]) }.error-message

      expect(["finally"]) { records() }

    noleak-test("interleaved pair")
      val pair =
        interleaved {
          wait(short-pause)
          1
        } {
          wait(short-pause)
          2
        }
      expect((1,2)) { pair }

    noleak-test("cancel the scope above an interleave")
      with audit
      val result = unsafe-catch-cancel
        with child-scope
        val outer-scope = async-scope
        interleaved {
          wait(short-pause)
          outer-scope.cancel()
        } {
          with finally
            record("finally")
            wait(long-pause)
          "strand 2 complete"
        }
      expect(["finally"]) { records() }
      expect(True) { result.is-cancel }

    noleak-test("firstof doesn't run more actions if the first is synchronous")
      with audit
      val result = firstof {
        1
      } {
        wait(short-pause)
        record("second branch executed")
        2
      }
      expect(result) { 1 }
      expect([]: list<string>) { records() }

    noleak-test("firstof doesn't spawn further actions if the first raises synchronously")
      with audit
      val result = try
        firstof {
          throw("branch 1")
        } {
          wait(short-pause)
          record("second branch executed")
        }
      expect(Just("branch 1")) { result.error-message }
      expect([]: list<string>) { records() }

    noleak-test("interleave doesn't spawn further actions if the first raises synchronously")
      with audit
      val result = try
        interleaved([{
          throw("branch 1")
        }, {
          wait(short-pause)
          record("second branch executed")
        }])
      expect(Just("branch 1")) { result.error-message }
      expect([]: list<string>) { records() }

    noleak-test("interleave with finalization after exn")
      with audit
      val result = try
        interleaved {
          wait(short-pause)
          throw("strand 1 failed")
        } {
          with finally
            record("finally")
          on-cancel {
            record("cancel")
          } {
            wait(long-pause)
          }
          "strand 2 complete"
        }
      expect(["cancel", "finally"]) { records() }
      expect(Just("strand 1 failed")) { result.error-message }


    noleak-test("firstof with finalization in slower branch")
      with audit
      val result = firstof {
        wait(short-pause)
        1
      } {
        with finally
          record("finally")
        on-cancel {
          record("cancel")
        } {
          wait(long-pause)
        }
        2
      }
      expect(["cancel", "finally"]) { records() }
      expect(1) { result }

    noleak-test("finalization can be async")
      val log = ref([]: list<string>)
      fun long-running()
        fun cleanup()
          wait(long-pause)
          log.push("cleanup")
        
        with finally(cleanup)
        log.push("start")
        wait(long-pause) // <- will be canceled
        log.push("wakeup")
        "long"

      fun short-running()
        wait(short-pause)
        log.push("cancel")
        "short"

      val result = firstof(long-running, short-running)
      log.push("result: " ++ result)
      val e = list/(==)(["a"], ["b"])
      expect(["start", "cancel", "cleanup", "result: short"]) { !log }

    noleak-test("cancellation and try")
      with audit
      fun interruptible()
        with finally { record("finally") }
        try {
          record("start")
          wait(long-pause)
        } fn(e) {
          record("catch")
        }
        record("after-catch")
        wait(short-pause)
        record("still running...")
        "result"

      expect(Nothing: maybe<string>)
        timeout(short-pause, interruptible)

      expect(["start", "finally"]) { records() }

    noleak-test("error in cancelation is raised")
      fun interruptible()
        with finally { throw("finalization exn") }
        wait(long-pause)
        "result"

      expect("finalization exn")
        try {
          timeout(short-pause, interruptible)
          "success"
        } fn(e) { e.message }

    noleak-test("exception in main code takes priority over error in cancelation")
      fun interruptible()
        with finally { throw("finalization exn") }
        wait(long-pause)
        "main exn"

      expect("finalization exn")
        try {
          firstof(interruptible)
            wait(short-pause)
            throw("main exn")
          "success"
        } fn(e) { e.message }

    noleak-test("defer-cancelation defers cancelation signal until block is complete")
      val log = ref([]: list<string>)
      fun interruptible()
        defer-cancelation
          wait(long-pause)
          log.push("in critical section")
        log.push("after critical section")

      expect(Nothing) { timeout(short-pause, interruptible) }
      expect(["in critical section"]) { !log }

    noleak-test("a cancelable block within a defered-cancelation block is canceled immediately")
      with audit
      fun interruptible()
        defer-cancelation()
          fun inner()
            on-cancel { record("inner canceled") }
              wait(long-pause)
            record("inner still running after cancel")
          timeout(short-pause, inner)
          record("after-inner")
        record("after-defer")
      timeout(short-pause, interruptible)
      expect(["inner canceled", "after-inner"]) { records() }

    // TODO: this currently fails at runtime with `ev_10958.hnd._ctl_flip is not a function`
    // noleak-test("multiple resumption works within async")
    //   with audit
    //   val result = both
    //     wait(short-pause)
    //     if flip() then
    //       wait(short-pause)
    //       record(True)
    //       "heads"
    //     else
    //       record(False)
    //       "tails"
    //   expect([True, False]) { records() }
    //   expect(["heads", "tails"]) { result }
