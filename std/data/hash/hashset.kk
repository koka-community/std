/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

module std/data/hash/hashset
import std/num/int64
import std/test
import std/num/random
import std/core-extras

/*
  todo:
  union: I am not sure how to do this one without either exposing a div effect or duplicating code from insert
  intersection
  difference
*/

pub struct hash-set<v>
  data : vector<list<v>>
  amount : int
  seed : int64

// Creates a hash-set with a specified inital `capacity`.
// If zero then the hash-set will set capacity to 1.
// Random effect is needed to initalize the seed.
pub fun hash-set( capacity : int ) : random hash-set<v>
  Hash-set( vector( if capacity > 0 then capacity else 1, Nil ), 0, random-int64() )

// Creates a hash-set with a specified inital `capacity` and a user defined `seed`.
// If zero then the hash-set will set capacity to 1.
pub fun hash-set-seeded( capacity : int, seed : int64 ) : hash-set<v>
  Hash-set( vector( if capacity > 0 then capacity else 1, Nil ), 0, seed )

// Creates a hash-set from a list `xs`. This hash-set has the same capacity as the length of the list `xs`.
// Random effect is needed to initalize the seed.
pub fun list/hash-set( xs : list<v>, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : random hash-set<v>
  from-list-helper( hash-set( xs.length ), xs, ?hash = hash, ?(==) = (==) )

// Creates a hash-set from a list `xs` and with a `seed`. This hash-set has the same capacity as the length of the list `xs`.
pub fun list/hash-set-seeded( xs : list<v>, seed : int64, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set<v>
  from-list-helper( hash-set-seeded( xs.length, seed ), xs, ?hash = hash, ?(==) = (==) )

fun from-list-helper( hs : hash-set<v>, l : list<v>, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set<v>
  match l
    Nil -> hs
    Cons(x, xs) -> 
      from-list-helper( hs.insert( x, ?hash = hash, ?(==) = (==) ), xs, ?hash = hash, ?(==) = (==) )


// Resizes a hash-set with `new-capacity` being the new capacity of the hashset. 
// If `new-capacity` is smaller than the capacity of the hash-set then there will be more hash collisions.
pub fun resize( hs : hash-set<v>, new-capacity : int, ?hash : (v, int64) -> int ) : hash-set<v>
  val buckets: vector<list<v>> = vector(hs.data.length, Nil)
  match hs
    Hash-set(data, size, seed) ->
      for( data.length ) fn (i)
        match data.at(i)
          Nothing -> ()
          Just(x) -> 
            buckets.drop-at( i.ssize_t )
            buckets.unsafe-assign( i.ssize_t, x )

            data.drop-at( i.ssize_t )
      
      val new-data = realloc(data, new-capacity.ssize_t)
      for( new-data.length ) fn (i)
        new-data.unsafe-assign( i.ssize_t, Nil )
      val new-hs = Hash-set( data = new-data, amount = size, seed = seed)
      
      new-hs.rehash( buckets, ?hash = hash )

fun rehash( hs : hash-set<v>, buckets : vector<list<v>>, ?hash : (v, int64) -> int ) : hash-set<v>
  buckets.foreach fn (bucket)
    bucket.foreach fn (entry)
      val the-hash = hash(entry, hs.seed)
      val position = the-hash % hs.data.length
      match hs.data.at( position )
        Nothing -> ()
        Just(xs) -> hs.data.unsafe-assign( position.ssize_t, Cons( entry, xs ) )
  hs

// Internal function that dictates when to resize the hash-set. This can be overridden with implicits.
fun when-resize( table-size : int, item-count : int ) : bool
  if 2 * table-size <= item-count then
    True
  else
    False

// Internal function that determines the new size of a hash-set when inserting. This can be overridden with implicits.
fun resizer( table-size : int, item-count : int ) : int
   item-count * 2

// Inserts a `value` into the hash-set.
pub fun insert( hs : hash-set<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool, ?when-resize : (int, int) -> bool, ?resizer : (int, int) -> int ) : hash-set<v>
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  val new-hs = match hs
    Hash-set(data, amount, seed) ->
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = Cons( value, data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x == value) )
      data.unsafe-assign( position.ssize_t, bucket )
      val new-amount = if old-bucket-size < data.unsafe-idx( position.ssize_t ).length then amount + 1 else amount
      Hash-set(data, new-amount, seed)
  if when-resize( new-hs.data.length, new-hs.amount ) then
    new-hs.resize( resizer( new-hs.data.length, new-hs.amount ), ?hash = hash )
  else
    new-hs

// Removes a value from the hash-set with a given `value`.
pub fun remove( hs : hash-set<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set<v>
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  match hs
    Hash-set(data, amount, seed) -> 
      val bucket = data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x == value)
      data.unsafe-assign( position.ssize_t, bucket )
      Hash-set( data, amount - 1, seed)

// Checks if a value is in the hash-set `hs` and returns `True` if found and `False` if not found.
pub fun contains( hs : hash-set<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : bool
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  match hs.data.unsafe-idx( position.ssize_t ).filter( fn(x) x == value )
    Cons(_, _) -> True
    Nil -> False

// Fetches the amount of items in the hash-set
pub fun length( hs : hash-set<v> ) : int
  hs.amount

// Removes all buckets from the hash-set, effectively clearing the hash-set.
pub fun clear( hs : hash-set<v>) : hash-set<v>
  match hs
    Hash-set(data, _, seed) ->
      for( data.length ) fn (x) 
        data.drop-at( x.ssize_t )
        data.unsafe-assign(x.ssize_t, Nil)
      Hash-set( data, 0, seed )

// Applies a function `f` to each key-value of the hash-set via a tuple.
pub fun effect/map( hs : hash-set<a>, f : (a) -> e b ) : e hash-set<b>
  val new-data = hs.data.map fn (buckets)
    buckets.list/map(f)
  Hash-set( new-data, hs.amount, hs.seed )

// Applies a function `f` to each key-value of the hash-set via a tuple.
pub fun unique/map( hs : hash-set<a>, f : (a) -> b ) : hash-set<b>
  match hs
    Hash-set(data, amount, seed) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map(f)
      Hash-set( new-data, amount, seed )

// Invoke a function `f` for each key-value of the hash-set.
pub fun foreach( hs : hash-set<v>, f : (v) -> e () ) : e ()
  for( hs.data.length ) fn (i) 
    hs.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      f(entry)


fun test-hash-set()
  basic/test("hash-set insert")
    val hs = hash-set(1)
    val hs' = hs.insert( 2, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32) )
    val value = hs'.contains(2, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32))
    expect(True, { value } , details="Expected True but got " ++ value.show)
  basic/test("hash-set remove")
    val hs = hash-set(1)
    val hs' = hs.insert(2, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32) )
    val hs@ = hs'.remove(2, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32) )
    expect(0, { hs@.length } , details="Expected 0 but got " ++ hs@.length.show)
  basic/test("hash-set stress test")
    var hs := hash-set(1)
    for(50000) fn (i)
      hs := hs.insert(i, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32) )
    expect(True, { True } , details="Expected Resizing to work")
  basic/test("hash-set clear")
    var hs := hash-set(1)
    for(50) fn (i)
      hs := hs.insert(i, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32) )
    hs := hs.clear()
    val value = hs.length()
    expect(0, { value } , details="Expected 0 but got " ++ value.show)
  basic/test("hash-set clear then fill")
    var hs := hash-set(1)
    for(50) fn (i)
      hs := hs.insert(i, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32) )
    hs := hs.clear()
    for(50) fn (i)
      hs := hs.insert(i, ?hash = fn (x, _) x * 2654435761 % (2 ^ 32) )
    val value = hs.length()
    expect(50, { value } , details="Expected 0 but got " ++ value.show)
  
