import std/test
import std/concurrent/cml
import std/async/async
import std/time/duration
import uv/event-loop

fun main()
  with default-event-loop
  with async/handle
  run-tests(suite)

pub fun suite()
  effectful-test("timeout")
    val ch = cml/channel()
    expect(())
      select([
        ch.send-op(1),
        timeout-op(100.milli-seconds),
      ])

  effectful-test("concurrent updates")
    val ch = cml/channel()
    expect(((), 1))
      interleaved(
        {
          select([
            ch.send-op(1),
            timeout-op(1.seconds),
          ])
        },
        { select(ch.receive-op()) }
      )

  effectful-test("nonterminating op")
    // TODO: doesn't work currently
    val ch = cml/channel()
    expect(((), 1))
      select(ch.receive-op())
