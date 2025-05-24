import std/data/heap
import std/test
import std/num/random

fun mb/(==)(a: maybe<int>, b: maybe<int>)
  match (a, b)
    (Nothing, Nothing) -> True
    (Just(x), Just(y)) -> x == y
    _ -> False

fun test()  
  with run-tests
  group("heap")
    test("heap min ordered")
      expect(Just(1))
        val heap = list/heap( [1, 2, 3] )
        heap.min
    test("heap min reversed")
      expect(Just(1))
        val heap = list/heap( [3, 2, 1] )
        heap.min
    test("heap max ordered")
      expect(Just(3))
        val heap = list/heap( [3, 2, 1] )
        heap.max
    test("heap max reversed")
      expect(Just(3))
        val heap = list/heap( [1, 2, 3] )
        heap.max
    test("heap min unordered")
      expect(Just(1))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
        heap.min
    test("heap max unordered")
      expect(Just(12))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
        heap.max
    test("heap insertion min")
      expect(Just(-1))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
        heap.insert( -1 ).min
    test("heap insertion max")
      expect(Just(17))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
        heap.insert( 17 ).max
    test("heap delete-min unordered")
      expect(Just(2))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
        val heap' = match heap.delete-min()
          Nothing -> heap
          Just((_, h)) -> h
        heap'.min
    test("heap delete-max unordered")
      expect(Just(7))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
        val heap' = match heap.delete-max()
          Nothing -> heap
          Just((_, h)) -> h
        heap'.max
    test("heap update-key min")
      expect(Just(0))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 12, 0 )
        heap.min
    test("heap update-key max")
      expect(Just(17))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 2, 17 )
        heap.max
    test("heap update-key min no-change")
      expect(Just(1))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 13, 0 )
        heap.min
    test("heap update-key max no-change")
      expect(Just(12))
        val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 5, 17 )
        heap.max
    test("heap stress test")
      with pseudo-random(0)
      var heap := heap()
      expect(True)
        for(50000) fn (i)
          heap := heap.insert( i * random-int() )
        True
    test("heap delete min 1")
      var heap := heap()
      expect(True)
        heap := heap.insert( 1 )
        heap.delete-min()
        True
    test("heap delete max 1")
      var heap := heap()
      expect(True) 
        heap := heap.insert( 1 )
        heap.delete-max
        True
    test("heap clear each element min ordered")
      val heap = list/heap( [1, 2, 3] )
      expect(Just(1))
        heap.min
      match heap.delete-min()
        Nothing -> assert-error("No more elements when there should be 2 more.")
        Just((_, heap')) ->
          expect(Just(2))
            heap'.min
          match heap'.delete-min()
            Nothing -> assert-error("No more elements when there should be 1 more.")
            Just((_, heap@)) ->
              expect(Just(3))
                heap@.min
    test("heap clear each element max ordered")
      val heap = list/heap( [1, 2, 3] )
      expect(Just(3))
        heap.max
      match heap.delete-max()
        Nothing -> assert-error("No more elements when there should be 2 more.")
        Just((_, heap')) ->
          expect(Just(2))
            heap'.max
          match heap'.delete-max()
            Nothing -> assert-error("No more elements when there should be 1 more.")
            Just((_, heap@)) ->
              expect(Just(1))
                heap@.max