// Implementation of CML primitives based on the guile scheme
// implementation described in:
// https://wingolog.org/archives/2017/06/29/a-new-concurrent-ml
//
// Multithreaded ref operations:
// Performing a `get` on a ref containing a simple value is a cheap memory read.
// But a get on a ref containing a heap allocated object uses locking under the hood.
// Therefore we prefer to use `get` followed by `compare-and-set` for value types, but for reference types
// we usually prefer `get-and-update` since that has the same overhead as a `get`.

import std/concurrent/atomic
import std/async/async
import uv/timer
import uv/event-loop
import std/time/duration
import std/num/int32
import std/data/buffer
import std/core/list

type opstate
  Waiting // ready
  Claimed // possible to synchronise, will soon transition to Done or back to Waiting
  Done // synchronisation complete

struct send-op<a>
  value: a
  continuation: (()) -> io-noexn ()
  state: ref<global, opstate>

struct recv-op<a>
  continuation: (a) -> io-noexn ()
  state: ref<global, opstate>

struct channel<a>
  send-queue: ref<global,list<send-op<a>>>
  receive-queue: ref<global,list<recv-op<a>>>

fun channel<a>(): alloc<global> channel<a>
  Channel(ref(Nil), ref(Nil))

struct atomic-op<a>
  // try to resolve without blocking
  optimistic: () -> io-noexn maybe<a>

  // block until resolved. Optionally returns a cleanup function to invoke when NOT selected
  pessimistic: (ref<global,opstate>, a -> io-noexn ()) -> <io-noexn> (maybe<() -> io-noexn ()>)

type op<a>
  AtomicOp(base: atomic-op<a>)
  AsyncOp(f: () -> <async,io> a) // TODO noexn?

fun async-op(action: () -> <async,io> a): op<a>
  AsyncOp(action)

fun receive-op(channel: channel<a>): op<a>
  AtomicOp(Atomic-op(
    optimistic = fn()
      fun retry() {
        val sendq = !channel.send-queue
        match sendq
          Cons(send-op, tail) ->
            if (!send-op.state).is-Done then {
              // GC the completed operation and retry
              val _: bool = channel.send-queue.compare-and-set(sendq, tail)
              retry()
            } else {
              // TODO: loop, removing any `Done` ops?
              if send-op.state.compare-and-set(Waiting, Done) then
                // try to GC this operation, but don't worry if not
                val _: bool = channel.send-queue.compare-and-set(sendq, tail)
                send-op.continuation.(()) // TODO: spawn?
                Just(send-op.value)
              else
                Nothing
            }
          _ -> Nothing
      }
      retry()
    ,
    pessimistic = fn(opstate, continuation)
      // publish, others may resume us from this point
      val this-op = Recv-op(continuation, opstate)
      channel.receive-queue.get-and-update fn(q) Cons(this-op, q)

      fun retry() {
        val sendq = !channel.send-queue
        match sendq
          Nil -> () // no ready senders, will be woken up when one arrives
          Cons(send-op, tail) -> {
            if this-op.state.compare-and-set(Waiting, Claimed) then {
              // this-op is claimed, now complete sender
              if send-op.state.compare-and-set(Waiting, Done) then {
                // Claimed -> Done
                this-op.state.set(Done)

                // Ignore failure, someone else will clean it up if this fails
                val _: bool = channel.send-queue.compare-and-set(sendq, tail)
                
                // todo: spawn these?
                // TODO: why does this need disambiguation?
                this-op.recv-op/continuation.(send-op.value)
                send-op.send-op/continuation.(())
              } else {
                // conflict on send-op
                this-op.state.set(Waiting)
                if (!send-op.state).is-Done then
                  // send-op already completed; try to GC and try again
                  val _: bool = channel.send-queue.compare-and-set(sendq, tail)
                  ()
                retry()
              }
            } else { // this-op is not Waiting, must be Done. Someone else completed me
              ()
            }
          }
      }
      retry()
      Nothing
  ))


