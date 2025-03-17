// import std/async/async
import std/time/timer
import std/time/duration
import std/num/int32
import std/async/timer

/* Scheduler abstraction.

This module contains a test scheduler to be used
by ./async.kk for simulating time in async functions.
*/

// Internal effect exposed to low-level async `setup` functions.
// The `schedule-timeout` and `schedule-clear-timeout` functions are used by the
// corresponding async functions in preference to directly using
// timer's `raw/set-timeout` and `raw/clear-timeout`,
// as the schedule effect allows a simulated clock for tests.
pub effect schedule
  fun schedule-timeout( cb : () -> io-noexn (), ms : int32 ) : any
  fun schedule-clear-timeout(tid: any) : ()

ref struct thunk<e>
  delay: int32
  action: () -> e ()

fun thunk/cmp(a: thunk<_>, b: thunk<_>): order
  a.delay.cmp(b.delay)

ref struct state
  thunks: list<thunk<io-noexn>>
  start: duration // base time for this scheduler
  elapsed-ms: int32 // how far past start we've advanced

fun state/initial<e>(start: duration)
  State(
    thunks = [],
    start = start,
    elapsed-ms = int32/zero
  )

fun state/pop(s: state)
  match s.thunks
    Nil -> Nothing
    Cons(head, tail) ->
      val newstate = s(
        elapsed-ms = s.elapsed-ms + head.delay,
        thunks = tail.map fn(i) i(delay = i.delay - head.delay)
      )
      Just((head, newstate))

fun state/add(s: state, thunk: thunk<io-noexn>): state
  s(thunks = s.thunks.insert-sorted(thunk))

fun insert-sorted(lst: list<a>, item: a, ?cmp: (a,a) -> order): list<a>
  match lst
    Nil -> [item]
    Cons(head, tail) ->
      if (item < head) then
        Cons(item, Cons(head, tail))
      else
        Cons(head, insert-sorted(tail, item))

value struct test-scheduler
  state: ref<global, state>

pub fun make-test-scheduler(): io-noexn test-scheduler
  val state = ref(state/initial(timer/ticks()))
  Test-scheduler(state)

// Note: this is spawned from a context where async is not allowed,
// so we use set-timeout internally to schedule another execution
fun scheduler/drain(scheduler: test-scheduler): <io-noexn> ()
  val popped = scheduler.state.modify fn(state)
    match state.pop()
      Nothing ->
        Nothing
      Just((thunk, newstate)) ->
        state := newstate
        Just(thunk)

  match popped
    Nothing -> ()
    Just(thunk) ->
      (thunk.action)()
      raw/set-timeout({ scheduler.drain() }, int32/zero)
      ()

fun scheduler/schedule(scheduler: test-scheduler, cb: () -> io-noexn (), ms: int32): <io-noexn> any
  val thunk = Thunk(ms, cb)
  scheduler.state.modify fn(s)
    // TODO store a tid in thunk for later cancellation
    s := s.add(thunk)
  raw/set-timeout({ scheduler.drain() }, int32/zero)

fun scheduler/clear-timeout(scheduler: test-scheduler, tid: any)
  println("TODO: clear-timeout")

fun scheduler/ticks(scheduler: test-scheduler): read<global> duration
  val state = !scheduler.state
  state.start + int/milli-seconds(state.elapsed-ms.int)

fun handle-schedule(scheduler: test-scheduler, action: () -> <schedule,io-noexn|e> a): <io-noexn|e> a
  handle <schedule>(action)
    fun schedule-timeout(cb, ms)
      scheduler.schedule(cb, ms)

    fun schedule-clear-timeout(tid)
      scheduler.clear-timeout(tid)
