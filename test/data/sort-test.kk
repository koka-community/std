import std/data/sort
import std/test

fun suite()
  group("sort")
    test("empty and singleton")
      expect(([], [7]))
        (([] : list<int>).sort, [7].sort)

    test("sorts")
      expect([1, 2, 3, 4, 5, 6])
        [4, 2, 6, 1, 5, 3].sort

    test("duplicates")
      expect([1, 1, 2, 3, 3, 3])
        [3, 1, 3, 2, 1, 3].sort

    test("already sorted and reversed")
      expect(True)
        val xs = list(1, 1000)
        xs.sort == xs && xs.reverse.sort == xs

    // the quadratic case: the old first-pivot quicksort needed ~n^2/2
    // comparisons and n-deep recursion here
    test("large sorted input is fast")
      expect(200000)
        list(1, 200000).sort.length

    test("stable: ties keep input order")
      expect([(1, "a"), (1, "b"), (2, "c"), (2, "d")])
        [(2, "c"), (1, "a"), (2, "d"), (1, "b")].sort(?(<) = fn(p: (int, string), q: (int, string)) p.fst < q.fst)

fun main()
  run-tests(suite)
