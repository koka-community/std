/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a min-max heap implementation
module std/data/heap
import std/core-extras
import std/test
import std/core/unsafe
import std/num/random
import std/num/float64

// Time Complexity:
// Operation    Average   Worst Case
// Insert       O(log n)  O(log n)
// Update-key             O(n)
// Delete-min   O(log n)  O(log n)
// Delete-max   O(log n)  O(log n)
// Space Complexity:
// O(n + 1)
pub value struct heap<a>
  data : vector<a>
  size : int

// Create an empty heap with a given starting `capacity`.
pub fun heap( capacity : int = 1 ) : heap<a>
  // We add `1` to capacity since we ignore the 0th element to make our math easier
  Heap( unsafe-vector( (capacity + 1).ssize_t ), 0 )

// Create a heap from a list `l` where the initial capacity is the length of `l`.
pub fun list/heap( l : list<a>, ?cmp : (a, a) -> order ) : heap<a>
  // We add `1` to capacity since we ignore the 0th element to make our math easier
  val vec = unsafe-vector( (l.length + 1).ssize_t )
  list-to-heap( vec, l , 1)
  balance( Heap( vec, l.length ), list( 1, l.length).reverse )

// This helper function puts in the elements from the list into the vector buffer
tail fun heap/list-to-heap( v : vector<a>, l : list<a>, index : int ) : ()
  match l
    Nil -> ()
    Cons(x, xs) -> 
      v.unsafe-assign( index.ssize_t, x )
      list-to-heap( v, xs, index + 1)

// This helper function is used to rebalance the heap after all elements in the list have been added.
tail fun heap/balance( h : heap<a>, index-list : list<int>, ?cmp : (a, a) -> order ) : heap<a>
  match index-list
    Nil -> h
    Cons(x, xs) -> 
      balance( h.push-down( x ), xs )

// This helper is a recursive algorithm tells us if an `i` is on a min or max level
tail fun on-min-level( h : heap<a>, i : int ) : bool
  i.float64.log2.floor.float64/int % 2 == 0

// Helper for getting the parent index
fun parent( i : int ) : int
  i / 2

// Helper for checking if an index is on root.
fun is-root( i : int ) : bool
  i == 1

// Also known as sift-down. This function will move data down the heap.
fun push-down( h : heap<a>, i : int, ?cmp : (a, a) -> order ) : heap<a>
  unsafe-total fn ()
    push-down-helper( h, i )

fun push-down-helper( h : heap<a>, i : int, ?cmp : (a, a) -> order ) : div heap<a>
  if h.on-min-level( i ) then
    //trace("on min")
    h.push-down-min( i )
  else
    //trace("on max")
    h.push-down-max( i )

