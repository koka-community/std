/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// This module provides a bucket hashmap 
module std/data/hash/hashmap
import std/core-extras
import std/test

pub value struct hash-map<k, v>
  data : vector<list<(k,v)>>
  amount : int

// Creates a hash-map with a specified inital `capacity`.
// If zero then the hash-map will set capacity to 1.
pub fun hash-map( capacity : int ) : hash-map<k, v>
  Hash-map( vector( if capacity > 0 then capacity else 1, Nil ), 0 )

// Creates a hash-map from a list `xs`. This hash-map has the same capacity as the length of the list `xs`.
pub fun hash-map-from-list( xs : list<(k, v)>, ?hash : (k) -> int, ?(==) : (k, k) -> bool ) : hash-map<k, v>
  from-list-helper( hash-map( xs.length ), xs, ?hash = hash, ?(==) = (==) )

fun from-list-helper( hm : hash-map<k, v>, l : list<(k, v)>, ?hash : (k) -> int, ?(==) : (k, k) -> bool ) : hash-map<k, v>
  match l
    Nil -> hm
    Cons(x, xs) -> 
      val (key, value) = x
      from-list-helper( hm.insert( key, value, ?hash = hash, ?(==) = (==) ), xs, ?hash = hash, ?(==) = (==) )


// Resizes a hash-map with `new-capacity` being the new capacity of the hashmap. 
// If `new-capacity` is smaller than the capacity of the hash-map then there will be more hash collisions.
pub fun resize( hm : hash-map<k, v>, new-capacity : int, ?hash : (k) -> int ) : hash-map<k, v>
  val buckets: vector<list<(k, v)>> = vector(hm.data.length, Nil)
  match hm
    Hash-map(data, size) ->
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
      val new-hm = Hash-map( data = new-data, amount = size)
      
      new-hm.rehash( buckets, ?hash = hash )

fun rehash( hm : hash-map<k, v>, buckets : vector<list<(k,v)>>, ?hash : (k) -> int ) : hash-map<k, v>
  buckets.foreach fn (bucket)
    bucket.foreach fn (entry)
      val (key, _) = entry
      val the-hash = hash(key)
      val position = the-hash % hm.data.length
      match hm.data.at( position )
        Nothing -> ()
        Just(xs) -> hm.data.unsafe-assign( position.ssize_t, Cons( entry, xs ) )
  hm

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
pub fun insert( hm : hash-map<k,v>, key : k, value : v, ?hash : (k) -> int, ?(==) : (k, k) -> bool, ?when-resize : (int, int) -> bool, ?resizer : (int, int) -> int ) : hash-map<k, v>
  val the-hash = hash(key)
  val position = the-hash % hm.data.length
  val new-hm = match hm
    Hash-map(data, amount) ->
      val old-bucket-size = data.unsafe-idx( position.ssize_t ).length
      val bucket = Cons( (key, value), data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x.fst == key) )
      data.unsafe-assign( position.ssize_t, bucket )
      val new-amount = if old-bucket-size < data.unsafe-idx( position.ssize_t ).length then amount + 1 else amount
      Hash-map(data, new-amount)
  if when-resize( new-hm.data.length, new-hm.amount ) then
    new-hm.resize( resizer( new-hm.data.length, new-hm.amount ), ?hash = hash )
  else
    new-hm

// Removes a value from the hash-map with a given `key`.
pub fun remove( hm : hash-map<k,v>, key : k, ?hash : (k) -> int, ?(==) : (k, k) -> bool ) : hash-map<k, v>
  val the-hash = hash(key)
  val position = the-hash % hm.data.length
  match hm
    Hash-map(data, amount) -> 
      val bucket = data.unsafe-idx( position.ssize_t ).filter() fn(x) not(x.fst == key)
      data.unsafe-assign( position.ssize_t, bucket )
      Hash-map( data, amount - 1)

