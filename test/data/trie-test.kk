import std/data/trie
import std/test

fun suite(): <io,test> ()
  val t = trie/empty().add("Hello")
  val t1 = t.add("World").add("Worship")
  group("trie")
    test("lookup")
      expect(Just("Hello"))
        t1.lookup("Hello")
      expect(Just("Worship"))
        t1.lookup("Worship")
      expect(Nothing)
        t1.lookup("Wor")