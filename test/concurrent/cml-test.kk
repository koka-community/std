import std/test
import std/concurrent/cml
import std/async/async
import std/time/duration
import uv/event-loop

fun main()
  run-tests(suite)

pub fun suite()
  effectful-test("concurrent updates")
    val ch = cml/channel()
    expect(((), 1))
      interleaved(
        {
          select([
            ch.send-op(1),
            
            // timeout-op is a little more efficient, but these two
            // are effectively identical
            timeout-op(1.seconds),
            async-op { wait(2.seconds) },
          ])
        },
        { select(ch.receive-op()) }
      )
