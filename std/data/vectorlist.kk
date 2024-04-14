// This module provides a simple resizable vector implementation
module std/data/vectorlist

/*
  todo
  list/vectorlist
  foreach-while
  list
  vector
*/

fun flatten( item : maybe<maybe<a>> ) : maybe<a>
  match item
    Just(x) -> x
    Nothing -> Nothing

pub struct vectorlist<a>
  data : vector<maybe<a>>
  pub capacity : int
  size : int

// Create a new vectorlist of length `n` with initial elements `default`.
pub fun vectorlist( n : int, default : a ) : vectorlist<a>
  Vectorlist( vector-init( n, fn (_) Just(default)), n, n )

// Create a new vectorlist of length `n` with initial elements given by function `f` which can have a control effect.
pub fun vectorlist-init( ^capacity : int, f : (int) -> e a ) : e vectorlist<a>
  val g = fn(x : int) Just(f(x))
  Vectorlist( vector-init( capacity, g), capacity, capacity )

// Create an empty vectorlist.
pub fun unit/vectorlist() : vectorlist<a>
  Vectorlist( unit/vector(), 0, 0 )

// Create a vectorlist from a vector
pub fun vector/vectorlist( v : vector<a> ) : vectorlist<a>
  Vectorlist( v.vector/map( fn (x) Just(x) ), v.length, v.length )

// Resizes the vectorlist to a new capacity.
// If new-capacity is smaller than size then the vectorlist is truncated
pub fun resize( v : vectorlist<a>, new-capacity : int ) : vectorlist<a>
  val new-data = vector-init( new-capacity ) fn (x) match v.data.at(x)
    Just(y) -> y
    Nothing -> Nothing
  val updated-size = if new-capacity > v.size then v.size else new-capacity
  v( data = new-data, capacity = new-data.length )

// Return the element at position `index` in vectorlist `v` or `Nothing` if out of bounds
pub fun at( ^v : vectorlist<a>, ^index : int ) : maybe<a>
  match v.data.at(index)
    Nothing -> Nothing
    Just(x) -> x

// Set an element in the vectorlist at position `index` in vectorlist `v` with `value`
// Returns `Nothing` if the `index` is out of bounds
pub fun set( ^v : vectorlist<a>, ^index : int, value : a ) : maybe<vectorlist<a>>
  if index < 0 || index >= v.size then
    Nothing
  else
    Just( v( data = vector-init( v.capacity, fn (i) if i == index then Just(value) else v.data.vector/at(i).flatten ) ) )


fun resizer( current : int ) : int
  if current <= 1 then 1 else current * 2

// Pushes `value` at the end of the vectorlist `v`.
// Push also takes implicit `resizer` to allow for custom growth factors
pub fun push( ^v : vectorlist<a>, value : a, ?resizer : (int) -> int) : vectorlist<a>
  val vec = if v.size >= v.capacity then
    val new-capacity = resizer(v.capacity)
    v.resize(new-capacity)
  else 
    v
  vec( data = vector-init( vec.capacity, fn (i) if i == v.size then Just(value) else vec.data.vector/at(i).flatten ), size = vec.size + 1)

// Removes the ending element from the vectorlist `v`. Returns `Nothing` if size is 0.
pub fun pop( ^v : vectorlist<a>) : maybe<vectorlist<a>>
  if v.size == 0 then
    Nothing
  else
    Just( v( data = vector-init( v.capacity, fn (i) if i == v.size - 1 then Nothing else v.data.vector/at(i).flatten ), size = v.size - 1 ) )

// Gets the ending element from the vectorlist `v`. Returns `Nothing` if size is 0.
pub fun last( ^v : vectorlist<a> ) : maybe<a>
  if v.size == 0 then Nothing
  else v.at(v.size - 1)

// Fetches the current size of the vectorlist `v`. This isn't the capacity of the vectorlist.
pub fun length( ^v : vectorlist<a> ) : int
  v.size

// Apply a total function `f` to each element in a vectorlist `v`.
pub fun map( ^v : vectorlist<a>, f : (a) -> e b ) : e vectorlist<b>
  val new-data = v.data.map() fn (n) match n
    Just(x) -> Just(f(x))
    Nothing -> Nothing
  Vectorlist( new-data, new-data.length, v.size )

// Invoke a function `f` for each element in a vectorlist `v`.
pub fun foreach( v : vectorlist<a>, f : (a) -> e () ) : e ()
  for( v.size ) fn (i) match v.at(i)
    Just(x) -> f(x)
    Nothing -> ()

// Invoke a function `f` for each element in a vectorlist `v` with the corresponding index.
pub fun foreach-indexed( v : vectorlist<a>, f : (int, a) -> e () ) : e ()
  for( v.size ) fn (i) match v.at(i)
    Just(x) -> f(i, x)
    Nothing -> ()


fun test-push()
  var vec := unit/vectorlist()
  vec := vec.push(2)
  vec.at(0).show.println

fun test-pop()
  var vec := vectorlist-init(10) fn (i) i
  "before pop".println
  vec.foreach() fn (x)
    x.println
  match vec.pop()
    Just(v) -> vec := v
    Nothing -> ()
  "\nafter pop".println
  vec.foreach() fn (x)
    x.println

fun test-resize-push()
  var vec := vectorlist-init(10) fn (i) i
  "capacity before".println
  vec.capacity.show.println
  vec := vec.push(11)
  "capacity after".println
  vec.capacity.show.println