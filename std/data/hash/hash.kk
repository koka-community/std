/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// A module to provide hashing functionality
// The hash function used is xxhash64, while not cryptographically secure, it should be fast and avoid collisions.
module std/data/hash/hash
import std/num/int64
import std/test/test
import std/core-extras


extern import 
  c file "inline/hash"

pub inline extern int/hash( i : int, ?seed : int64 ) : int
  c "kk_integer_hash"


pub fun char/hash( c : char, ?seed : int64 ) : int
  c.int().int/hash( ?seed = seed )

pub fun bool/hash( b : bool, ?seed : int64 ) : int
  match b
    True -> int/hash(1)
    False -> int/hash(0)

pub inline extern string/hash( s : string, ?seed : int64 ) : int
  c "kk_string_hash"

pub fun list/hash( l : list<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  val vec = unsafe-vector( l.length.ssize_t )
  list-hash-helper( l, vec, 0, ?hasher = hasher, ?seed = seed )

  hash-vector( vec, seed )

inline fun list-hash-helper( l : list<a>, buf : vector<int64>, index : int, ?hasher : (a, int64) -> int, ?seed : int64 ) : ()
  match l
    Nil -> ()
    Cons(x, xs) -> 
      buf.unsafe-assign( index.ssize_t, hasher(x, seed).int64 )
      list-hash-helper( xs, buf, index + 1, ?hasher = hasher, ?seed = seed )

pub fun vector/hash( v : vector<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  val vec = unsafe-vector( v.length.ssize_t )
  for( v.length ) fn (i)
    vec.unsafe-assign( i.ssize_t, hasher( v.unsafe-idx( i.ssize_t ), seed ).int64 )
  
  hash-vector( vec, seed )

inline extern hash-vector( v : vector<int64>, seed : int64 ) : int
  c "kk_hash_vector"

pub fun maybe/hash( m : maybe<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  match m
    Nothing -> int/hash( 109043358147367465933604847619, ?seed = seed )
    Just(x) -> 
      val vec = unsafe-vector( 2.ssize_t )
      vec.unsafe-assign( 0.ssize_t, hasher(x, seed).int64 )
      vec.unsafe-assign( 1.ssize_t, 636221073298515699161266525619.int64 )
      hash-vector( vec, seed )

pub fun either/hash( e : either<l, r>, ?hasher-l : (l, int64) -> int, ?hasher-r : (r, int64) -> int, ?seed : int64 ) : int
  val hash-key = match e
    Left(l) -> (hasher-l( l, seed ), 979671666476914879931210933431)
    Right(r) -> (hasher-r( r, seed ), 214237100480734178309831475373)
  val (the-hash, prime) = hash-key
  val vec = unsafe-vector( 2.ssize_t )
  vec.unsafe-assign( 0.ssize_t, the-hash.int64 )
  vec.unsafe-assign( 1.ssize_t, prime.int64 )

  hash-vector( vec, seed )

fun test-hash()
  /*
  basic/test("vlist push")
    val vec = unit/vector-list() 
    val vec' = vec.push(2)
    val value = vec'.at(0)
    expect(Just(2), { value } , details="Expected Just(2) but got " ++ value.show)
  */
  val seed = 0.int64
  val hashed = list/hash([2, 2], ?hasher = int/hash, ?seed = seed)
  hashed.show.println
  hashed.int/hash( ?seed = seed ).show.println


