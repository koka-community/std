import std/data/hashset
import std/data/hash
import std/test


fun suite()
  group("hash-set")
    test("insert")
      val hs = thread/hash-set(1)
      expect(True)
        val hs' = hs.insert(2)
        hs'.contains(2)
    test("remove")
      val hs = thread/hash-set(1)
      val hs' = hs.insert(2)
      expect(0)
        hs'.remove(2).length
    test("stress test")
      var hs := thread/hash-set(1)
      expect(True)
        for(50000) fn(i)
          hs := hs.insert(i)
        True
    test("clear")
      var hs := thread/hash-set(1)
      for(50) fn(i)
        hs := hs.insert(i)
      expect(0)
        hs := hs.clear
        hs.length
    test("clear then fill")
      var hs := thread/hash-set(1)
      for(50) fn(i)
        hs := hs.insert(i)
      expect(50)
        hs := hs.clear
        for(50) fn(i)
          hs := hs.insert(i)
        hs.length