inline fun push-down-min( h : heap<a>, i : int, ?cmp : (a, a) -> order ) : div heap<a>
  match h
    Heap( data, size) ->
      if has-children( i, size ) then
        val (m, grandchild) = data.wrapper/get-next-min( i, size )
        if grandchild then
          if data.unsafe-idx( m.ssize_t ) < data.unsafe-idx( i.ssize_t ) then
            val data' = data.a/unsafe-swap( m, i )
            if data'.unsafe-idx( m.ssize_t ) > data'.unsafe-idx( m.parent.ssize_t ) then
              data'.unit/unsafe-swap( m.parent, m )
            Heap( data', size ).push-down-helper( m )
          else
            Heap( data, size )
        elif data.unsafe-idx( m.ssize_t ) < data.unsafe-idx( i.ssize_t ) then
          val data' = data.a/unsafe-swap( m, i )
          Heap( data', size )
        else
          Heap( data, size )
      else
        Heap( data, size )

inline fun push-down-max( h : heap<a>, i : int, ?cmp : (a, a) -> order ) : div heap<a>
  match h
    Heap( data, size) ->
      if has-children( i, size ) then
        val (m, grandchild) = data.wrapper/get-next-max( i, size )
        if grandchild then
          if data.unsafe-idx( m.ssize_t ) > data.unsafe-idx( i.ssize_t ) then
            val data' = data.a/unsafe-swap( m, i )
            if data'.unsafe-idx( m.ssize_t ) < data'.unsafe-idx( m.parent.ssize_t ) then
              data'.unit/unsafe-swap( m.parent, m )
            Heap( data', size ).push-down-helper( m )
          else
            Heap( data, size )
        elif data.unsafe-idx( m.ssize_t ) > data.unsafe-idx( i.ssize_t ) then
          val data' = data.a/unsafe-swap( m, i )
          Heap( data', size )
        else
          Heap( data, size )
      else
        Heap( data, size )

// Helper for checking if an index has any children.
fun has-children( i : int, size : int ) : bool
  if i < 1 then False
  else 2 * i <= size || 2 * i + 1 <= size

// Helper for getting the next minimum value from either children or grandchildren.
fun wrapper/get-next-min( data : vector<a>, i : int, size : int, ?cmp : (a, a) -> order ) : (int, bool)
  unsafe-total() fn () 
    real/get-next-min( data, i, size )

// This function is an unrolled loop that checks for the minimum value from either children or grandchildren.
inline fun real/get-next-min( data : vector<a>, i : int, size : int, ?cmp : (a, a) -> order ) : div (int, bool)
  var min := data.unsafe-idx( (2 * i).ssize_t )
  var min-idx := 2 * i
  if 2 * i + 1 < size then
    val check1 = data.unsafe-idx( (2 * i + 1).ssize_t )
    if min > check1 then
      min := check1
      min-idx := 2 * i + 1
  var grandchild := False
  val child1-idx = 2 * i
  val child2-idx = 2 * i + 1
  if 2 * child1-idx < size then
    val check2 = data.unsafe-idx( (2 * child1-idx).ssize_t )
    if min > check2 then
      min := check2
      min-idx := 2 * child1-idx
      grandchild := True
  if 2 * child1-idx + 1 < size then
    val check3 = data.unsafe-idx( (2 * child1-idx + 1).ssize_t )
    if min > check3 then
      min := check3
      min-idx := 2 * child1-idx + 1
      grandchild := True
  if 2 * child2-idx < size then
    val check4 = data.unsafe-idx( (2 * child2-idx).ssize_t )
    if min > check4 then
      min := check4
      min-idx := 2 * child2-idx
      grandchild := True
  if 2 * child2-idx + 1 < size then
    val check5 = data.unsafe-idx( (2 * child2-idx + 1).ssize_t )
    if min > check5 then
      min := check5
      min-idx := 2 * child2-idx + 1
      grandchild := True 
  (min-idx, grandchild)

// Helper for getting the next maximum value from either children or grandchildren.
fun wrapper/get-next-max( data : vector<a>, i : int, size : int, ?cmp: (a, a) -> order ) : (int, bool)
  unsafe-total() fn () 
    real/get-next-max( data, i, size )

// This function is an unrolled loop that checks for the maximum value from either children or grandchildren.
inline fun real/get-next-max( data : vector<a>, i : int, size : int, ?cmp: (a, a) -> order ) : div (int, bool)
  var max := data.unsafe-idx( (2 * i).ssize_t )
  var max-idx := 2 * i
  if 2 * i + 1 < size then
    val check1 = data.unsafe-idx( (2 * i + 1).ssize_t )
    if max < check1 then
      max := check1
      max-idx := 2 * i + 1
  var grandchild := False
  val child1-idx = 2 * i
  val child2-idx = 2 * i + 1
  if 2 * child1-idx < size then
    val check2 = data.unsafe-idx( (2 * child1-idx).ssize_t )
    if max < check2 then
      max := check2
      max-idx := 2 * child1-idx
      grandchild := True
  if 2 * child1-idx + 1 < size then
    val check3 = data.unsafe-idx( (2 * child1-idx + 1).ssize_t )
    if max < check3 then
      max := check3
      max-idx := 2 * child1-idx + 1
      grandchild := True
  if 2 * child2-idx < size then
    val check4 = data.unsafe-idx( (2 * child2-idx).ssize_t )
    if max < check4 then
      max := check4
      max-idx := 2 * child2-idx
      grandchild := True
  if 2 * child2-idx + 1 < size then
    val check5 = data.unsafe-idx( (2 * child2-idx + 1).ssize_t )
    if max < check5 then
      max := check5
      max-idx := 2 * child2-idx + 1
      grandchild := True 
  (max-idx, grandchild)

// Also known as bubble-up. This function will move data up the heap.
fun push-up( h : heap<a>, i : int, ?cmp: (a, a) -> order ) : heap<a>
  unsafe-total fn ()
    push-up-helper( h, i )

fun push-up-helper( h : heap<a>, i : int, ?cmp: (a, a) -> order ) : div heap<a>
  match h
    Heap(data, size) -> 
      if i.is-root.not then
        if h.on-min-level( i ) then
          if data.unsafe-idx( i.ssize_t ) > data.unsafe-idx( i.parent.ssize_t ) then
            val data' = data.a/unsafe-swap( i.parent, i )
            Heap( data', size ).push-up-max( i.parent )
          else
            Heap( data, size ).push-up-min( i )
        else
          if data.unsafe-idx( i.ssize_t ) < data.unsafe-idx( i.parent.ssize_t ) then
            val data' = data.a/unsafe-swap( i.parent, i )
            Heap( data', size ).push-up-min( i.parent )
          else
            Heap( data, size ).push-up-max( i )
      else
        Heap( data, size )

fun push-up-min( h : heap<a>, i : int, ?cmp: (a, a) -> order ) : div heap<a>
  val grandparent = get-grandparent( i )
  match grandparent
    Nothing -> h
    Just( g ) ->
      match h 
        Heap( data, size ) ->
          if data.unsafe-idx( i.ssize_t ) < data.unsafe-idx( g.ssize_t ) then
            val data' = data.a/unsafe-swap( i, g )
            Heap( data', size ).push-up-min( g )
          else
            Heap( data, size )

fun push-up-max( h : heap<a>, i : int, ?cmp: (a, a) -> order ) : div heap<a>
  val grandparent = get-grandparent( i )
  match grandparent
    Nothing -> h
    Just( g ) ->
      match h 
        Heap( data, size ) ->
          if data.unsafe-idx( i.ssize_t ) > data.unsafe-idx( g.ssize_t ) then
            val data' = data.a/unsafe-swap( i, g )
            Heap( data', size ).push-up-max( g )
          else
            Heap( data, size )

// Helper for getting the grandparent of an index `i`.
fun get-grandparent( i : int ) : maybe<int>
  if i <= 3 then
    Nothing
  else 
    Just( i / 4 )

// Internal base function for dictating how to resize the vector buffer.
fun resizer( size : int ) : int
  if size == 0 then
    1
  else
    size * 2

// Inserts an item `x` into the end of the heap `h`, resizing first if necessary.
// After insertion, then value will be pushed up if needed.
pub fun insert( h : heap<a>, x : a, ?cmp: (a, a) -> order, ?resizer : (int) -> int ) : heap<a>
  match h
    Heap( data, size ) ->
      // adding `1` here since we ignore the first value in the list
      val vec = if size + 1 == data.length  then
        data.realloc( resizer( size + 1 ).ssize_t )
      else
        data
      val vec' = vec.unsafe-set( size + 1, x)
      Heap( vec', size + 1 ).push-up( size + 1 )

// Fetches the minimum element from heap `h`.
pub fun min( h : heap<a>, ?cmp: (a, a) -> order ) : maybe<a>
  if h.size == 0 then
    Nothing
  else
    h.data.at( 1 )

// Removes the minimum element from heap `h`.
pub fun delete-min( h : heap<a>, ?cmp: (a, a) -> order ) : maybe<(a, heap<a>)>
  if h.size == 0 then
    Nothing
  else 
    val min = h.data.unsafe-idx( 1.ssize_t )
    match h
      Heap( data, size ) ->
        val last = data.unsafe-idx( size.ssize_t )
        val data' = data.unsafe-set( 1, last )
        data'.unsafe-vector-clear-at( (size).ssize_t )
        Just( (min, Heap( data', size - 1 ).push-down( 1 )) )

// Fetches the maximum element from heap `h`.
pub fun max( h : heap<a>, ?cmp: (a, a) -> order ) : maybe<a>
  if h.size == 0 then
    Nothing
  else 
    val index = if h.size == 1 then
      1
    elif h.size == 2 then
      2
    elif h.data.unsafe-idx( 2.ssize_t ) > h.data.unsafe-idx( 3.ssize_t ) then
      2
    else
      3
    h.data.at( index )

// Removes the maximum element from heap `h`.
pub fun delete-max( h : heap<a>, ?cmp: (a, a) -> order, ?show : (a) -> string ) : maybe<(a, heap<a>)>
  if h.size == 0 then
    Nothing
  else 
    val index = if h.size == 1 then
      1
    elif h.size == 2 then
      2
    elif h.data.unsafe-idx( 2.ssize_t ) > h.data.unsafe-idx( 3.ssize_t ) then
      2
    else
      3
    val max = h.data.unsafe-idx( index.ssize_t )
    match h
      Heap( data, size ) ->
        val last = data.unsafe-idx( size.ssize_t )
        val data' = data.unsafe-set( index, last )
        data'.unsafe-vector-clear-at( (size).ssize_t )
        Just( (max, Heap( data', size - 1 ).push-down( index )) )

// This function will update a `key` with a `new-key` in a heap `h`.
pub fun update-key( h : heap<a>, key : a, new-key : a, ?cmp: (a, a) -> order ) : heap<a>
  unsafe-total 
    update-key-real( h, key, new-key )

// This function needs to be optimized. We need to figure out the exact situations of when to call `push-down` or `push-up` so that we don't have a worse case O(n) time.
inline fun update-key-real( h : heap<a>, key : a, new-key : a, ?cmp: (a, a) -> order ) : div heap<a>
  var i := 1
  while { h.size > i && h.data.unsafe-idx( i.ssize_t ) != key }
    i := i + 1
  if i == h.size then
    h
  else
    match h
      Heap( data, size ) -> 
        val data' = data.unsafe-set( i, new-key ).a/unsafe-swap( 1, i )
        Heap( data', size ).push-down( 1 )


fun test-heap()  
  basic/test("heap min ordered")
    val heap = list/heap( [1, 2, 3] )
    val min = heap.min()
    expect(Just(1), { min }, details = "Expected Just(1) but found " ++ min.show )
  basic/test("heap min reversed")
    val heap = list/heap( [3, 2, 1] )
    val min = heap.min()
    expect(Just(1), { min }, details = "Expected Just(1) but found " ++ min.show )
  basic/test("heap max ordered")
    val heap = list/heap( [3, 2, 1] )
    val min = heap.max()
    expect(Just(3), { min }, details = "Expected Just(3) but found " ++ min.show )
  basic/test("heap max reversed")
    val heap = list/heap( [1, 2, 3] )
    val min = heap.max()
    expect(Just(3), { min }, details = "Expected Just(3) but found " ++ min.show )
  basic/test("heap min unordered")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
    val min = heap.min()
    expect(Just(1), { min }, details = "Expected Just(1) but found " ++ min.show )
  basic/test("heap max unordered")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
    val min = heap.max()
    expect(Just(12), { min }, details = "Expected Just(12) but found " ++ min.show )
  basic/test("heap insertion min")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).insert( -1 )
    val min = heap.min()
    expect(Just(-1), { min }, details = "Expected Just(-1) but found " ++ min.show )
  basic/test("heap insertion max")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).insert( 17 )
    val min = heap.max()
    expect(Just(17), { min }, details = "Expected Just(17) but found " ++ min.show )
  basic/test("heap delete-min unordered")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
    val heap' = match heap.delete-min()
      Nothing -> heap
      Just((_, h)) -> h
    val min = heap'.min()
    expect(Just(2), { min }, details = "Expected Just(2) but found " ++ min.show )
  basic/test("heap delete-max unordered")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] )
    val heap' = match heap.delete-max()
      Nothing -> heap
      Just((_, h)) -> h
    val max = heap'.max()
    expect(Just(7), { max }, details = "Expected Just(7) but found " ++ max.show )
  basic/test("heap update-key min")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 12, 0 )
    val min = heap.min()
    expect(Just(0), { min }, details = "Expected Just(0) but found " ++ min.show )
  basic/test("heap update-key max")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 2, 17 )
    val max = heap.max()
    expect(Just(17), { max }, details = "Expected Just(17) but found " ++ max.show )
  basic/test("heap update-key min no-change")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 13, 0 )
    val min = heap.min()
    expect(Just(1), { min }, details = "Expected Just(0) but found " ++ min.show )
  basic/test("heap update-key max no-change")
    val heap = list/heap( [ 7, 1, 4, 2, 12, 3] ).update-key( 5, 17 )
    val max = heap.max()
    expect(Just(12), { max }, details = "Expected Just(17) but found " ++ max.show )
  basic/test("heap stress test")
    var heap := heap()
    for(50000) fn (i)
      heap := heap.insert( i * random-int() )
    expect(True, { True }, details = "Heap did not succeed." )
  basic/test("heap delete min 1")
    var heap := heap()
    heap := heap.insert( 1 )
    heap.delete-min()
    expect(True, { True }, details = "Heap did not succeed." )
  basic/test("heap delete max 1")
    var heap := heap()
    heap := heap.insert( 1 )
    heap.delete-max()
    expect(True, { True }, details = "Heap did not succeed." )
  basic/test("heap clear each element min ordered")
    val heap = list/heap( [1, 2, 3] )
    val min1 = heap.min()
    expect(Just(1), { min1 }, details = "Expected Just(1) but found " ++ min1.show )
    match heap.delete-min()
      Nothing -> expect(True, { False }, details = "No more elements when there should be 2 more." )
      Just((_, heap')) ->
        val min2 = heap'.min()
        expect(Just(2), { min2 }, details = "Expected Just(2) but found " ++ min2.show )
        match heap'.delete-min()
          Nothing -> expect(True, { False }, details = "No more elements when there should be 1 more." )
          Just((_, heap@)) ->
            val min3 = heap@.min()
            expect(Just(3), { min3 }, details = "Expected Just(3) but found " ++ min3.show )
  basic/test("heap clear each element max ordered")
    val heap = list/heap( [1, 2, 3] )
    val max1 = heap.max()
    expect(Just(3), { max1 }, details = "Expected Just(3) but found " ++ max1.show )
    match heap.delete-max()
      Nothing -> expect(True, { False }, details = "No more elements when there should be 2 more." )
      Just((_, heap')) ->
        val max2 = heap'.max()
        expect(Just(2), { max2 }, details = "Expected Just(2) but found " ++ max2.show )
        match heap'.delete-max()
          Nothing -> expect(True, { False }, details = "No more elements when there should be 1 more." )
          Just((_, heap@)) ->
            val max3 = heap@.max()
            expect(Just(1), { max3 }, details = "Expected Just(1) but found " ++ max3.show )

fun main()
  test-heap()