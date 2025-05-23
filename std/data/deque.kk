/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a simple deque using a circular vector
module std/data/deque
import std/core-extras

pub value struct deque<a>
  data : vector<a>
  front-idx : int
  back-idx : int
  size : int

// Creates a Deque that is of size `n` with values specified by `default`.
pub inline fun deque( n : int, default : a) : deque<a>  
  Deque( vector-init( n, fn (_) default ), n - 1, n, n)

// Creates a Deque that is of size `n` with values defined by the function `f`.
pub inline fun deque-init( ^n : int, f : (int) -> e a ) : e deque<a>
  Deque( vector-init( n, f ), n - 1, n, n )

// Creates a Deque that is of size `n` with no values.
pub inline fun deque-capacity( ^n : int ) : deque<a>
  Deque( unsafe-vector( n.ssize_t ), 0, 0, 0)

// Creates a Deque that is empty and with size of `0`.
pub inline fun unit/deque() : deque<a>
  Deque( unit/vector(), 0, 0, 0 )

// Resizes the deque `d` with the `new-capacity`.
// If `new-capacity` is smaller than the current size then `d` is truncated.
pub fun resize( d : deque<a>, new-capacity : int ) : deque<a>
  match d
    Deque(data, _, _, size) -> 
      val new-data = unsafe-vector( new-capacity.ssize_t )
      val limit = if data.length < new-data.length then data.length else new-data.length
      for( limit ) fn (i)
        match d.at( i )
          Nothing -> ()
          Just(element) -> new-data.unsafe-assign( i.ssize_t, element)
      val new-size = if size > new-capacity then new-capacity else size
      Deque( new-data, front-idx = new-data.length - 1, back-idx = new-size, size = new-size )

// Fetches an element from deque `d` with `index`.
// This function handles ring buffer logic
pub fun at( ^d : deque<a>, ^index : int ) : maybe<a>
  if index < 0 || index >= d.size then
    Nothing
  else
    val offset : int = d.front-idx + 1
    val real-index = (index + offset) % d.data.length
    d.data.at(real-index)

// Sets the deque `d` at the specified `index` with a `value`.
pub fun set( ^d : deque<a>, ^index : int, value : a ) : maybe<deque<a>>
  if index < 0 || index >= d.size then
    Nothing
  else
    match d
      Deque(data, front, back, size) ->
        val real-index = (index + front) % size
        Just( Deque( data.unsafe-set( index, value ), front, back, size ) )

// Internal function for dictating how big the new size should be.
pub fun resizer( current : int ) : int
  if current < 1 then 1 else current * 2

// Pushes a `value` onto the front of a deque `d`.
// `?resizer` controls how big a deque should be when it needs to be resized.
pub fun push-front( ^d : deque<a>, value : a, ?resizer : (int) -> int ) : deque<a>
  val vec = if d.size >= d.data.length then
      val new-capacity = resizer( d.data.length )
      d.resize( new-capacity )
    else
      d
  match vec
    Deque(data, front, back, size) -> 
      // We have to adjust the back on the first insertion so we don't overwrite the first element
      val new-back = if size == 0 then back + 1 else back
      val new-front = (front - 1) % data.length
      Deque( data.unsafe-set( front, value ), new-front, new-back, size + 1)

// Pushes a `value` onto the back of a deque `d`.
// `?resizer` controls how big a deque should be when it needs to be resized.
pub fun push-back( ^d : deque<a>, value : a, ?resizer : (int) -> int ) : deque<a>
  val vec = if d.size >= d.data.length then
      val new-capacity = resizer( d.data.length )
      d.resize( new-capacity )
    else
      d
  match vec
    Deque(data, front, back, size) -> 
      // We have to adjust the front on the first insertion so we don't overwrite the first element
      val new-front = if size == 0 then front - 1 else front
      val new-back = (front + 1) % data.length
      Deque( data.unsafe-set( back, value ), new-front, new-back, size + 1)

