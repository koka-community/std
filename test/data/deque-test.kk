import std/data/deque
import std/test
import std/core-extras
import std/core/unsafe

reference struct something {i: int}

fun suite()
  group("Deque")
    test("push-front")
      val deq = unit/deque()
      expect(Just(2))
        val deq' = deq.push-front(2)
        deq'.at(0)
    test("push-back")
      val deq = unit/deque()
      expect(Just(2))
        val deq' = deq.push-back(2)
        deq'.at(0)
    test("pop-front")
      val deq = deque-init(10) fn (i) Something(i)
      expect("1 2 3 4 5 6 7 8 9 ")
        val deq' = match deq.pop-front()
          Just((x, v)) -> 
            expect(Something(0), { x }, ?(==)= fn(a, b) a.i == b.i, ?show=_.i.show)
            v
          Nothing -> deq
        var after-pop := ""
        deq'.foreach() fn (x)
          after-pop := after-pop ++ x.i.show ++ " "
        after-pop 
    test("pop-back")
      val deq = deque-init(10) fn (i) Something(i)
      expect("0 1 2 3 4 5 6 7 8 ")
        val deq' = match deq.pop-back()
          Just((x, v)) -> 
            expect(x, {Something(9)}, ?(==)= fn(a, b) a.i == b.i, ?show=_.i.show)
            v
          Nothing -> deq
        var after-pop := ""
        deq'.foreach() fn (x)
          after-pop := after-pop ++ x.i.show ++ " "
        after-pop
    test("unique map")
      val deq = deque-init(10) fn (i) Something(i)
      expect("1 2 3 4 5 6 7 8 9 10 ")
        val deq2 = deq.unique/map(fn (x) x.i + 1)
        var after-map := ""
        deq2.foreach() fn (x)
          after-map := after-map ++ x.show ++ " "
        after-map
    test("resize push")
      val deq = deque-init(10) fn (i) i
      expect(20)
        deq.push-back(11).capacity
    test("copies on set")
      val deq1 = deque-init(10) fn (i) i
      expect(True, details="Expected deq1 and deq2 to be different")
        val deq2 = deq1.set(0, 100).unjust
        deq1.at(0).default(0) != deq2.at(0).default(0)
    test("doesn't copy when unique")
      expect(False, details="Expected deq1 and deq10 to be the same")
        val deq1 = deque-init(10, Something)
        val deq10 = deq1.at(0).unjust
        val deq2 = deq1.set(9, Something(1)).unjust
        unsafe-ptr-eq(deq10, deq2.at(4).unjust)
    test("stress")
      expect(True)
        var deq := unit/deque()
        for(50000) fn (i)
          deq := (if i % 2 == 0 then deq.push-front(i) else deq.push-back(i))
        True
    test("clear")
      var deq := deque(2, 2)
      expect(0)
        deq := deq.clear
        deq.length
    test("insertion after clear")
      var deq := deque(2, 2)
      expect(10)
        deq := deq.clear
        for(10) fn (i)
          deq := (if i % 2 == 0 then deq.push-front(i) else deq.push-back(i))
        deq.length
    test("truncation")
      val deq = deque(2, 2)
      expect("2 ")
        val deq' = deq.resize(1)
        var truncated := ""
        deq'.foreach() fn (x)
          truncated := truncated ++ x.show ++ " "
        truncated

  