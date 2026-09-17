import std/data/rb-set
import std/test

// ints order by the default `cmp`/`order2`
fun ints(s: rbset<int>): list<int>
  s.list

fun suite()
  group("rb-set")
    test("empty is empty")
      expect(True)
        (rb-set/empty() : rbset<int>).is-empty

    test("from-list dedups and sorts")
      expect([1, 2, 3])
        [3, 1, 2, 3, 1].from-list.ints

    test("iteration is key order, not insertion order")
      expect([1, 5, 9])
        (rb-set/empty() + 9 + 1 + 5).ints

    test("member")
      expect((True, False))
        val s = [1, 2, 3].from-list
        (s.member(2), s.member(4))

    test("remove present and absent")
      expect(([1, 3], [1, 2, 3]))
        val s = [1, 2, 3].from-list
        (s.remove(2).ints, s.remove(7).ints)

    test("size / length")
      expect((3, 3))
        val s = [4, 4, 5, 6].from-list
        (s.size, s.length)

    test("union")
      expect([1, 2, 3, 4])
        union([1, 3].from-list, [2, 3, 4].from-list).ints

    test("unions")
      expect([1, 2, 3, 5])
        [[1].from-list, [3, 2].from-list, [5, 1].from-list].unions.ints

    test("unions of nothing")
      expect(True)
        ([] : list<rbset<int>>).unions.is-empty

    test("difference")
      expect([1, 4])
        ([1, 2, 3, 4].from-list - [2, 3, 9].from-list).ints

    test("intersection")
      expect([2, 3])
        intersection([1, 2, 3].from-list, [3, 2, 9].from-list).ints

    test("disjoint / common")
      expect((True, False, True))
        val a = [1, 2].from-list
        (disjoint(a, [3, 4].from-list), disjoint(a, [2].from-list), common(a, [2].from-list))

    test("is-subset-of")
      expect((True, False))
        ([1, 2].from-list.is-subset-of([1, 2, 3].from-list), [1, 4].from-list.is-subset-of([1, 2, 3].from-list))

    test("equality ignores construction order")
      expect((True, False))
        ([3, 2, 1].from-list == [1, 2, 3].from-list, [1, 2].from-list == [1, 2, 3].from-list)

    test("filter")
      expect([2, 4])
        [1, 2, 3, 4].from-list.filter(fn(x) x % 2 == 0).ints

    test("list + and list -")
      expect(([1, 2, 7], [2]))
        val s = [1, 2].from-list
        ((s + [7, 1]).ints, (s - [1, 8]).ints)

    test("maybe -")
      expect(([1], [1, 2]))
        val s = [1, 2].from-list
        ((s - Just(2)).ints, (s - (Nothing : maybe<int>)).ints)

    test("foldl visits in key order")
      expect("123")
        [3, 1, 2].from-list.list.foldl("", fn(acc, x) acc ++ x.show)

fun main()
  run-tests(suite)
