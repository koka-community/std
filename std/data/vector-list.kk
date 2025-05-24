/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a simple resizable vector implementation
module std/data/vector-list
import std/core-extras 
import std/num/int64
import std/data/hash
/*
  todo
  list/vector-list
  foreach-while
  list
  vector
*/

pub alias vlist<a> = vector-list<a> 

// Create a new vector-list of length `n` with initial elements `default`.
pub fun vlist( n : int, default : a ) : vector-list<a>
  vector-list(n, default)

// Create a new vector-list of length `n` with initial elements given by function `f` which can have a control effect.
pub fun vlist-init( n : int, f : (int) -> e a ) : e vector-list<a>
  vector-list-init(n, f)

// Create an empty vector-list.
pub fun unit/vlist() : vector-list<a>
  unit/vector-list()

// Create a vector-list from a vector
pub fun vector/vlist( v : vector<a> ) : vector-list<a>
  vector/vector-list(v)

pub value struct vector-list<a>
  data : vector<a>
  size : int

// Create a new vector-list of length `n` with initial elements `default`.
pub inline fun vector-list( n : int, default : a ) : vector-list<a>
  Vector-list( vector-init( n, fn (_) default), n )

// Create a new vector-list of length `n` with initial elements given by function `f` which can have a control effect.
pub inline fun vector-list-init( ^n : int, f : (int) -> e a ) : e vector-list<a>
  Vector-list( vector-init( n, f), n )

// Create an empty vector-list.
pub inline fun unit/vector-list() : vector-list<a>
  Vector-list( unit/vector(), 0 )

// Create a vector-list from a vector
pub inline fun vector/vector-list( v : vector<a> ) : vector-list<a>
  Vector-list( v, v.length )

// Resizes the vector-list to a new capacity.
// If new-capacity is smaller than size then the vector-list is truncated
pub fun resize( v : vector-list<a>, new-capacity : int ) : vector-list<a>
  match v
    Vector-list(data, old-size) ->
      val new-size = if old-size < new-capacity then old-size else new-capacity
      Vector-list( data = realloc(data, new-capacity.ssize_t), size = new-size )

// Return the element at position `index` in vector-list `v` or `Nothing` if out of bounds
pub fun at( ^v : vector-list<a>, ^index : int ) : maybe<a>
  if index >= 0 && index < v.size then 
    v.data.at(index)
  else Nothing

// Set an element in the vector-list at position `index` in vector-list `v` with `value`
// Returns `Nothing` if the `index` is out of bounds
pub fun set( v : vector-list<a>, ^index : int, value : a ) : maybe<vector-list<a>>
  if index < 0 || index >= v.size then
    Nothing
  else
    match v
      Vector-list(data, size) ->
        Just(Vector-list( data.unsafe-set( index, value ), size ))

pub fun resizer( current : int ) : int
  if current < 1 then 1 else current * 2

// Pushes `value` at the end of the vector-list `v`.
// Push also takes implicit `resizer` to allow for custom growth factors
// It is important that `resizer` must handle the case of where the current capacity is 0
pub fun push( ^v : vector-list<a>, value : a, ?resizer : (int) -> int ) : vector-list<a>
  val vec = if v.size >= v.data.length then
    val new-capacity = resizer( v.data.length )
    // trace("Resizing to " ++ new-capacity.show)
    v.resize( new-capacity )
  else 
    v
  match vec
    Vector-list(data, size) ->
      // trace("Pushing " ++ size.show)
      Vector-list( data.unsafe-set(size, value), size + 1 )

// Removes the ending element from the vector-list `v`. Returns `Nothing` if size is 0.
pub fun pop( ^v : vector-list<a>) : maybe<(a, vector-list<a>)>
  if v.size == 0 then
    Nothing
  else
    val new-size = v.size - 1
    match v.at(new-size)
      Nothing -> Nothing
      Just(x) ->
        v.data.drop-at(new-size.ssize_t) // X was dupped for v.at(), but we are making it no longer accessible from the vector        
        Just((x, Vector-list(v.data, size=new-size))) 

// Gets the ending element from the vector-list `v`. Returns `Nothing` if size is 0.
pub fun last( ^v : vector-list<a> ) : maybe<a>
  if v.size == 0 then Nothing
  else v.at(v.size - 1)

pub fun clear( ^v : vector-list<a> ) : vector-list<a>
  match v
    Vector-list(data, size) ->
      if data.is-vec-unique then
        data.unsafe-vector-clear( size.ssize_t )
        Vector-list( data, 0 )
      else
        Vector-list( unsafe-vector( data.length.ssize_t ), 0 )

// Fetches the current size of the vector-list `v`. This isn't the capacity of the vector-list.
pub fun length( ^v : vector-list<a> ) : int
  v.size

// Fetches the current capacity of the vector-list `v`. This isn't the amount of elements of the vector-list.
pub fun capacity( ^v : vector-list<a> ) : int
  v.data.length

// Apply a function `f` to each element in a vector-list `v`.
pub fun effect/map( ^v : vector-list<a>, f : (a) -> e b ) : e vector-list<b>
  val new-data = v.data.map(f)
  Vector-list( new-data, v.size )

pub fun unique/map( v : vector-list<a>, f : (a) -> b ) : vector-list<b>
  match v
    Vector-list(data, size) -> 
      val new-data = data.unique/map(f)
      Vector-list( new-data, size )

// Invoke a function `f` for each element in a vector-list `v`.
pub fun foreach( v : vector-list<a>, f : (a) -> e () ) : e ()
  for( v.size ) fn (i) 
    f(v.data.unsafe-idx( i.ssize_t ))

// Invoke a function `f` for each element in a vector-list `v` with the corresponding index.
pub fun foreach-indexed( v : vector-list<a>, f : (int, a) -> e () ) : e ()
  for( v.size ) fn (i) 
    f(i, v.data.unsafe-idx( i.ssize_t ))

extern hash-vector-int64( v : vector<int64>, seed : int64 ) : int
  c "kk_hash_vector_int64"

pub fun vlist/hash( v : vector-list<a>, ?hasher: (a, int64) -> int, ?seed : int64 ) : int
  val vec = unsafe-vector( v.size.ssize_t )
  for( v.size ) fn (i)
    vec.unsafe-assign( i.ssize_t, hasher( v.data.unsafe-idx( i.ssize_t ), ?seed ).int64 )
  hash-vector-int64( vec, ?seed )