// Pops a value from the front of a deque `d`.
pub fun pop-front( ^d : deque<a> ) : maybe<(a, deque<a>)>
  if d.size == 0 then
    Nothing
  else
    match d
      Deque(data, front, back, size) -> 
        val index = (front + 1) % data.length
        val item = data.unsafe-idx( index.ssize_t )
        val data' = if data.is-vec-unique then
            data.drop-at( index.ssize_t )
            data
          else
            val new-data = data.copy
            new-data.drop-at( index.ssize_t )
            new-data
        Just( (item, Deque( data', index, back, size - 1 ) ) )

// Pops a value from the back of a deque `d`.
pub fun pop-back( ^d : deque<a> ) : maybe<(a, deque<a>)>
  if d.size == 0 then
    Nothing
  else
    match d
      Deque(data, front, back, size) -> 
        val index = (back - 1) % data.length
        val item = data.unsafe-idx( index.ssize_t )
        val data' = if data.is-vec-unique then
            data.drop-at( index.ssize_t )
            data
          else
            val new-data = data.copy
            new-data.drop-at( index.ssize_t )
            new-data
        Just( (item, Deque( data', front, index, size - 1 ) ) )

// Fetches a value from the front of a deque `d`.
pub fun front( ^d : deque<a> ) : maybe<a>
  if d.size == 0 then Nothing
  else d.at( 0 )

// Fetches a value from the back of a deque `d`.
pub fun back( ^d : deque<a> ) : maybe<a>
  if d.size == 0 then Nothing
  else d.at( d.size )

// Clears a deque `d`, while retaining the capacity.
pub fun clear( ^d : deque<a> ) : deque<a>
  match d
    Deque(data, _, _, size) ->
      if data.is-vec-unique then
        forz(size.ssize_t) fn (i) 
          data.unsafe-vector-clear-at( i )
        Deque( data, 0, 0, 0)
      else
        Deque( unsafe-vector( data.length.ssize_t ), 0, 0, 0 )

// Fetches the length of a deque `d`.
pub fun length( ^d : deque<a> ) : int
  d.size

// Fetches the capacity of a deque `d`.
pub fun capacity( ^d : deque<a> ) : int
  d.data.length

// Apply an effectful function `f` to each element in a deque `d`.
pub fun effect/map( ^d : deque<a>, f : (a) -> e b ) : e deque<b>
  match d
    Deque( data, front, back, size ) -> 
      val new-data = data.map( f )
      Deque( new-data, front, back, size )

// Apply a function `f` to each element in a deque `d`.
pub fun unique/map( d : deque<a>, f : (a) -> b ) : deque<b>
  match d
    Deque( data, front, back, size ) -> 
      val new-data = data.unique/map( f )
      Deque( new-data, front, back, size )

// Invoke a function `f` for each element in a deque `d`.
pub fun foreach( d : deque<a>, f : (a) -> e () ) : e ()
  for( d.size ) fn (i)
    val offset : int = d.front-idx + 1
    val real-index = (i + offset) % d.data.length
    f( d.data.unsafe-idx( real-index.ssize_t ) )

// Invoke a function `f` for each element in a deque `d` with its index.
pub fun foreach-indexed( d : deque<a>, f : (int, a) -> e () ) : e ()
  for( d.size ) fn (i)
    val offset : int = d.front-idx + 1
    val real-index = (i + offset) % d.data.length
    f( i, d.data.unsafe-idx( real-index.ssize_t ))

// Equality checking for deque.
pub fun (==)( xs : deque<a>, ys : deque<a>, ?(==) : (a, a) -> bool ) : bool
  if xs.length != ys.length then
    False
  else
    val result = for-while(xs.length) fn(i) 
      match (xs.at(i), ys.at(i))
        (Just(x), Just(y)) -> 
          if x == y then 
            Nothing
          else
            Just(False)
        _ -> Nothing
    match result
      Nothing -> True
      Just(x) -> x
