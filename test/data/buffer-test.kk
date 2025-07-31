import std/data/buffer
import std/test
import std/num/random

fun suite()
  group("buffer")
    test("can be empty")
      val empty: list<string> = []
      expect(empty)
        val result: buffer<string> = buffer()
        buffer().list
    test("collects data")
      expect([1, 10, 100])
        var buffer := buffer()
        buffer := buffer.append(1)
        buffer := buffer.append(10)
        buffer := buffer.append(100)
        buffer.list
    test("buffer stress test")
      with pseudo-random(0)
      var buffer := buffer()
      expect(True)
        for(50000) fn(i)
          buffer := buffer.append(random-int())
        True
   