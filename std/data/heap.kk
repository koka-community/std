/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a simple resizable vector implementation
module std/data/heap
import std/core-extras
import std/test
import std/core/unsafe

pub value struct heap<a>
  pub data : vector<a>
  size : int

pub fun heap( capacity : int = 1 ) : heap<a>
  // We add `1` to capacity since we ignore the 0th element to make our math easier
  Heap( unsafe-vector( (capacity + 1).ssize_t ), 0 )

pub fun list/heap( l : list<a>, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  // We add `1` to capacity since we ignore the 0th element to make our math easier
  val vec = unsafe-vector( (l.length + 1).ssize_t )
  list/heap-helper1( vec, l , 1)
  list/heap-helper2( Heap( vec, l.length ), stride/list( 1, l.length, 1).reverse )

fun list/heap-helper1( v : vector<a>, l : list<a>, index : int ) : ()
  match l
    Nil -> ()
    Cons(x, xs) -> 
      v.unsafe-assign( index.ssize_t, x )
      list/heap-helper1( v, xs, index + 1)

fun list/heap-helper2( h : heap<a>, index-list : list<int>, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  match index-list
    Nil -> h
    Cons(x, xs) -> 
      list/heap-helper2( h.push-down( x ), xs )

fun on-min-level( h : heap<a>, i : int ) : bool
  unsafe-total fn ()
    val x = helper/on-min-level( i, 1, 1 )
    trace(x.show)
    x

fun helper/on-min-level( i : int, left-bound : int, right-bound : int ) : div bool
  /*trace("index " ++ i.show)
  trace("left-bound " ++ left-bound.show)
  trace("right-bound " ++ right-bound.show)*/
  if i >= left-bound && i <= right-bound then
    True
  elif i >= 2 * left-bound && i <= 2 * right-bound + 1 then
    False
  else 
    val new-left-bound = 2 * (2 * left-bound)
    val new-right-bound = 2 * (2 * right-bound + 1) + 1
    helper/on-min-level( i, new-left-bound, new-right-bound ) 

fun parent( i : int ) : int
  i / 2

fun is-root( i : int ) : bool
  i == 1

fun push-down( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  unsafe-total fn ()
    push-down-helper( h, i )

fun push-down-helper( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div heap<a>
  if h.on-min-level( i ) then
    trace("on min")
    h.push-down-min( i )
  else
    trace("on max")
    h.push-down-max( i )

inline fun push-down-min( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div heap<a>
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

inline fun push-down-max( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div heap<a>
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

fun has-children( i : int, size : int ) : bool
  if i > 1 then False
  else 2 * i < size || 2 * i + 1 < size

fun wrapper/get-next-min( data : vector<a>, i : int, size : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : (int, bool)
  unsafe-total() fn () 
    real/get-next-min( data, i, size )

inline fun real/get-next-min( data : vector<a>, i : int, size : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div (int, bool)
  var min := data.unsafe-idx( (2 * i).ssize_t )
  var min-idx := 2 * i
  if min > data.unsafe-idx( (2 * i + 1).ssize_t ) then
    min := data.unsafe-idx( (2 * i + 1).ssize_t )
    min-idx := 2 * i + 1
  var grandchild := False
  val child1-idx = 2 * i
  val child2-idx = 2 * i + 1
  if 2 * child1-idx < size then
    if min > data.unsafe-idx( (2 * child1-idx).ssize_t ) then
      min := data.unsafe-idx( (2 * child1-idx).ssize_t )
      min-idx := 2 * child2-idx
      grandchild := True
  if 2 * child1-idx + 1 < size then
    if min > data.unsafe-idx( (2 * child1-idx + 1).ssize_t ) then
      min := data.unsafe-idx( (2 * child1-idx + 1).ssize_t )
      min-idx := 2 * child2-idx + 1
      grandchild := True
  if 2 * child2-idx < size then
    if min > data.unsafe-idx( (2 * child2-idx).ssize_t ) then
      min := data.unsafe-idx( (2 * child2-idx).ssize_t )
      min-idx := 2 * child2-idx
      grandchild := True
  if 2 * child2-idx + 1 < size then
    if min > data.unsafe-idx( (2 * child2-idx + 1).ssize_t ) then
      min := data.unsafe-idx( (2 * child2-idx + 1).ssize_t )
      min-idx := 2 * child2-idx + 1
      grandchild := True 
  (min-idx, grandchild)

fun wrapper/get-next-max( data : vector<a>, i : int, size : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : (int, bool)
  unsafe-total() fn () 
    real/get-next-max( data, i, size )

inline fun real/get-next-max( data : vector<a>, i : int, size : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div (int, bool)
  var max := data.unsafe-idx( (2 * i).ssize_t )
  var max-idx := 2 * i
  if max < data.unsafe-idx( (i + 1).ssize_t ) then
    max := data.unsafe-idx( (i + 1).ssize_t )
    max-idx := 2 * i + 1
  var grandchild := False
  val child1-idx = 2 * i
  val child2-idx = 2 * i + 1
  if 2 * child1-idx < size then
    if max < data.unsafe-idx( (2 * child1-idx).ssize_t ) then
      max := data.unsafe-idx( (2 * child1-idx).ssize_t )
      max-idx := 2 * child1-idx
      grandchild := True
  if 2 * child1-idx + 1 < size then
    if max < data.unsafe-idx( (2 * child1-idx + 1).ssize_t ) then
      max := data.unsafe-idx( (2 * child1-idx + 1).ssize_t )
      max-idx := 2 * child1-idx + 1
      grandchild := True
  if 2 * child2-idx < size then
    if max < data.unsafe-idx( (2 * child2-idx).ssize_t ) then
      max := data.unsafe-idx( (2 * child2-idx).ssize_t )
      max-idx := 2 * child2-idx
      grandchild := True
  if 2 * child2-idx + 1 < size then
    if max < data.unsafe-idx( (2 * child2-idx + 1).ssize_t ) then
      max := data.unsafe-idx( (2 * child2-idx + 1).ssize_t )
      max-idx := 2 * child2-idx + 1
      grandchild := True 
  (max-idx, grandchild)


fun push-up( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : heap<a>
  unsafe-total fn ()
    push-up-helper( h, i )

fun push-up-helper( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div heap<a>
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

fun push-up-min( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div heap<a>
  val grandparent = get-grandparent( i )
  match grandparent
    Nothing -> h
    Just( g ) ->
      match h 
        Heap( data, size ) ->
          if data.unsafe-idx( i.ssize_t ) < data.unsafe-idx( g.ssize_t ) then
            val i-item = data.unsafe-idx( i.ssize_t )
            val data' = data.unsafe-set( i, data.unsafe-idx( g.ssize_t ))
            data.unsafe-assign( i.ssize_t, i-item )
            Heap( data', size ).push-up-min( g )
          else
            Heap( data, size )

fun push-up-max( h : heap<a>, i : int, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : div heap<a>
  val grandparent = get-grandparent( i )
  match grandparent
    Nothing -> h
    Just( g ) ->
      match h 
        Heap( data, size ) ->
          if data.unsafe-idx( i.ssize_t ) > data.unsafe-idx( g.ssize_t ) then
            val i-item = data.unsafe-idx( i.ssize_t )
            val data' = data.unsafe-set( i, data.unsafe-idx( g.ssize_t ))
            data.unsafe-assign( i.ssize_t, i-item )
            Heap( data', size ).push-up-max( g )
          else
            Heap( data, size )

fun get-grandparent( i : int ) : maybe<int>
  if i <= 3 then
    Nothing
  else 
    Just( i / 4 )

fun resizer( size : int ) : int
  if size == 0 then
    1
  else
    size * 2

pub fun insert( h : heap<a>, x : a, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool, ?resizer : (int) -> int ) : heap<a>
  match h
    Heap( data, size ) ->
      // subtracting `1` here since we ignore the first value in the list
      val vec = if size == data.length - 1 then
        data.realloc( resizer( size ).ssize_t )
      else
        data
      val vec' = vec.unsafe-set( size, x)
      Heap( vec', size + 1 ).push-up( size )

pub fun min( h : heap<a>, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : maybe<a>
  if h.size == 0 then
    Nothing
  else
    h.data.at( 1 )

pub fun delete-min( h : heap<a>, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : maybe<(a, heap<a>)>
  if h.size == 0 then
    Nothing
  else 
    val min = h.data.unsafe-idx( 1.ssize_t )
    match h
      Heap( data, size ) ->
        val last = data.unsafe-idx( size.ssize_t )
        val data' = data.unsafe-set( 1, last )
        data'.unsafe-vector-clear-at( size.ssize_t )
        Just( (min, Heap( data', size - 1 ).push-down( 1 )) )

pub fun max( h : heap<a>, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : maybe<a>
  if h.size == 0 then
    Nothing
  else 
    val index = if h.size == 1 then
      1
    elif h.size == 2 then
      2
    else
      if h.data.unsafe-idx( 2.ssize_t ) > h.data.unsafe-idx( 3.ssize_t ) then
        2
      else
        3
    h.data.at( index )

pub fun delete-max( h : heap<a>, ?(<) : (a, a) -> bool, ?(>) : (a, a) -> bool, ?(==) : (a, a) -> bool ) : maybe<(a, heap<a>)>
  if h.size == 0 then
    Nothing
  else 
    val index = if h.size == 1 then
      1
    elif h.size == 2 then
      2
    else
      if h.data.unsafe-idx( 2.ssize_t ) > h.data.unsafe-idx( 3.ssize_t ) then
        2
      else
        3
    val max = h.data.unsafe-idx( index.ssize_t )
    match h
      Heap( data, size ) ->
        val last = data.unsafe-idx( size.ssize_t )
        val data' = data.unsafe-set( 1, last )
        data'.unsafe-vector-clear-at( size.ssize_t )
        Just( (max, Heap( data', size - 1 ).push-down( 1 )) )


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
    heap.data.foreach fn (x)
      trace(x.show)
    expect(Just(12), { min }, details = "Expected Just(12) but found " ++ min.show )
  