fun send-op(channel: channel<a>, value: a): op<()>
  AtomicOp(Atomic-op(
    optimistic = fn()
      fun retry() {
        val recvq = !channel.receive-queue
        match recvq
          Cons(recv-op, tail) ->
            if (!recv-op.state).is-Done then {
              // GC the completed operation and retry
              val _: bool = channel.receive-queue.compare-and-set(recvq, tail)
              retry()
            } else {
              // TODO: loop, removing any `Done` ops?
              if recv-op.state.compare-and-set(Waiting, Done) then
                // try to GC this operation, but don't worry if not
                val _: bool = channel.receive-queue.compare-and-set(recvq, tail)
                recv-op.continuation.(value) // TODO: spawn?
                Just(())
              else
                Nothing
            }
          _ -> Nothing
      }
      retry()
    ,
    pessimistic = fn(opstate, continuation) {
      // publish, others may resume us from this point
      val this-op = Send-op(value, continuation, opstate)
      channel.send-queue.get-and-update fn(q) Cons(this-op, q)

      fun retry() {
        val recvq = !channel.receive-queue
        match recvq
          Nil -> () // no ready receivers, will be woken up when one arrives
          Cons(recv-op, tail) -> {
            if this-op.state.compare-and-set(Waiting, Claimed) then {
              // this-op is claimed, now complete receiver
              if recv-op.state.compare-and-set(Waiting, Done) then {
                // Claimed -> Done
                this-op.state.set(Done)

                // Ignore failure, someone else will clean it up if this fails
                val _: bool = channel.receive-queue.compare-and-set(recvq, tail)
                
                // todo: spawn these?
                // TODO: why does this need disambiguation?
                recv-op.recv-op/continuation.(value)
                this-op.send-op/continuation.(())
              } else {
                // conflict on recv-op
                this-op.state.set(Waiting)
                if (!recv-op.state).is-Done then
                  // send-op already completed; try to GC and try again
                  val _: bool = channel.receive-queue.compare-and-set(recvq, tail)
                  ()
                retry()
              }
            } else { // my recv-op is not Waiting, must be Done. Someone else completed me
              ()
            }
          }
      }
      retry()
      Nothing
    }
  ))

fun timeout-op(duration: duration): op<()>
  AtomicOp(Atomic-op(
    optimistic = fn() Nothing,
    pessimistic = fn(opstate, continuation) {
      // Need to guard against concurrent completion.
      fun maybe-continue()
        if opstate.compare-and-set(Waiting, Done) then
          // only continue if we're the first to resolve
          continuation(())
      val t = set-timeout(maybe-continue, duration.milli-seconds.int32)
      // cleanup if not selected
      Just({ clear-timeout(t) })
    }
  ))

// Select from one of multiple atomic operations
fun select-op(ops: list<atomic-op<a>>): atomic-op<a>
  match ops
    Cons(e, Nil) -> e
    ops ->
      // TODO randomise visiting order?
      Atomic-op(
        optimistic = fn() {
          ops.foreach-while fn(op)
            op.optimistic.()
        },
        pessimistic = fn(opstate, continuation) {
          val cleanups: ref<global,list<(int, () -> io-noexn ())>> = ref([])
          val installed: ref<global,bool> = ref(False)

          fun do-cleanup(chosen-id: maybe<int>)
            if !installed then { // Note: ! is ref.get, not boolean negate
              (!cleanups).foreach fn((cleanup-id, cleanup-fn))
                val is-this = (match chosen-id
                  Nothing -> False
                  Just(chosen-id) -> chosen-id == cleanup-id
                )
                if !is-this then
                  cleanup-fn()
            } else {
              do-cleanup(chosen-id) // spin loop until ready
            }

          fun continue-after-cleanup(this-id)
            return fn(value)
              do-cleanup(Just(this-id))
              continuation(value)

          ops.foreach fn(op) {
            // we pass the same continuation to each pessimistic
            // function, we're guaranteed that only one will actually
            // be invoked. We annotate each op with an ID so that when
            // any of them complete. we can cleanup all others.
            val id = unique()
            // TODO: just use the list index as an ID, and set array items. Can use a sentinel
            // value in the array to indicate not-ready

            // TODO: it's possible for another thread to complete this op concurrently
            // before we've modified cleanups.
            // We should add a guard so that we wait for the cleanup fn to be populated
            // if resolved concurrently
            val cleanup = op.pessimistic.(opstate, continue-after-cleanup(id))
            match cleanup
              Nothing -> ()
              Just(f) ->
                cleanups.get-and-update(fn(c) Cons((id, f), c))
                ()
          }
          installed.set(True) // all operations setup
          Just({ do-cleanup(Nothing) }) // cleanup all if none were selected
        }
      )

