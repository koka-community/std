/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a simple resizable vector implementation
module std/data/vector-list
import std/core-extras
import std/test/test
/*
  todo
  list/vector-list
  foreach-while
  list
  vector
*/

alias vlist<a> = vector-list<a> 

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

pub struct vector-list<a>
  data : vector<maybe<a>>
  vec-length : int
  size : int

// Create a new vector-list of length `n` with initial elements `default`.
pub inline fun vector-list( n : int, default : a ) : vector-list<a>
  Vector-list( vector-init( n, fn (_) Just(default)), n, n )

// Create a new vector-list of length `n` with initial elements given by function `f` which can have a control effect.
pub inline fun vector-list-init( ^n : int, f : (int) -> e a ) : e vector-list<a>
  val g = fn(x : int) Just(f(x))
  Vector-list( vector-init( n, g), n, n )

// Create an empty vector-list.
pub inline fun unit/vector-list() : vector-list<a>
  Vector-list( unit/vector(), 0, 0 )

// Create a vector-list from a vector
pub inline fun vector/vector-list( v : vector<a> ) : vector-list<a>
  Vector-list( v.vector/map( fn (x) Just(x) ), v.length, v.length )

// Resizes the vector-list to a new capacity.
// If new-capacity is smaller than size then the vector-list is truncated
pub fun resize( v : vector-list<a>, new-capacity : int ) : vector-list<a>
  val new-data = vector-init( new-capacity ) fn (x) match v.data.at(x)
    Just(y) -> y
    Nothing -> Nothing
  val updated-size = if new-capacity > v.size then v.size else new-capacity
  v( data = new-data, vec-length = new-data.length )

// Return the element at position `index` in vector-list `v` or `Nothing` if out of bounds
pub fun at( ^v : vector-list<a>, ^index : int ) : maybe<a>
  match v.data.at(index)
    Nothing -> Nothing
    Just(x) -> x

// Set an element in the vector-list at position `index` in vector-list `v` with `value`
// Returns `Nothing` if the `index` is out of bounds
pub fun set( ^v : vector-list<a>, ^index : int, value : a ) : exn maybe<vector-list<a>>
  if index < 0 || index >= v.size then
    Nothing
  else
    Just( v( data = v.data.set( index, Just(value) ).unjust ) )


fun resizer( current : int ) : int
  if current <= 1 then 1 else current * 2

// Pushes `value` at the end of the vector-list `v`.
// Push also takes implicit `resizer` to allow for custom growth factors
// It is important that `resizer` must handle the case of where the current capacity is 0
pub fun push( ^v : vector-list<a>, value : a, ?resizer : (int) -> int ) : exn vector-list<a>
  val vec = if v.size >= v.vec-length then
    val new-capacity = resizer(v.vec-length)
    v.resize(new-capacity)
  else 
    v
  vec( data = vec.data.set( v.size, Just(value) ).unjust, size = vec.size + 1)

// Removes the ending element from the vector-list `v`. Returns `Nothing` if size is 0.
pub fun pop( ^v : vector-list<a>) : exn maybe<vector-list<a>>
  if v.size == 0 then
    Nothing
  else
    Just( v( data = v.data.set( v.size - 1, Nothing ).unjust, size = v.size - 1 ) )

// Gets the ending element from the vector-list `v`. Returns `Nothing` if size is 0.
pub fun last( ^v : vector-list<a> ) : maybe<a>
  if v.size == 0 then Nothing
  else v.at(v.size - 1)

// Fetches the current size of the vector-list `v`. This isn't the capacity of the vector-list.
pub fun length( ^v : vector-list<a> ) : int
  v.size

// Fetches the current capacity of the vector-list `v`. This isn't the amount of elements of the vector-list.
pub fun capacity( ^v : vector-list<a> ) : int
  v.vec-length

// Apply a function `f` to each element in a vector-list `v`.
pub fun map( ^v : vector-list<a>, f : (a) -> e b ) : e vector-list<b>
  val new-data = v.data.map() fn (n) match n
    Just(x) -> Just(f(x))
    Nothing -> Nothing
  Vector-list( new-data, new-data.length, v.size )

// Invoke a function `f` for each element in a vector-list `v`.
pub fun foreach( v : vector-list<a>, f : (a) -> e () ) : e ()
  for( v.size ) fn (i) match v.at(i)
    Just(x) -> f(x)
    Nothing -> ()

// Invoke a function `f` for each element in a vector-list `v` with the corresponding index.
pub fun foreach-indexed( v : vector-list<a>, f : (int, a) -> e () ) : e ()
  for( v.size ) fn (i) match v.at(i)
    Just(x) -> f(i, x)
    Nothing -> ()

fun test-vlist()
  basic/test("vlist push")
    var vec := unit/vector-list()
    vec := vec.push(2)
    val value = vec.at(0)
    val out = expect(Just(2), { value } , details="Expected Just(2) but got " ++ value.show)
    ()
  basic/test("vlist pop")
    var vec := vector-list-init(10) fn (i) i
    match vec.pop()
      Just(v) -> vec := v
      Nothing -> ()
    var after-pop := ""
    vec.foreach() fn (x)
      after-pop := after-pop ++ x.show ++ " "
    val out = expect("0 1 2 3 4 5 6 7 8 ", { after-pop }, details="Expected '0 1 2 3 4 5 6 7 8 ' but got: " ++ after-pop)
    ()
  basic/test("vlist resize push")
    var vec := vector-list-init(10) fn (i) i
    vec := vec.push(11)
    val out = expect(20, { vec.capacity }, details="Expected 20 but got: " ++ vec.capacity.show)
    ()
