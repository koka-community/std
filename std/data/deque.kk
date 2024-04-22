/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a simple deque using a circular vector
module std/data/deque
import std/core-extras
import std/test
import std/core/unsafe

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
      Deque( new-data, front-idx = -1 % new-data.length, back-idx = new-size, size = new-size )

// Fetches an element from deque `d` with `index`.
// This function handles ring buffer logic
pub fun at( ^d : deque<a>, ^index : int ) : maybe<a>
  if index < 0 || index > d.size then
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
fun resizer( current : int ) : int
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
        match data.at( index )
          Nothing -> Nothing
          Just(x) -> 
            data.drop-at( index.ssize_t )
            Just( (x, Deque( data, index, back, size - 1 ) ) )

// Pops a value from the back of a deque `d`.
pub fun pop-back( ^d : deque<a> ) : maybe<(a, deque<a>)>
  if d.size == 0 then
    Nothing
  else
    match d
      Deque(data, front, back, size) -> 
        val index = (back - 1) % data.length
        match data.at( index )
          Nothing -> Nothing
          Just(x) -> 
            data.drop-at( index.ssize_t )
            Just( (x, Deque( data, front, index, size - 1 ) ) )

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
        for(size) fn (i) 
          data.unsafe-vector-clear-at( i.ssize_t )
          ()// This is needed to prevent a compiler error
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
  val new-data = unsafe-vector( d.data.length.ssize_t )
  for( d.size ) fn (i)
    match d.at( i )
      Nothing -> ()
      Just(x) -> new-data.unsafe-assign( i.ssize_t, f(x) )
  val front = -1 % new-data.length
  Deque( new-data, front, d.size, d.size )

// Apply a function `f` to each element in a deque `d`.
pub fun unique/map( d : deque<a>, f : (a) -> b ) : deque<b>
  val new-data = unsafe-vector( d.data.length.ssize_t )
  for( d.size ) fn (i)
    match d.at( i )
      Nothing -> ()
      Just(x) -> new-data.unsafe-assign( i.ssize_t, f(x) )
  val front = -1 % new-data.length
  Deque( new-data, front, d.size, d.size )

// Invoke a function `f` for each element in a deque `d`.
pub fun foreach( d : deque<a>, f : (a) -> e () ) : e ()
  for( d.size ) fn (i)
    match d.at( i )
      Nothing -> ()
      Just(x) -> f( x )

// Invoke a function `f` for each element in a deque `d` with its index.
pub fun foreach-indexed( d : deque<a>, f : (int, a) -> e () ) : e ()
  for( d.size ) fn (i)
    match d.at( i )
      Nothing -> ()
      Just(x) -> f( i, x )

// Equality checking for deque.
pub fun (==)( xs : deque<a>, ys : deque<a>, ?(==) : (a, a) -> bool ) : bool
  if xs.length != ys.length then
    False
  else
    val result = for-while(xs.length) fn(i) 
      match (xs.at(i), ys.at(i))
        (Just(x), Just(y)) -> if x == y then 
            Nothing
          else
            Just(False)
        _ -> Nothing
    match result
      Nothing -> True
      Just(x) -> x
      


ref struct something {i: int}
fun test-deque()
  basic/test("deque push-front")
    val deq = unit/deque()
    val deq' = deq.push-front(2)
    val value = deq'.at(0)
    expect(Just(2), { value }, details="Expected Just(2) but got " ++ value.show )
  basic/test("deque push-back")
    val deq = unit/deque()
    val deq' = deq.push-back(2)
    val value = deq'.at(0)
    expect(Just(2), { value }, details="Expected Just(2) but got " ++ value.show )
  basic/test("deque pop-front")
    val deq = deque-init(10) fn (i) Something(i)
    val deq' = match deq.pop-front()
      Just((x, v)) -> 
        expect(Something(0), { x }, ?(==)= fn(a, b) a.i == b.i, ?show=fn(a) a.i.show)
        v
      Nothing -> deq
    var after-pop := ""
    deq'.foreach() fn (x)
      after-pop := after-pop ++ x.i.show ++ " "
    expect("1 2 3 4 5 6 7 8 9 ", { after-pop }, details="Expected '1 2 3 4 5 6 7 8 9 ' but got: " ++ after-pop)
  basic/test("deque pop-back")
    val deq = deque-init(10) fn (i) Something(i)
    val deq' = match deq.pop-back()
      Just((x, v)) -> 
        expect(x, {Something(9)}, ?(==)= fn(a, b) a.i == b.i, ?show=fn(a) a.i.show)
        v
      Nothing -> deq
    var after-pop := ""
    deq'.foreach() fn (x)
      after-pop := after-pop ++ x.i.show ++ " "
    expect("0 1 2 3 4 5 6 7 8 ", { after-pop }, details="Expected '0 1 2 3 4 5 6 7 8 ' but got: " ++ after-pop)
  basic/test("deque unique map")
    val deq = deque-init(10) fn (i) Something(i)
    val deq2 = deq.unique/map(fn (x) x.i + 1)
    var after-map := ""
    deq2.foreach() fn (x)
      after-map := after-map ++ x.show ++ " "
    expect("1 2 3 4 5 6 7 8 9 10 ", { after-map }, details="Expected '0 1 2 3 4 5 6 7 8 9 ' but got: " ++ after-map)
  basic/test("deque resize push")
    val deq = deque-init(10) fn (i) i
    val deq' = deq.push-back(11)
    expect(20, { deq'.capacity }, details="Expected 20 but got: " ++ deq'.capacity.show)
  basic/test("deque copies on set")
    val deq1 = deque-init(10) fn (i) i
    val deq2 = deq1.set(0, 100).unjust
    expect(True, { deq1.at(0).default(0) != deq2.at(0).default(0) }, details="Expected deq1 and deq2 to be different")
  basic/test("deque doesn't copy when unique")
    val deq1 = deque-init(10) fn(i) Something(i)
    val deq10 = deq1.at(0).unjust
    val deq2 = deq1.set(9, Something(1)).unjust
    expect(False, { unsafe-ptr-eq(deq10, deq2.at(4).unjust) }, details="Expected deq1 and deq10 to be the same")
  basic/test("deque stress test")
    var deq := unit/deque()
    for(50000) fn (i)
      deq := (if i % 2 == 0 then deq.push-front(i) else deq.push-back(i))
    expect(True, { True }, details="Deque did not succeed")
  basic/test("deque clear test")
    var deq := deque(2, 2)
    deq := deq.clear
    expect(0, { deq.length }, details="Deque should have zero elements but instead has " ++ deq.length.show)
  basic/test("deque insertion after clear test")
    var deq := deque(2, 2)
    deq := deq.clear
    for(10) fn (i)
      deq := (if i % 2 == 0 then deq.push-front(i) else deq.push-back(i))
    expect(10, { deq.length }, details="Deque should have 10 elements but instead has " ++ deq.length.show)
  basic/test("deque truncation")
    val deq = deque(2, 2)
    val deq' = deq.resize(1)
    var truncated := ""
    deq'.foreach() fn (x)
      truncated := truncated ++ x.show ++ " "
    expect("2 ", { truncated }, details="Expected '2 ' but instead got " ++ truncated)

  