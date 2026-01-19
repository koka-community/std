import std/data/int-set
import std/test
import std/num/int64

fun contains(xs: list<a>, elem: a, ?(==): (a, a) -> bool): bool
  match xs
    Cons(a, rst) -> if a == elem then True else rst.contains(elem)
    Nil -> False

fun suite()
  group("int-set")
    test("empty set is empty")
      expect(True)
        int-set/empty().is-empty

    test("insert element")
      expect(True)
        val s = int-set/empty().insert(42.int64)
        s.member(42.int64)

    test("member not found")
      expect(False)
        val s = int-set/empty().insert(42.int64)
        s.member(43.int64)

    test("insert duplicate")
      expect(1)
        val s = int-set/empty().insert(42.int64).insert(42.int64)
        s.size

    test("remove element")
      expect(False)
        val s = int-set/empty().insert(42.int64).insert(43.int64)
        val s' = s.remove(42.int64)
        s'.member(42.int64)

    test("remove non-existent")
      expect(True)
        val s = int-set/empty().insert(42.int64)
        val s' = s.remove(99.int64)
        s'.member(42.int64)

    test("size empty")
      expect(0)
        int-set/empty().size

    test("size single")
      expect(1)
        int-set/empty().insert(42.int64).size

    test("size multiple")
      expect(3)
        int-set/empty().insert(1.int64).insert(2.int64).insert(3.int64).size

    test("size after remove")
      expect(2)
        val s = int-set/empty().insert(1.int64).insert(2.int64).insert(3.int64)
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
        union(int-set/empty(), int-set/empty()).size

    test("union with empty")
      expect(2)
        val s = from-list([1.int64, 2.int64])
        union(s, int-set/empty()).size

    test("union disjoint sets")
      expect(4)
        val s1 = from-list([1.int64, 2.int64])
        val s2 = from-list([3.int64, 4.int64])
        union(s1, s2).size

    test("union overlapping sets")
      expect(4)
        val s1 = from-list([1.int64, 2.int64, 3.int64])
        val s2 = from-list([2.int64, 3.int64, 4.int64])
        union(s1, s2).size

    test("union disjoint high/low trees")
      expect(4)
        // s1 branches at bit 60 (high mask)
        val s1 = from-list([0.int64, 1.int64.shl(60)])
        // s2 branches at bit 0 (low mask), but has prefix with bit 61 set
        val base = 1.int64.shl(61)
        val s2 = from-list([base, base + 1.int64])
        
        val u1 = union(s1, s2)
        val u2 = union(s2, s1)
        
        if u1.size != 4 then 
          println("u1 size: " ++ u1.size.show)
          println("u1: " ++ u1.show)
        if u2.size != 4 then
          println("u2 size: " ++ u2.size.show)
          println("u2: " ++ u2.show)
          
        if u1.size == 4 && u2.size == 4 then 4 else 0

    test("intersection empty sets")
      expect(0)
        intersection(int-set/empty(), int-set/empty()).size

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
        difference(int-set/empty(), int-set/empty()).size

    test("difference with empty")
      expect(2)
        val s = from-list([1.int64, 2.int64])
        difference(s, int-set/empty()).size

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
        is-subset-of(int-set/empty(), int-set/empty())

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
        disjoint(int-set/empty(), int-set/empty())

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
      expect(5000)
        var s := int-set/empty()
        for(5000) fn(i)
          s := s.insert(i.int64)
        s.size

    test("large set membership")
      expect(True)
        var s := int-set/empty()
        for(5000) fn(i)
          s := s.insert(i.int64)
        s.member(2500.int64)

    test("large set after remove")
      expect(499999)
        var s := int-set/empty()
        for(500000) fn(i)
          s := s.insert(i.int64)
        s.remove(2500.int64).size

fun main()
  run-tests(suite)
