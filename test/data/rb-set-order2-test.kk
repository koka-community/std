import std/data/rb-set
import std/data/rb-set-order2
import std/test

// the cmp (rb-set) writes must give the SAME sets as the rb-set-order2 writes
fun same(a: rb-set/rbset<int>, b: rb-set-order2/rbset<int>): bool
  a.rb-set/list == b.rb-set-order2/list

fun suite()
  group("rb-set vs rb-set-order2")
    test("from-list with duplicates")
      expect(True)
        val xs = list(1, 500).map(fn(i) (i * 7919) % 300)
        same(rb-set/from-list(xs), rb-set-order2/from-list(xs))

    test("remove, including absent elements")
      expect(True)
        val xs = list(1, 200).map(fn(i) (i * 37) % 200)
        val ks = [0, 7, 199, 500, 42, 7]
        same(ks.foldl(rb-set/from-list(xs), fn(acc, k) rb-set/remove(acc, k)),
             ks.foldl(rb-set-order2/from-list(xs), fn(acc, k) rb-set-order2/remove(acc, k)))

    test("unions and difference")
      expect(True)
        val ls = [[1, 5, 3], [2, 5], [9, 1]]
        val d = [5, 9]
        same(rb-set/difference(rb-set/unions(ls.map(rb-set/from-list)), rb-set/from-list(d)),
             rb-set-order2/difference(rb-set-order2/unions(ls.map(rb-set-order2/from-list)), rb-set-order2/from-list(d)))

    test("check-add reports newness")
      expect((True, False))
        val (a, s) = rb-set/check-add(rb-set/from-list([1, 2]), 3)
        val (b, _) = rb-set/check-add(s, 2)
        (a, b)

    test("cmp is lexicographic")
      expect((True, True, True))
        (rb-set/cmp(rb-set/from-list([1, 2]), rb-set/from-list([1, 3])) == Lt,
         rb-set/cmp(rb-set/from-list([2, 1]), rb-set/from-list([1, 2])) == Eq,
         rb-set/cmp(rb-set/from-list([1, 2, 3]), rb-set/from-list([1, 2])) == Gt)

fun main()
  run-tests(suite)
