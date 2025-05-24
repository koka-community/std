/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a min-max heap implementation
module std/data/heap
import std/core-extras
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
  if 2 * i + 1 <= size then
    val child2 = data.unsafe-idx( (2 * i + 1).ssize_t )
    if min > child2 then
      min := child2
      min-idx := 2 * i + 1
  var grandchild := False
  val child1-idx = 2 * i
  val child2-idx = 2 * i + 1
  val grandchild1-idx = 2 * child1-idx
  val grandchild2-idx = 2 * child1-idx + 1
  val grandchild3-idx = 2 * child2-idx
  val grandchild4-idx = 2 * child2-idx + 1
  if grandchild1-idx <= size then
    val grandchild1 = data.unsafe-idx( grandchild1-idx.ssize_t )
    if min > grandchild1 then
      min := grandchild1
      min-idx := grandchild1-idx
      grandchild := True
  if grandchild2-idx <= size then
    val grandchild2 = data.unsafe-idx( grandchild2-idx.ssize_t )
    if min > grandchild2 then
      min := grandchild2
      min-idx := grandchild2-idx
      grandchild := True
  if grandchild3-idx <= size then
    val grandchild3 = data.unsafe-idx( grandchild3-idx.ssize_t )
    if min > grandchild3 then
      min := grandchild3
      min-idx := grandchild3-idx
      grandchild := True
  if grandchild4-idx <= size then
    val grandchild4 = data.unsafe-idx( grandchild4-idx.ssize_t )
    if min > grandchild4 then
      min := grandchild4
      min-idx := grandchild4-idx
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
  if 2 * i + 1 <= size then
    val child2 = data.unsafe-idx( (2 * i + 1).ssize_t )
    if max < child2 then
      max := child2
      max-idx := 2 * i + 1
  var grandchild := False
  val child1-idx = 2 * i
  val child2-idx = 2 * i + 1
  val grandchild1-idx = 2 * child1-idx
  val grandchild2-idx = 2 * child1-idx + 1
  val grandchild3-idx = 2 * child2-idx
  val grandchild4-idx = 2 * child2-idx + 1
  if grandchild1-idx <= size then
    val grandchild1 = data.unsafe-idx( grandchild1-idx.ssize_t )
    if max < grandchild1 then
      max := grandchild1
      max-idx := grandchild1-idx
      grandchild := True
  if grandchild2-idx <= size then
    val grandchild2 = data.unsafe-idx( grandchild2-idx.ssize_t )
    if max < grandchild2 then
      max := grandchild2
      max-idx := grandchild2-idx
      grandchild := True
  if grandchild3-idx <= size then
    val grandchild3 = data.unsafe-idx( grandchild3-idx.ssize_t )
    if max < grandchild3 then
      max := grandchild3
      max-idx := grandchild3-idx
      grandchild := True
  if grandchild4-idx <= size then
    val grandchild4 = data.unsafe-idx( grandchild4-idx.ssize_t )
    if max < grandchild4 then
      max := grandchild4
      max-idx := grandchild4-idx
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
pub fun resizer( size : int ) : int
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


