/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// A mutable hashset implementation
module std/data/mutable/hashset-mut
import std/num/int64
import std/core-extras
import std/data/hash



pub struct hash-set-mut<v>
  data : vector<list<v>>
  amount : int
  seed : int64

// Creates a hash-set-mut with a specified inital `capacity`.
// If zero then the hash-set-mut will set capacity to 1.
pub fun hash-set-mut( capacity : int = 1 ) : hash-set-mut<v>
  Hash-set-mut( vector( if capacity > 0 then capacity else 1, Nil ), 0, thread/seed )

// Creates a hash-set-mut with a specified inital `capacity` and a user defined `seed`.
// If zero then the hash-set-mut will set capacity to 1.
pub fun hash-set-mut-seeded( seed : int64, capacity : int = 1 ) : hash-set-mut<v>
  Hash-set-mut( vector( if capacity > 0 then capacity else 1, Nil ), 0, seed )

// Creates a hash-set-mut from a list `xs`. This hash-set-mut has the same capacity as the length of the list `xs`.
pub fun list/hash-set-mut( xs : list<v>, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set-mut<v>
  from-list-helper( hash-set-mut( xs.length ), xs )

// Creates a hash-set-mut from a list `xs` and with a `seed`. This hash-set-mut has the same capacity as the length of the list `xs`.
pub fun list/hash-set-mut-seeded( xs : list<v>, seed : int64, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set-mut<v>
  from-list-helper( hash-set-mut-seeded( seed, capacity = xs.length ), xs )

fun from-list-helper( hs : hash-set-mut<v>, l : list<v>, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set-mut<v>
  match l
    Nil -> hs
    Cons(x, xs) -> 
      from-list-helper( hs.insert( x ), xs )


// Resizes a hash-set-mut with `new-capacity` being the new capacity of the hashset. 
// If `new-capacity` is smaller than the capacity of the hash-set-mut then there will be more hash collisions.
pub fun resize( hs : hash-set-mut<v>, new-capacity : int, ?hash : (v, int64) -> int ) : hash-set-mut<v>
  val buckets: vector<list<v>> = vector(hs.data.length, Nil)
  match hs
    Hash-set-mut(data, size, seed) ->
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
      val new-hs = Hash-set-mut( data = new-data, amount = size, seed = seed)
      
      new-hs.rehash( buckets, ?hash = hash )

pub fun rehash( hs : hash-set-mut<v>, buckets : vector<list<v>>, ?hash : (v, int64) -> int ) : hash-set-mut<v>
  buckets.foreach fn (bucket)
    bucket.foreach fn (entry)
      val the-hash = hash(entry, hs.seed)
      val position = the-hash % hs.data.length
      match hs.data.at( position )
        Nothing -> ()
        Just(xs) -> hs.data.unsafe-assign( position.ssize_t, Cons( entry, xs ) )
  hs

// Inserts a `value` into the hash-set-mut.
pub fun insert( hs : hash-set-mut<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool, ?when-resize : (int, int) -> bool, ?resizer : (int, int) -> int ) : hash-set-mut<v>
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  val new-hs = match hs
    Hash-set-mut(data, amount, seed) ->
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = Cons( value, data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x == value) )
      data.unsafe-assign( position.ssize_t, bucket )
      val new-amount = if old-bucket-size < data.unsafe-idx( position.ssize_t ).length then amount + 1 else amount
      Hash-set-mut(data, new-amount, seed)
  if when-resize( new-hs.data.length, new-hs.amount ) then
    new-hs.resize( resizer( new-hs.data.length, new-hs.amount ), ?hash = hash )
  else
    new-hs

// Removes a value from the hash-set-mut with a given `value`.
pub fun remove( hs : hash-set-mut<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : hash-set-mut<v>
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  match hs
    Hash-set-mut(data, amount, seed) -> 
      val bucket = data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x == value)
      data.unsafe-assign( position.ssize_t, bucket )
      Hash-set-mut( data, amount - 1, seed)

// Checks if a value is in the hash-set-mut `hs` and returns `True` if found and `False` if not found.
pub fun contains( hs : hash-set-mut<v>, value : v, ?hash : (v, int64) -> int, ?(==) : (v, v) -> bool ) : bool
  val the-hash = hash(value, hs.seed)
  val position = the-hash % hs.data.length
  match hs.data.unsafe-idx( position.ssize_t ).filter( _ == value )
    Cons(_, _) -> True
    Nil -> False

// Fetches the amount of items in the hash-set-mut
pub fun length( hs : hash-set-mut<v> ) : int
  hs.amount

// Removes all buckets from the hash-set-mut, effectively clearing the hash-set-mut.
pub fun clear( hs : hash-set-mut<v>) : hash-set-mut<v>
  match hs
    Hash-set-mut(data, _, seed) ->
      for( data.length ) fn (x) 
        data.drop-at( x.ssize_t )
        data.unsafe-assign(x.ssize_t, Nil)
      Hash-set-mut( data, 0, seed )

// Applies a function `f` to each key-value of the hash-set-mut via a tuple.
pub fun effect/map( hs : hash-set-mut<a>, f : (a) -> e b ) : e hash-set-mut<b>
  val new-data = hs.data.map fn (buckets)
    buckets.list/map(f)
  Hash-set-mut( new-data, hs.amount, hs.seed )

// Applies a function `f` to each key-value of the hash-set-mut via a tuple.
pub fun unique/map( hs : hash-set-mut<a>, f : (a) -> b ) : hash-set-mut<b>
  match hs
    Hash-set-mut(data, amount, seed) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map(f)
      Hash-set-mut( new-data, amount, seed )

// Invoke a function `f` for each key-value of the hash-set-mut.
pub fun foreach( hs : hash-set-mut<v>, f : (v) -> e () ) : e ()
  for( hs.data.length ) fn (i) 
    hs.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      f(entry)
