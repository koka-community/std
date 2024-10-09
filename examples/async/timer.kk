import std/async
import std/time/duration
import std/time/timestamp

// In VSCode Cmd/Ctrl+Shift+P Then select Koka: Compilation target, and switch to nodejs, prior to running this
fun main()
  val res = try
    val x = ref(0)
    timer(1000.milli-seconds) fn(t)
      "Hello From Timer".println
      x := !x + 1
      if !x == 3 then False else True
    wait(1.seconds)
    "Before timeout".println
    wait(10.seconds)
    "Hello After Timeout".println
  println("Done!")
  