import std/data/vector-list
import std/test
import std/core/unsafe

reference struct something {i: int}

fun suite()
  group("vlist")
    test("push")
      val vec = unit/vector-list() 
      expect(2)
        val vec' = vec.push(2)
        vec'.at(0).unjust
    test("pop")
      val vec = vector-list-init(10) fn (i) Something(i)
      expect("0 1 2 3 4 5 6 7 8 ")

        val vec' = match vec.pop()
          Just((x, v)) -> 
            expect(x, {Something(9)}, ?(==)= fn(a, b) a.i == b.i, ?show=_.i.show)
            v
          Nothing -> vec
        var after-pop := ""
        vec'.foreach() fn (x)
          after-pop := after-pop ++ x.i.show ++ " "
        after-pop
    test("unique map")
      val vec = vector-list-init(10) fn (i) Something(i)
      expect("1 2 3 4 5 6 7 8 9 10 ")
        val vec2 = vec.unique/map(fn (x) x.i + 1)
        var after-map := ""
        vec2.foreach() fn (x)
          after-map := after-map ++ x.show ++ " "
        after-map
    test("resize push")
      val vec = vector-list-init(10) fn (i) i
      expect(20)
        vec.push(11).capacity
    test("copies on set")
      val vec1 = vector-list-init(10) fn (i) i
      expect(True, details="Expected vec1 and vec2 to be different")
        val vec2 = vec1.set(0, 100).unjust
        vec1.at(0).default(0) != vec2.at(0).default(0)
    test("doesn't copy when unique")
      val vec1 = vector-list-init(10, Something)
      expect(False, details="Expected vec1 and vec10 to be the same")
        val vec10 = vec1.at(0).unjust
        val vec2 = vec1.set(9, Something(1)).unjust
        unsafe-ptr-eq(vec10, vec2.at(4).unjust)
    test("stress test")
      var vec := unit/vlist()
      expect(True)
        for(50000) fn (i)
          vec := vec.push(i)
        True
    test("ref")
      expect("1 2 3 4 5 6 7 8 9 10 ")
        var vec := ref(vector-list-init(10) fn(i) i)
        vec.modify(fn(v) v := v.unique/map(fn (x) x + 1))
        var after-map := ""
        (!vec).foreach() fn (x)
          after-map := after-map ++ x.show ++ " "
        after-map
    test("clear test")
      expect(0)
        var vec := unit/vlist()
        for(20) fn (i)
          vec := vec.push(i)
        vec := vec.clear
        vec.length
    test("insertion after clear test")
      var vec : vector-list<int> := unit/vlist()
      for(8) fn (i)
        vec := vec.push(i)
      expect(9)
        vec := vec.clear
        for(9) fn (i)
          vec := vec.push(i)
        vec.length