fun try-complete(opstate: ref<global,opstate>): <div,st<global>> bool
  if (!opstate).is-Done then
    False
  else
    if opstate.compare-and-set(Waiting, Done) then
      True
    else
      try-complete(opstate)

fun perform-async(opstate, action: () -> <async,io> a): <async,io> a
  val result = try(action)
  if try-complete(opstate) then
    result.untry
  else
    // Operation already complete, we expect to be
    // cancelled so just suspend.
    await0(fn(cb) ())
    throw("Impossible")

fun partition-either(items: list<a>, f: (a) -> either<l,r>): (list<l>, list<r>)
  var lefts := buffer()
  var rights := buffer()
  items.foreach fn(item)
    match f(item)
      Left(left) -> lefts := lefts.append(left)
      Right(right) -> rights := rights.append(right)
  (lefts.list, rights.list)

// Select over a number of possible operations.
// Atomic operations will occur transactionally, while
// async operations will not (but they will still
// race for completion correctly with atomic ops).
pub fun select(ops: list<op<a>>): <async, io> a
  val opstate: ref<global, opstate> = ref(Waiting)
  val (atomic-ops, async-ops) = ops.partition-either fn(op)
    match op
      AtomicOp(e) -> Left(e)
      AsyncOp(e) -> Right(e)

  match (atomic-ops, async-ops)
    (Nil, Nil) -> throw("unsupported")
    
    // single async
    (Nil, Cons(a,Nil)) -> perform-async(opstate, a)

    // 1+ atomic, no async
    (atomic-ops, Nil) ->
      perform(opstate, select-op(atomic-ops))
    
    // 0+ atomic, 1+ async
    (atomic-ops, asyncs) ->
      val async-thunks = asyncs.map(fn(a) fn() perform-async(opstate, a))
      val all-thunks: list<() -> <async,io> _> = (match atomic-ops
        Nil -> async-thunks
        atomic-ops -> Cons({ perform(opstate, select-op(atomic-ops)) }, async-thunks)
      )
      list/firstof(all-thunks)
      
pub fun single/select(op: op<a>): <async,io> a
  // TODO optimise
  select([op])

// TODO this could be done more efficiently directly in async module
fun list/firstof(thunks: list<() -> <async,io> a>): <async,io> a
  // returns a thunk
  fun firstof-nel(head: () -> <async,io> a, tail: list<() -> <async,io> a>): (() -> <async,io> a)
    match tail
      Nil -> head
      Cons(head2, tail2) ->
        val exec-tail = firstof-nel(head2, tail2)
        fn() async/firstof(head, exec-tail)

  match thunks
    Nil -> throw("impossible")
    Cons(head, tail) -> firstof-nel(head, tail).()

// Internal
fun atomic/perform(opstate: ref<global,opstate>, op: atomic-op<a>): <async,io-noexn, exn> a
  match op.optimistic.()
    Just(result) -> result
    Nothing ->
      await1 fn(continuation)
        op.pessimistic.(opstate, continuation)
        // ignore cleanup for a single op, it will always be selected
        // (TODO: support async cancelation)
        ()
