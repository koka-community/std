import std/data/rb-map
import std/test

fun m(l: list<(int,string)>): rbmap<int,string>
  l.from-list

fun suite()
  group("rb-map")
    test("iteration is key order")
      expect([1, 5, 9])
        rb-map/empty().set(9, "c").set(1, "a").set(5, "b").keys

    test("is-empty / size")
      expect((True, False, 2))
        ((rb-map/empty() : rbmap<int,string>).is-empty, m([(1,"a")]).is-empty, m([(1,"a"),(2,"b"),(1,"c")]).size)

    test("from-list: later entries win")
      expect(Just("c"))
        m([(1,"a"),(1,"c")]).lookup(1)

    test("add: existing value wins")
      expect(Just("a"))
        m([(1,"a")]).add(1, "z").lookup(1)

    test("add-all is add-if-absent")
      expect([(1,"a"),(2,"y")])
        (m([(1,"a")]) + [(1,"x"),(2,"y")]).list

    test("update: present calls f(old, new)")
      expect(Just("old+new"))
        m([(1,"old")]).update(1, "new", fn(o, n) o ++ "+" ++ n).lookup(1)

    test("update: absent inserts the value")
      expect(Just("new"))
        m([]).update(1, "new", fn(o, n) o ++ "+" ++ n).lookup(1)

    test("get / get-default / contains-key")
      expect(("a", "d", True, False))
        val x = m([(1,"a")])
        (x.get(1), x.get-default(2, "d"), x.contains-key(1), x.contains-key(2))

    test("union-with sees (from-s1, from-s2)")
      expect(Just("L|R"))
        union-with(m([(1,"L")]), m([(1,"R")]), fn(a, b) a ++ "|" ++ b).lookup(1)

    test("union is left-biased")
      expect([(1,"L"),(2,"r")])
        union(m([(1,"L")]), m([(1,"R"),(2,"r")])).list

    test("unions: earlier maps win")
      expect(Just("first"))
        [m([(1,"first")]), m([(1,"second")])].unions.lookup(1)

    test("unions-with: later maps' values come first")
      expect(Just("3,2,1"))
        [m([(1,"1")]), m([(1,"2")]), m([(1,"3")])].unions-with(fn(a, b) a ++ "," ++ b).lookup(1)

    test("filter")
      expect([2])
        m([(1,"a"),(2,"bb")]).filter(fn(_, v) v == "bb").keys

    test("foldl visits in key order")
      expect("abc")
        m([(3,"c"),(1,"a"),(2,"b")]).foldl("", fn(acc, _, v) acc ++ v)

    test("remove-all ignores absent keys")
      expect([2])
        m([(1,"a"),(2,"b"),(3,"c")]).remove-all([3, 1, 9]).keys

    test("remove")
      expect([1, 3])
        m([(1,"a"),(2,"b"),(3,"c")]).remove(2).keys

fun main()
  run-tests(suite)