// Attempts to retreve a value from the hash-map with a given `key`. Returns `Nothing` if the key is invalid.
pub fun get( hm : hash-map<k, v>, key : k, ?hash : (k) -> int, ?(==) : (k, k) -> bool ) : maybe<v>
  val the-hash = hash(key)
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
    Hash-map(data, _) ->
      for( data.length ) fn (x) 
        data.drop-at( x.ssize_t )
        data.unsafe-assign(x.ssize_t, Nil)
      Hash-map( data, 0 )

// Applies a function `f` to each value of the hash-map.
pub fun effect/map-values( hm : hash-map<k, a>, f : (a) -> e b ) : e hash-map<k, b>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map fn (entry)
      val (key, value) = entry
      (key, f( value ))
  Hash-map( new-data, hm.amount )

// Applies a function `f` to each value of the hash-map.
pub fun unique/map-values( hm : hash-map<k, a>, f : (a) -> b ) : hash-map<k, b>
  match hm
    Hash-map(data, amount) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map fn (entry)
          val (key, value) = entry
          (key, f( value ))
      Hash-map( new-data, amount )

// Applies a function `f` to each key of the hash-map.
pub fun effect/map-keys( hm : hash-map<a, v>, f : (a) -> e b ) : e hash-map<b, v>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map fn (entry)
      val (key, value) = entry
      (f( key ), value)
  Hash-map( new-data, hm.amount )

// Applies a function `f` to each key of the hash-map.
pub fun unique/map-keys( hm : hash-map<a, v>, f : (a) -> b ) : hash-map<b, v>
  match hm
    Hash-map(data, amount) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map fn (entry)
          val (key, value) = entry
          (f( key ), value)
      Hash-map( new-data, amount )

// Applies a function `f` to each key-value of the hash-map via a tuple.
pub fun effect/map( hm : hash-map<a, b>, f : ((a, b)) -> e (c, d) ) : e hash-map<c, d>
  val new-data = hm.data.map fn (buckets)
    buckets.list/map(f)
  Hash-map( new-data, hm.amount )

// Applies a function `f` to each key-value of the hash-map via a tuple.
pub fun unique/map( hm : hash-map<a, b>, f : ((a, b)) -> (c, d) ) : hash-map<c, d>
  match hm
    Hash-map(data, amount) -> 
      val new-data = data.unique/map fn (bucket)
        bucket.map(f)
      Hash-map( new-data, amount )

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
    val hm' = hm.insert(1, 2, ?hash = fn (x) x * 2654435761 % (2 ^ 32) )
    val value = hm'.get(1, ?hash = fn (x) x * 2654435761 % (2 ^ 32))
    expect(Just(2), { value } , details="Expected Just(2) but got " ++ value.show)
  basic/test("hash-map remove")
    val hm = hash-map(1)
    val hm' = hm.insert(1, 2, ?hash = fn (x) x * 2654435761 % (2 ^ 32) )
    val hm@ = hm'.remove(1, ?hash = fn (x) x * 2654435761 % (2 ^ 32) )
    expect(0, { hm@.length } , details="Expected 0 but got " ++ hm@.length.show)
  basic/test("hash-map overwrite")
    val hm = hash-map(1)
    val hm' = hm.insert(1, 2, ?hash = fn (x) x * 2654435761 % (2 ^ 32) )
    val hm@ = hm'.insert(1, 3, ?hash = fn (x) x * 2654435761 % (2 ^ 32) )
    val value = hm@.get(1, ?hash = fn (x) x * 2654435761 % (2 ^ 32))
    expect(Just(3), { value } , details="Expected Just(3) but got " ++ value.show)
  basic/test("hash-map stress test")
    var hm := hash-map(1)
    for(50000) fn (i)
      hm := hm.insert(i, i, ?hash = fn (x) x * 2654435761 % (2 ^ 32) )
    expect(True, { True } , details="Expected Resizing to work")
  basic/test("hash-map clear")
    var hm := hash-map(1)
    for(50) fn (i)
      hm := hm.insert(i, i, ?hash = fn (x) x * 2654435761 % (2 ^ 32) )
    hm := hm.clear()
    val value = hm.length()
    expect(0, { value } , details="Expected 0 but got " ++ value.show)