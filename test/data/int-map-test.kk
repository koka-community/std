import std/data/int-map
import std/test
import std/num/int64
import std/core/maybe

fun suite()
  group("int-map")
    test("empty map is empty")
      expect(True)
        int-map/empty().is-empty

    test("set value")
      expect(Just("hello"))
        val m = int-map/empty().set(42.int64, "hello")
        m.lookup(42.int64)

    test("lookup not found")
      expect(Nothing)
        val m = int-map/empty().set(42.int64, "hello")
        m.lookup(43.int64)

    test("set overwrite")
      expect(Just("world"))
        val m = int-map/empty().set(42.int64, "hello").set(42.int64, "world")
        m.lookup(42.int64)

    test("add value")
      expect(Just("hello"))
        val m = int-map/empty().add(42.int64, "hello")
        m.lookup(42.int64)

    test("add existing")
      expect(Just("hello"))
        val m = int-map/empty().set(42.int64, "hello").add(42.int64, "world")
        m.lookup(42.int64)

    test("update insert")
      expect(Just("hello"))
        val m = int-map/empty().update(42.int64, fn(_) Just("hello"))
        m.lookup(42.int64)

    test("update modify")
      expect(Just("helloworld"))
        val m = int-map/empty().set(42.int64, "hello")
        val m' = m.update(42.int64, fn(mb) match mb { Just(v) -> Just(v ++ "world"); Nothing -> Nothing })
        m'.lookup(42.int64)

    test("update remove")
      expect(Nothing)
        val m = int-map/empty().set(42.int64, "hello")
        val m' = m.update(42.int64, fn(_) Nothing)
        m'.lookup(42.int64)

    test("remove element")
      expect(Nothing)
        val m = int-map/empty().set(42.int64, "hello").set(43.int64, "world")
        val m' = m.remove(42.int64)
        m'.lookup(42.int64)

    test("remove non-existent")
      expect(Just("hello"))
        val m = int-map/empty().set(42.int64, "hello")
        val m' = m.remove(99.int64)
        m'.lookup(42.int64)

    test("size empty")
      expect(0)
        int-map/empty().size

    test("size single")
      expect(1)
        int-map/empty().set(42.int64, "a").size

    test("size multiple")
      expect(3)
        int-map/empty().set(1.int64, "a").set(2.int64, "b").set(3.int64, "c").size

    test("from-list")
      expect(3)
        from-list([(1.int64, "a"), (2.int64, "b"), (3.int64, "c")]).size

    test("from-list with duplicates")
      expect(2)
        // Last one wins with set
        val m = from-list([(1.int64, "a"), (2.int64, "b"), (1.int64, "c"), (2.int64, "d")])
        m.size

    test("from-list values")
      expect(Just("c"))
        val m = from-list([(1.int64, "a"), (2.int64, "b"), (1.int64, "c")])
        m.lookup(1.int64)

    test("large map operations")
      expect(5000)
        var m := int-map/empty()
        for(5000) fn(i)
          m := m.set(i.int64, i)
        m.size

    test("map values")
      expect(Just("a!"))
        val m = int-map/empty().set(1.int64, "a").set(2.int64, "b")
        val m' = m.map(fn(v) v ++ "!")
        m'.lookup(1.int64)

    test("map size preserved")
      expect(2)
        val m = int-map/empty().set(1.int64, "a").set(2.int64, "b")
        val m' = m.map(fn(v) v ++ "!")
        m'.size

    test("union empty")
      expect(0)
        union(int-map/empty(), int-map/empty()).size

    test("union disjoint")
      expect(2)
        val m1 = int-map/empty().set(1.int64, "a")
        val m2 = int-map/empty().set(2.int64, "b")
        union(m1, m2).size

    test("union overlap left-biased")
      expect(Just("a"))
        val m1 = int-map/empty().set(1.int64, "a")
        val m2 = int-map/empty().set(1.int64, "b")
        union(m1, m2).lookup(1.int64)

    test("union-with")
      expect(Just("ab"))
        val m1 = int-map/empty().set(1.int64, "a")
        val m2 = int-map/empty().set(1.int64, "b")
        union-with(m1, m2, fn(v1, v2) v1 ++ v2).lookup(1.int64)

    test("union complex")
      expect(3)
        val m1 = int-map/empty().set(1.int64, "a").set(2.int64, "b")
        val m2 = int-map/empty().set(2.int64, "c").set(3.int64, "d")
        val u = union-with(m1, m2, fn(v1, v2) v1 ++ v2)
        if u.lookup(2.int64).unjust == "bc" then u.size else 0

    test("difference empty")
      expect(0)
        difference(int-map/empty(), int-map/empty()).size

    test("difference disjoint")
      expect(1)
        val m1 = int-map/empty().set(1.int64, "a")
        val m2 = int-map/empty().set(2.int64, "b")
        difference(m1, m2).size

    test("difference overlap")
      expect(0)
        val m1 = int-map/empty().set(1.int64, "a")
        val m2 = int-map/empty().set(1.int64, "b")
        difference(m1, m2).size

    test("difference complex")
      expect(1)
        val m1 = int-map/empty().set(1.int64, "a").set(2.int64, "b")
        val m2 = int-map/empty().set(2.int64, "c").set(3.int64, "d")
        val d = difference(m1, m2)
        if d.lookup(1.int64).unjust == "a" then d.size else 0

    test("intersection empty")
      expect(0)
        intersection(int-map/empty(), int-map/empty() : int-map<string>).size

    test("intersection disjoint")
      expect(0)
        val m1 = int-map/empty().set(1.int64, "a")
        val m2 = int-map/empty().set(2.int64, "b")
        intersection(m1, m2).size

    test("intersection is left-biased")
      expect(Just("a"))
        val m1 = int-map/empty().set(1.int64, "a")
        val m2 = int-map/empty().set(1.int64, "b")
        intersection(m1, m2).lookup(1.int64)

    test("intersection keeps only shared keys")
      expect(1)
        val m1 = int-map/empty().set(1.int64, "a").set(2.int64, "b")
        val m2 = int-map/empty().set(2.int64, "c").set(3.int64, "d")
        val i = intersection(m1, m2)
        if i.lookup(2.int64).unjust == "b" then i.size else 0

    test("intersection-with combines both values")
      expect(Just("bc"))
        val m1 = int-map/empty().set(1.int64, "a").set(2.int64, "b")
        val m2 = int-map/empty().set(2.int64, "c").set(3.int64, "d")
        intersection-with(m1, m2, fn(v1, v2) v1 ++ v2).lookup(2.int64)

    // Data.IntMap.intersectionWith KEEPS a shared key whose combined value is
    // "empty" -- the caller filters if it wants otherwise.
    test("intersection-with keeps an empty combined value")
      expect(1)
        val m1 = int-map/empty().set(1.int64, ["a"])
        val m2 = int-map/empty().set(1.int64, ["b"])
        intersection-with(m1, m2, fn(_v1, _v2) ([] : list<string>)).size

    test("intersection-with over a larger map")
      expect([(2.int64, "bb"), (4.int64, "dd")])
        val m1 = [(1.int64,"a"),(2.int64,"b"),(4.int64,"d"),(7.int64,"g")].from-list
        val m2 = [(2.int64,"b"),(3.int64,"c"),(4.int64,"d"),(9.int64,"i")].from-list
        intersection-with(m1, m2, fn(v1, v2) v1 ++ v2).list.reverse

fun main()
  run-tests(suite)
