/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides an immutable bucket hashset implementation.
module std/data/hash-set
import std/num/int64
import std/core-extras
pub import std/data/hash

val int-hash : (int, int64) -> int = int/hash
val char-hash : (char, int64) -> int = char/hash
val bool-hash : (bool, int64) -> int = bool/hash
val string-hash : (string, int64) -> int = string/hash

pub struct hash-set<v>
  data : vector<list<v>>
  amount : int
  seed : int64

// Creates a hash-set with a specified inital `capacity`.
// If zero then the hash-set will set capacity to 1.
pub fun hash-set( capacity : int = 1 ) : hash-set<v>
  Hash-set( vector( if capacity > 0 then capacity else 1, Nil ), 0, thread/seed )

// Creates a hash-set with a specified inital `capacity` and a user defined `seed`.
// If zero then the hash-set will set capacity to 1.
pub fun hash-set-seeded( seed : int64, capacity : int = 1 ) : hash-set<v>
  Hash-set( vector( if capacity > 0 then capacity else 1, Nil ), 0, seed )

// Creates a hash-set from a list `xs`. This hash-set has the same capacity as the length of the list `xs`.
pub fun list/hash-set( xs : list<v>, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set<v>
  from-list-helper( hash-set( xs.length ), xs )

// Creates a hash-set from a list `xs` and with a `seed`. This hash-set has the same capacity as the length of the list `xs`.
pub fun list/hash-set-seeded( xs : list<v>, seed : int64, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set<v>
  from-list-helper( hash-set-seeded( seed, capacity = xs.length ), xs )

fun from-list-helper( hs : hash-set<v>, l : list<v>, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set<v>
  match l
    Nil -> hs
    Cons(x, xs) -> 
      from-list-helper( hs.insert( x ), xs )


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

            //data.drop-at( i.ssize_t )
      
      val new-data = realloc(data, new-capacity.ssize_t)
      Hash-set( data = helper/resize( new-data ).rehash( buckets, seed ), amount = size, seed = seed )


// This helper function either clears out a vector if it is unique or creates a new vector if it isn't unique.
fun helper/resize( v : vector<list<v>> ) : vector<list<v>>
  if v.is-vec-unique then
    //trace("helper/resize: vector is unique")
    for( v.length ) fn (i)
      v.drop-at( i.ssize_t )
      v.unsafe-assign( i.ssize_t, Nil )
    v
  else
    //trace("helper/resize: vector isn't unique")
    vector( v.length, Nil)

pub fun rehash( v : vector<list<v>>, buckets : vector<list<v>>, seed : int64, ?hash : (v, int64) -> int ) : vector<list<v>>
  if v.is-vec-unique then
    buckets.foreach fn (bucket)
      bucket.foreach fn (entry)
        val the-hash = hash(entry, seed)
        val position = the-hash % v.length
        match v.at( position )
          Nothing -> ()
          Just(xs) -> v.unsafe-assign( position.ssize_t, Cons( entry, xs ) )
    v
  else
    helper/rehash( v, buckets.vector/list.flatmap(fn (x) x), seed, ?hash = hash )

// This helper will use `buckets` to allow for a `div`-less use of `unsafe-set` to set values in vector `v`.
fun helper/rehash( v : vector<list<v>>, buckets : list<v>, seed : int64, ?hash : (v, int64) -> int ) : vector<list<v>>
  match buckets
    Nil -> v
    Cons(value, xs) ->
      val the-hash = hash(value, seed)
      val position = the-hash % v.length
      val new-v = v.unsafe-set( position, Cons( value, v.unsafe-idx( position.ssize_t ) ) )
      helper/rehash( new-v, xs, seed )

// Inserts a `value` into the hash-set.
pub fun insert( hs : hash-set<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool, ?when-resize : (int, int) -> bool, ?resizer : (int, int) -> int ) : hash-set<v>
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  val new-hs = match hs
    Hash-set(data, amount, seed) ->
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = Cons( value, data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x == value) )
      val new-data = data.unsafe-set( position, bucket )
      val new-amount = if old-bucket-size < new-data.unsafe-idx( position.ssize_t ).length then amount + 1 else amount
      Hash-set( new-data, new-amount, seed )
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
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x == value)
      val new-data = data.unsafe-set( position, bucket )
      val new-amount = if old-bucket-size > new-data.unsafe-idx( position.ssize_t ).length then amount - 1 else amount
      Hash-set( data, amount - 1, seed)

// Checks if a value is in the hash-set `hs` and returns `True` if found and `False` if not found.
pub fun contains( hs : hash-set<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : bool
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  match hs.data.unsafe-idx( position.ssize_t ).filter( _ == value )
    Cons(_, _) -> True
    Nil -> False

// Fetches the amount of items in the hash-set
pub fun length( hs : hash-set<v> ) : int
  hs.amount

// Removes all buckets from the hash-set, effectively clearing the hash-set.
pub fun clear( hs : hash-set<v>) : hash-set<v>
  match hs
    Hash-set(data, _, seed) ->
      if data.is-vec-unique then
        for( data.length ) fn (x) 
          data.drop-at( x.ssize_t )
          data.unsafe-assign(x.ssize_t, Nil)
        Hash-set( data, 0, seed )
      else
        Hash-set( vector( data.length, Nil ), 0, seed )

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

