/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a bucket hashmap 
module std/data/mutable/hashmap-mut
import std/core-extras
import std/test
import std/num/int64
import std/num/random
import std/data/hash


pub value struct hash-map-mut<k, v>
  data : vector<list<(k,v)>>
  amount : int
  seed : int64

// Creates a hash-map-mut with a specified inital `capacity`.
// If zero then the hash-map-mut will set capacity to 1.
// Random effect is needed to initalize the seed.
pub fun random/hash-map-mut( capacity : int = 1 ) : random hash-map-mut<k, v>
  Hash-map-mut( vector( if capacity > 0 then capacity else 1, Nil ), 0, random-int64() )

// Creates a hash-map-mut with a specified inital `capacity`.
// If zero then the hash-map-mut will set capacity to 1.
// The seed is initalized using the thread's id.
pub fun thread/hash-map-mut( capacity : int = 1 ) : hash-map-mut<k, v>
  Hash-map-mut( vector( if capacity > 0 then capacity else 1, Nil ), 0, seed )

// Creates a hash-map-mut with a specified inital `capacity` and a user defined `seed`.
// If zero then the hash-map-mut will set capacity to 1.
pub fun random/hash-map-mut-seeded( seed : int64, capacity : int = 1 ) : hash-map-mut<k, v>
  Hash-map-mut( vector( if capacity > 0 then capacity else 1, Nil ), 0, seed )

