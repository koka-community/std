import std/async
import std/time/duration

fun main()
  with async/handle
  catch {
    val x = two/interleaved { wait(1.seconds) } {2}
    println(x) 
  } fn(err) {
    println(err.message.show)
  }
    