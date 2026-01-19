import std/data/hash-map
import std/data/hash
import std/test
import std/num/random

pub fun main()
  run-tests(suite)

pub fun suite()
  group("hash-map")
    test("insert")
      val hm = hash-map()
      expect(Just(2))
        val hm' = hm.insert(1, 2)
        hm'.get(1)
    test("remove")
      val hm = hash-map()
      val hm' = hm.insert(1, 2)
      expect(0)
        hm'.remove(1 ).length
    test("overwrite")
      val hm = hash-map()
      val hm' = hm.insert(1, 2)
      expect(Just(3))
        val hm@ = hm'.insert(1, 3)
        hm@.get(1)
    test("stress test")
      var hm := hash-map()
      expect(True)
        for(50000) fn (i)
          hm := hm.insert(i, i)
        True
    test("clear")
      var hm := hash-map()
      for(50) fn (i)
        hm := hm.insert(i, i)
      expect(0)
        hm := hm.clear()
        hm.length
    test("clear then fill")
      var hm := hash-map()
      for(50) fn (i)
        hm := hm.insert(i, i)
      expect(50)
        hm := hm.clear()
        for(50) fn (i)
          hm := hm.insert(i, i)
        hm.length
    test("initialize with random seed")
      expect(0)
        arbitrary { hash-map-seeded(random-int64()) }.length
