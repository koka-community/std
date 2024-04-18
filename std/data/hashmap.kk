/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a bucket hashmap 
module std/data/hashmap
import std/core-extras
import std/test
import std/num/int64
import std/num/random
import std/data/hash


pub value struct hash-map<k, v>
  data : vector<list<(k,v)>>
  amount : int
  seed : int64

// Creates a hash-map with a specified inital `capacity`.
// If zero then the hash-map will set capacity to 1.
// Random effect is needed to initalize the seed.
pub fun hash-map( capacity : int = 1 ) : random hash-map<k, v>
  Hash-map( vector( if capacity > 0 then capacity else 1, Nil ), 0, random-int64() )

// Creates a hash-map with a specified inital `capacity` and a user defined `seed`.
// If zero then the hash-map will set capacity to 1.
pub fun hash-map-seeded( seed : int64, capacity : int = 1 ) : hash-map<k, v>
  Hash-map( vector( if capacity > 0 then capacity else 1, Nil ), 0, seed )

// Creates a hash-map from a list `xs`. This hash-map has the same capacity as the length of the list `xs`.
// Random effect is needed to initalize the seed.
pub fun list/hash-map( xs : list<(k, v)>, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : random hash-map<k, v>
  from-list-helper( hash-map( xs.length ), xs )

// Creates a hash-map from a list `xs` and with a `seed`. This hash-map has the same capacity as the length of the list `xs`.
pub fun list/hash-map-seeded( xs : list<(k, v)>, seed : int64, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : hash-map<k, v>
  from-list-helper( hash-map-seeded( seed, capacity = xs.length ), xs )

fun from-list-helper( hm : hash-map<k, v>, l : list<(k, v)>, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : hash-map<k, v>
  match l
    Nil -> hm
    Cons((key, value), xs) -> 
      from-list-helper( hm.insert( key, value ), xs )


// Resizes a hash-map with `new-capacity` being the new capacity of the hashmap. 
// If `new-capacity` is smaller than the capacity of the hash-map then there will be more hash collisions.
pub fun resize( hm : hash-map<k, v>, new-capacity : int, ?hash : (k, int64) -> int ) : hash-map<k, v>
  val buckets: vector<list<(k, v)>> = vector(hm.data.length, Nil)
  match hm
    Hash-map(data, size, seed) ->
      for( data.length ) fn (i)
        match data.at(i)
          Nothing -> ()
          Just(x) -> 
            buckets.drop-at( i.ssize_t )
            buckets.unsafe-assign( i.ssize_t, x )

            //data.drop-at( i.ssize_t )
      val new-data = realloc(data, new-capacity.ssize_t)
      //val new-hm = Hash-map( data = helper/resize( new-data ), amount = size, seed = seed)

      Hash-map( data = helper/resize( new-data ).rehash( buckets, seed ), amount = size, seed = seed )

// This helper function either clears out a vector if it is unique or creates a new vector if it isn't unique.
fun helper/resize( v : vector<list<(k, v)>> ) : vector<list<(k, v)>>
  if v.is-vec-unique then
    //trace("helper/resize: vector is unique")
    for( v.length ) fn (i)
      v.drop-at( i.ssize_t )
      v.unsafe-assign( i.ssize_t, Nil )
    v
  else
    //trace("helper/resize: vector isn't unique")
    vector( v.length, Nil)

// Rehash will overwrite vector `v` with values from `buckets` if it is unique, otherwise it will use `unsafe-set`
fun rehash( v : vector<list<(k,v)>>, buckets : vector<list<(k,v)>>, seed : int64, ?hash : (k, int64) -> int ) : vector<list<(k,v)>>
  if v.is-vec-unique then
    buckets.foreach fn (bucket)
      bucket.foreach fn (entry)
        val (key, _) = entry
        val the-hash = hash(key, seed)
        val position = the-hash % v.length
        match v.at( position )
          Nothing -> ()
          Just(xs) -> v.unsafe-assign( position.ssize_t, Cons( entry, xs ) )
    v
  else
    //trace("unlikely")
    val bkts = buckets.vector/list.flatmap fn (x) x
    helper/rehash( v, bkts, seed )

// This helper will use `buckets` to allow for a `div`-less use of `unsafe-set` to set values in vector `v`.
fun helper/rehash( v : vector<list<(k, v)>>, buckets : list<(k, v)>, seed : int64, ?hash : (k, int64) -> int ) : vector<list<(k, v)>>
  match buckets
    Nil -> v
    Cons((key, value), xs) ->
      val the-hash = hash(key, seed)
      val position = the-hash % v.length
      val new-v = v.unsafe-set( position, Cons( (key, value), v.unsafe-idx( position.ssize_t ) ) )
      helper/rehash( new-v, xs, seed )

// Internal function that dictates when to resize the hash-map. This can be overridden with implicits.
fun when-resize( table-size : int, item-count : int ) : bool
  if 2 * table-size <= item-count then
    True
  else
    False

// Internal function that determines the new size of a hash-map when inserting. This can be overridden with implicits.
fun resizer( table-size : int, item-count : int ) : int
   item-count * 2

// Inserts a `value` into the hash-map with a given `key`.
pub fun insert( hm : hash-map<k,v>, key : k, value : v, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool, ?when-resize : (int, int) -> bool, ?resizer : (int, int) -> int ) : hash-map<k, v>
  val the-hash = hash(key, hm.seed)
  val position = the-hash % hm.data.length
  val new-hm = match hm
    Hash-map(data, amount, seed) ->
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = Cons( (key, value), data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x.fst == key) )
      val new-data = data.unsafe-set( position, bucket )
      val new-amount = if old-bucket-size < new-data.unsafe-idx( position.ssize_t ).length then amount + 1 else amount
      Hash-map( new-data, new-amount, seed )
  if when-resize( new-hm.data.length, new-hm.amount ) then
    new-hm.resize( resizer( new-hm.data.length, new-hm.amount ) )
  else
    new-hm

// Removes a value from the hash-map with a given `key`.
pub fun remove( hm : hash-map<k,v>, key : k, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : hash-map<k, v>
  val the-hash = hash(key, hm.seed)
  val position = the-hash % hm.data.length
  match hm
    Hash-map(data, amount, seed) -> 
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x.fst == key)
      val new-data = data.unsafe-set( position, bucket )
      val new-amount = if old-bucket-size > new-data.unsafe-idx( position.ssize_t ).length then amount - 1 else amount
      Hash-map( new-data, new-amount, seed)

// Attempts to retreve a value from the hash-map with a given `key`. Returns `Nothing` if the key is invalid.
pub fun get( hm : hash-map<k, v>, key : k, ?hash : (k, int64) -> int, ?(==) : (k, k) -> bool ) : maybe<v>
  val the-hash = hash(key, hm.seed)
  val position = the-hash % hm.data.length
  match hm.data.unsafe-idx( position.ssize_t ).filter( fn(x) x.fst == key )
    Cons(x, _) -> Just(x.snd)
    Nil -> Nothing

// Fetches the amount of items in the hash-map
pub fun length( hm : hash-map<k, v> ) : int
  hm.amount

// Removes all buckets from the hash-map, effectively clearing the hash-map.
pub fun clear( hm : hash-map<k, v>) : hash-map<k, v>
  match hm
    Hash-map(data, _, seed) ->
      if data.is-vec-unique then
        for( data.length ) fn (x) 
          data.drop-at( x.ssize_t )
          data.unsafe-assign(x.ssize_t, Nil)
        Hash-map( data, 0, seed )
      else
        Hash-map( vector( data.length, Nil ), 0, seed )

// Applies a function `f` to each value of the hash-map.
pub fun effect/map-values( hm : hash-map<k, a>, f : (a) -> e b ) : e hash-map<k, b>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map fn (entry)
      val (key, value) = entry
      (key, f( value ))
  Hash-map( new-data, hm.amount, hm.seed )

// Applies a function `f` to each value of the hash-map.
pub fun unique/map-values( hm : hash-map<k, a>, f : (a) -> b ) : hash-map<k, b>
  match hm
    Hash-map(data, amount, seed) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map fn (entry)
          val (key, value) = entry
          (key, f( value ))
      Hash-map( new-data, amount, seed )

// Applies a function `f` to each key of the hash-map.
pub fun effect/map-keys( hm : hash-map<a, v>, f : (a) -> e b ) : e hash-map<b, v>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map fn (entry)
      val (key, value) = entry
      (f( key ), value)
  Hash-map( new-data, hm.amount, hm.seed )

// Applies a function `f` to each key of the hash-map.
pub fun unique/map-keys( hm : hash-map<a, v>, f : (a) -> b ) : hash-map<b, v>
  match hm
    Hash-map(data, amount) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map fn (entry)
          val (key, value) = entry
          (f( key ), value)
      Hash-map( new-data, amount, hm.seed )

// Applies a function `f` to each key-value of the hash-map via a tuple.
pub fun effect/map( hm : hash-map<a, b>, f : ((a, b)) -> e (c, d) ) : e hash-map<c, d>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map(f)
  Hash-map( new-data, hm.amount, hm.seed )

// Applies a function `f` to each key-value of the hash-map via a tuple.
pub fun unique/map( hm : hash-map<a, b>, f : ((a, b)) -> (c, d) ) : hash-map<c, d>
  match hm
    Hash-map(data, amount) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map(f)
      Hash-map( new-data, amount, hm.seed )

// Invoke a function `f` for each key-value of the hash-map.
pub fun foreach( hm : hash-map<k, v>, f : (k, v) -> e () ) : e ()
  for( hm.data.length ) fn (i) 
    hm.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      val (key, value) = entry
      f(key, value)

// Invoke a function `f` for each key of the hash-map.
pub fun foreach-key( hm : hash-map<k, v>, f : (k) -> e () ) : e ()
  for( hm.data.length ) fn (i) 
    hm.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      val (key, _) = entry
      f(key)

// Invoke a function `f` for each value of the hash-map.
pub fun foreach-value( hm : hash-map<k, v>, f : (v) -> e () ) : e ()
  for( hm.data.length ) fn (i) 
    hm.data.unsafe-idx( i.ssize_t ).foreach fn (entry)
      val (_, value) = entry
      f(value)


fun test-hash-map()
  basic/test("hash-map insert")
    val hm = hash-map(1)
    val hm' = hm.insert(1, 2, ?hash = int/hash )
    val value = hm'.get(1, ?hash = int/hash)
    expect(Just(2), { value } , details="Expected Just(2) but got " ++ value.show)
  basic/test("hash-map remove")
    val hm = hash-map(1)
    val hm' = hm.insert(1, 2, ?hash = int/hash )
    val hm@ = hm'.remove(1, ?hash = int/hash )
    expect(0, { hm@.length } , details="Expected 0 but got " ++ hm@.length.show)
  basic/test("hash-map overwrite")
    val hm = hash-map(1)
    val hm' = hm.insert(1, 2, ?hash = int/hash )
    val hm@ = hm'.insert(1, 3, ?hash = int/hash )
    val value = hm@.get(1, ?hash = int/hash)
    expect(Just(3), { value } , details="Expected Just(3) but got " ++ value.show)
  basic/test("hash-map stress test")
    var hm := hash-map(1)
    for(50000) fn (i)
      hm := hm.insert(i, i, ?hash = int/hash )
    expect(True, { True } , details="Expected Resizing to work")
  basic/test("hash-map clear")
    var hm := hash-map(1)
    for(50) fn (i)
      hm := hm.insert(i, i, ?hash = int/hash )
    hm := hm.clear()
    val value = hm.length()
    expect(0, { value } , details="Expected 0 but got " ++ value.show)
  basic/test("hash-map clear then fill")
    var hm := hash-map(1)
    for(50) fn (i)
      hm := hm.insert(i, i, ?hash = int/hash )
    hm := hm.clear()
    for(50) fn (i)
      hm := hm.insert(i, i, ?hash = int/hash )
    val value = hm.length()
    expect(50, { value } , details="Expected 0 but got " ++ value.show)
    
fun main()
  test-hash-map()