// Creates a hash-map-mut from a list `xs`. This hash-map-mut has the same capacity as the length of the list `xs`.
// Random effect is needed to initalize the seed.
pub fun random/list/hash-map-mut( xs : list<(k, v)>, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : random hash-map-mut<k, v>
  from-list-helper( random/hash-map-mut( xs.length ), xs )

// Creates a hash-map from a list `xs`. This hash-map-mut has the same capacity as the length of the list `xs`.
// The seed is initalized from the thread's id.
pub fun thread/list/hash-map-mut( xs : list<(k, v)>, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : hash-map-mut<k, v>
  from-list-helper( thread/hash-map-mut( xs.length ), xs )

// Creates a hash-map-mut from a list `xs` and with a `seed`. This hash-map-mut has the same capacity as the length of the list `xs`.
pub fun list/hash-map-mut-seeded( xs : list<(k, v)>, seed : int64, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : hash-map-mut<k, v>
  from-list-helper( hash-map-mut-seeded( seed, capacity = xs.length ), xs )

fun from-list-helper( hm : hash-map-mut<k, v>, l : list<(k, v)>, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : hash-map-mut<k, v>
  match l
    Nil -> hm
    Cons((key, value), xs) -> 
      from-list-helper( hm.insert( key, value ), xs )


// Resizes a hash-map-mut with `new-capacity` being the new capacity of the hashmap. 
// If `new-capacity` is smaller than the capacity of the hash-map-mut then there will be more hash collisions.
pub fun resize( hm : hash-map-mut<k, v>, new-capacity : int, ?hash : (k, int64) -> int ) : hash-map-mut<k, v>
  val buckets: vector<list<(k, v)>> = vector(hm.data.length, Nil)
  match hm
    Hash-map-mut(data, size, seed) ->
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
      val new-hm = Hash-map-mut( data = new-data, amount = size, seed = seed)
      
      new-hm.rehash( buckets, ?hash = hash )

pub fun rehash( hm : hash-map-mut<k, v>, buckets : vector<list<(k,v)>>, ?hash : (k, int64) -> int ) : hash-map-mut<k, v>
  buckets.foreach fn (bucket)
    bucket.foreach fn (entry)
      val (key, _) = entry
      val the-hash = hash(key, hm.seed)
      val position = the-hash % hm.data.length
      match hm.data.at( position )
        Nothing -> ()
        Just(xs) -> hm.data.unsafe-assign( position.ssize_t, Cons( entry, xs ) )
  hm

// Internal function that dictates when to resize the hash-map-mut. This can be overridden with implicits.
pub fun when-resize( table-size : int, item-count : int ) : bool
  if 2 * table-size <= item-count then
    True
  else
    False

// Internal function that determines the new size of a hash-map-mut when inserting. This can be overridden with implicits.
pub fun resizer( table-size : int, item-count : int ) : int
   item-count * 2

// Inserts a `value` into the hash-map-mut with a given `key`.
pub fun insert( hm : hash-map-mut<k,v>, key : k, value : v, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool, ?when-resize : (int, int) -> bool, ?resizer : (int, int) -> int ) : hash-map-mut<k, v>
  val the-hash = hash(key, hm.seed)
  val position = the-hash % hm.data.length
  val new-hm = match hm
    Hash-map-mut(data, amount, seed) ->
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = Cons( (key, value), data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x.fst == key) )
      data.unsafe-assign( position.ssize_t, bucket )
      val new-amount = if old-bucket-size < data.unsafe-idx( position.ssize_t ).length then amount + 1 else amount
      Hash-map-mut(data, new-amount, seed)
  if when-resize( new-hm.data.length, new-hm.amount ) then
    new-hm.resize( resizer( new-hm.data.length, new-hm.amount ), ?hash = hash )
  else
    new-hm

// Removes a value from the hash-map-mut with a given `key`.
pub fun remove( hm : hash-map-mut<k,v>, key : k, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : hash-map-mut<k, v>
  val the-hash = hash(key, hm.seed)
  val position = the-hash % hm.data.length
  match hm
    Hash-map-mut(data, amount, seed) -> 
      val bucket = data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x.fst == key)
      data.unsafe-assign( position.ssize_t, bucket )
      Hash-map-mut( data, amount - 1, seed)

// Attempts to retreve a value from the hash-map-mut with a given `key`. Returns `Nothing` if the key is invalid.
pub fun get( hm : hash-map-mut<k, v>, key : k, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : maybe<v>
  val the-hash = hash(key, hm.seed)
  val position = the-hash % hm.data.length
  match hm.data.unsafe-idx( position.ssize_t ).filter( fn(x) x.fst == key )
    Cons(x, _) -> Just(x.snd)
    Nil -> Nothing

// Fetches the amount of items in the hash-map-mut
pub fun length( hm : hash-map-mut<k, v> ) : int
  hm.amount

// Removes all buckets from the hash-map-mut, effectively clearing the hash-map-mut.
pub fun clear( hm : hash-map-mut<k, v>) : hash-map-mut<k, v>
  match hm
    Hash-map-mut(data, _, seed) ->
      for( data.length ) fn (x) 
        data.drop-at( x.ssize_t )
        data.unsafe-assign(x.ssize_t, Nil)
      Hash-map-mut( data, 0, seed )

// Applies a function `f` to each value of the hash-map-mut.
pub fun effect/map-values( hm : hash-map-mut<k, a>, f : (a) -> e b ) : e hash-map-mut<k, b>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map fn (entry)
      val (key, value) = entry
      (key, f( value ))
  Hash-map-mut( new-data, hm.amount, hm.seed )

// Applies a function `f` to each value of the hash-map-mut.
pub fun unique/map-values( hm : hash-map-mut<k, a>, f : (a) -> b ) : hash-map-mut<k, b>
  match hm
    Hash-map-mut(data, amount, seed) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map fn (entry)
          val (key, value) = entry
          (key, f( value ))
      Hash-map-mut( new-data, amount, seed )

// Applies a function `f` to each key of the hash-map-mut.
pub fun effect/map-keys( hm : hash-map-mut<a, v>, f : (a) -> e b ) : e hash-map-mut<b, v>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map fn (entry)
      val (key, value) = entry
      (f( key ), value)
  Hash-map-mut( new-data, hm.amount, hm.seed )

// Applies a function `f` to each key of the hash-map-mut.
pub fun unique/map-keys( hm : hash-map-mut<a, v>, f : (a) -> b ) : hash-map-mut<b, v>
  match hm
    Hash-map-mut(data, amount) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map fn (entry)
          val (key, value) = entry
          (f( key ), value)
      Hash-map-mut( new-data, amount, hm.seed )

// Applies a function `f` to each key-value of the hash-map-mut via a tuple.
pub fun effect/map( hm : hash-map-mut<a, b>, f : ((a, b)) -> e (c, d) ) : e hash-map-mut<c, d>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map(f)
  Hash-map-mut( new-data, hm.amount, hm.seed )

// Applies a function `f` to each key-value of the hash-map-mut via a tuple.
pub fun unique/map( hm : hash-map-mut<a, b>, f : ((a, b)) -> (c, d) ) : hash-map-mut<c, d>
  match hm
    Hash-map-mut(data, amount) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map(f)
      Hash-map-mut( new-data, amount, hm.seed )

// Invoke a function `f` for each key-value of the hash-map-mut.
pub fun foreach( hm : hash-map-mut<k, v>, f : (k, v) -> e () ) : e ()
  for( hm.data.length ) fn (i) 
    hm.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      val (key, value) = entry
      f(key, value)

// Invoke a function `f` for each key of the hash-map-mut.
pub fun foreach-key( hm : hash-map-mut<k, v>, f : (k) -> e () ) : e ()
  for( hm.data.length ) fn (i) 
    hm.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      val (key, _) = entry
      f(key)

// Invoke a function `f` for each value of the hash-map-mut.
pub fun foreach-value( hm : hash-map-mut<k, v>, f : (v) -> e () ) : e ()
  for( hm.data.length ) fn (i) 
    hm.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      val (_, value) = entry
      f(value)



fun test-hash-map-mut()
  group("hash-map-mut")
    test("insert")
      val hm = random/hash-map-mut(1)
      expect(2)
        val hm' = hm.insert(1, 2)
        hm'.get(1).unjust
    test("remove")
      val hm = random/hash-map-mut(1)
      val hm' = hm.insert(1, 2)
      expect(0)
        hm'.remove(1).length
    test("overwrite")
      val hm = random/hash-map-mut(1)
      val hm' = hm.insert(1, 2)
      expect(3)
        val hm@ = hm'.insert(1, 3)
        hm@.get(1).unjust
    test("stress test")
      var hm := random/hash-map-mut(1)
      expect(True)
        for(50000) fn (i)
          hm := hm.insert(i, i)
        True
    test("clear")
      var hm := random/hash-map-mut(1)
      for(50) fn (i)
        hm := hm.insert(i, i)
      expect(0)
        hm := hm.clear()
        hm.length
    test("clear then fill")
      var hm := random/hash-map-mut(1)
      for(50) fn (i)
        hm := hm.insert(i, i)
      expect(50)
        hm := hm.clear()
        for(50) fn (i)
          hm := hm.insert(i, i)
        hm.length
