import std/data/intset
import std/test
import std/num/int64

fun contains(xs: list<a>, elem: a, ?(==): (a, a) -> bool): bool
  match xs
    Cons(a, rst) -> if a == elem then True else rst.contains(elem)
    Nil -> False

fun suite()
  group("intset")
    test("empty set is empty")
      expect(True)
        intset/empty().is-empty

    test("insert element")
      expect(True)
        val s = intset/empty().insert(42.int64)
        s.member(42.int64)

    test("member not found")
      expect(False)
        val s = intset/empty().insert(42.int64)
        s.member(43.int64)

    test("insert duplicate")
      expect(1)
        val s = intset/empty().insert(42.int64).insert(42.int64)
        s.size

    test("remove element")
      expect(False)
        val s = intset/empty().insert(42.int64).insert(43.int64)
        val s' = s.remove(42.int64)
        s'.member(42.int64)

    test("remove non-existent")
      expect(True)
        val s = intset/empty().insert(42.int64)
        val s' = s.remove(99.int64)
        s'.member(42.int64)

    test("size empty")
      expect(0)
        intset/empty().size

    test("size single")
      expect(1)
        intset/empty().insert(42.int64).size

    test("size multiple")
      expect(3)
        intset/empty().insert(1.int64).insert(2.int64).insert(3.int64).size

    test("size after remove")
      expect(2)
        val s = intset/empty().insert(1.int64).insert(2.int64).insert(3.int64)
        s.remove(2.int64).size

    test("from-list")
      expect(3)
        from-list([1.int64, 2.int64, 3.int64]).size

    test("from-list with duplicates")
      expect(2)
        from-list([1.int64, 2.int64, 1.int64, 2.int64]).size

    test("to-list size matches")
      expect(3)
        val s = from-list([1.int64, 2.int64, 3.int64])
        s.list.length

    test("to-list contains elements")
      expect(True)
        val s = from-list([1.int64, 2.int64, 3.int64])
        val xs = s.list
        xs.contains(1.int64) && xs.contains(2.int64) && xs.contains(3.int64)

    test("union empty sets")
      expect(0)
        union(intset/empty(), intset/empty()).size

    test("union with empty")
      expect(2)
        val s = from-list([1.int64, 2.int64])
        union(s, intset/empty()).size

    test("union disjoint sets")
      expect(4)
        val s1 = from-list([1.int64, 2.int64])
        val s2 = from-list([3.int64, 4.int64])
        union(s1, s2).size

    test("union overlapping sets")
      expect(3)
        val s1 = from-list([1.int64, 2.int64, 3.int64])
        val s2 = from-list([2.int64, 3.int64, 4.int64])
        union(s1, s2).size

    test("intersection empty sets")
      expect(0)
        intersection(intset/empty(), intset/empty()).size

    test("intersection disjoint sets")
      expect(0)
        val s1 = from-list([1.int64, 2.int64])
        val s2 = from-list([3.int64, 4.int64])
        intersection(s1, s2).size

    test("intersection overlapping sets")
      expect(2)
        val s1 = from-list([1.int64, 2.int64, 3.int64])
        val s2 = from-list([2.int64, 3.int64, 4.int64])
        intersection(s1, s2).size

    test("intersection identical sets")
      expect(3)
        val s = from-list([1.int64, 2.int64, 3.int64])
        intersection(s, s).size

    test("difference empty sets")
      expect(0)
        difference(intset/empty(), intset/empty()).size

    test("difference with empty")
      expect(2)
        val s = from-list([1.int64, 2.int64])
        difference(s, intset/empty()).size

    test("difference disjoint sets")
      expect(2)
        val s1 = from-list([1.int64, 2.int64])
        val s2 = from-list([3.int64, 4.int64])
        difference(s1, s2).size

    test("difference overlapping sets")
      expect(1)
        val s1 = from-list([1.int64, 2.int64, 3.int64])
        val s2 = from-list([2.int64, 3.int64, 4.int64])
        difference(s1, s2).size

    test("is-subset-of empty")
      expect(True)
        is-subset-of(intset/empty(), intset/empty())

    test("is-subset-of identical")
      expect(True)
        val s = from-list([1.int64, 2.int64, 3.int64])
        is-subset-of(s, s)

    test("is-subset-of true")
      expect(True)
        val s1 = from-list([1.int64, 2.int64])
        val s2 = from-list([1.int64, 2.int64, 3.int64])
        is-subset-of(s1, s2)

    test("is-subset-of false")
      expect(False)
        val s1 = from-list([1.int64, 2.int64, 3.int64])
        val s2 = from-list([1.int64, 2.int64])
        is-subset-of(s1, s2)

    test("disjoint empty")
      expect(True)
        disjoint(intset/empty(), intset/empty())

    test("disjoint identical")
      expect(False)
        val s = from-list([1.int64, 2.int64, 3.int64])
        disjoint(s, s)

    test("disjoint true")
      expect(True)
        val s1 = from-list([1.int64, 2.int64])
        val s2 = from-list([3.int64, 4.int64])
        disjoint(s1, s2)

    test("disjoint false")
      expect(False)
        val s1 = from-list([1.int64, 2.int64, 3.int64])
        val s2 = from-list([2.int64, 3.int64, 4.int64])
        disjoint(s1, s2)

    test("large set operations")
      expect(500)
        var s := intset/empty()
        for(500) fn(i)
          s := s.insert(i.int64)
        s.size

    test("large set membership")
      expect(True)
        var s := intset/empty()
        for(500) fn(i)
          s := s.insert(i.int64)
        s.member(250.int64)

    test("large set after remove")
      expect(499)
        var s := intset/empty()
        for(500) fn(i)
          s := s.insert(i.int64)
        s.remove(250.int64).size

fun main()
  run-tests(suite)
