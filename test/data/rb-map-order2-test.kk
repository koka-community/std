import std/data/rb-map
import std/data/rb-map-order2
import std/test

fun m(l: list<(int,string)>): rb-map/rbmap<int,string>
  rb-map/from-list(l)

fun m2(l: list<(int,string)>): rb-map-order2/rbmap<int,string>
  rb-map-order2/from-list(l)

// the cmp (rb-map) writes must give the SAME maps as the rb-map-order2 writes
fun same(a: rb-map/rbmap<int,string>, b: rb-map-order2/rbmap<int,string>): bool
  a.rb-map/list == b.rb-map-order2/list

fun suite()
  group("rb-map vs rb-map-order2")
    test("set matches rb-map-order2/set, including overwrite")
      expect(True)
        val xs = [(5,"a"),(1,"b"),(9,"c"),(5,"d"),(3,"e"),(7,"f")]
        same(xs.foldl(rb-map/empty(), fn(acc, (k,v)) rb-map/set(acc, k, v)), rb-map-order2/from-list(xs))

    test("add keeps the existing value")
      expect(Just("a"))
        rb-map/add(m([(1,"a")]), 1, "z").rb-map/lookup(1)

    test("insert sees the present value")
      expect((Just("a!"), Just("new")))
        val x = rb-map/insert(m([(1,"a")]), 1, fn(mb) mb.default("new") ++ "!")
        val y = rb-map/insert(m([]), 2, fn(mb) mb.default("new"))
        (x.rb-map/lookup(1), y.rb-map/lookup(2))

    test("update: present f(old, new), absent new")
      expect((Just("old+new"), Just("new")))
        (rb-map/update(m([(1,"old")]), 1, "new", fn(o, n) o ++ "+" ++ n).rb-map/lookup(1),
         rb-map/update(m([]), 1, "new", fn(o, n) o ++ "+" ++ n).rb-map/lookup(1))

    test("union-with sees (from-s1, from-s2) and matches rb-map-order2")
      expect(True)
        val a = [(1,"L"),(3,"x")]; val b = [(1,"R"),(2,"y")]
        val f = fn(p: string, q: string) p ++ "|" ++ q
        same(rb-map/union-with(m(a), m(b), f), rb-map-order2/union-with(m2(a), m2(b), f))

    test("unions-with: later maps first, matches rb-map-order2")
      expect(True)
        val ms = [[(1,"1"),(4,"a")], [(1,"2")], [(1,"3"),(2,"b")]]
        val f = fn(p: string, q: string) p ++ "," ++ q
        same(rb-map/unions-with(ms.map(m), f), rb-map-order2/unions-with(ms.map(m2), f))

    test("unions: earlier maps win, matches rb-map-order2")
      expect(True)
        val ms = [[(1,"first")], [(1,"second"),(2,"x")]]
        same(rb-map/unions(ms.map(m)), rb-map-order2/unions(ms.map(m2)))

    test("large random-ish inserts stay sorted and complete")
      expect((1000, True))
        val xs = list(1, 1000).map(fn(i) ((i * 7919) % 1000, i.show))
        val t = xs.foldl(rb-map/empty(), fn(acc, (k,v)) rb-map/set(acc, k, v))
        (t.rb-map/size, same(t, rb-map-order2/from-list(xs)))

    test("remove matches rb-map-order2, including absent keys")
      expect(True)
        val xs = list(1, 200).map(fn(i) ((i * 37) % 200, i.show))
        val ks = [0, 7, 199, 500, 42, 7]
        same(ks.foldl(rb-map/from-list(xs), fn(acc, k) rb-map/remove(acc, k)),
             ks.foldl(rb-map-order2/from-list(xs), fn(acc, k) rb-map-order2/remove(acc, k)))

fun main()
  run-tests(suite)
