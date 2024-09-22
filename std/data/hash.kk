/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// A module to provide hashing functionality
// The hash function used is xxhash64, while not cryptographically secure, it should be fast and avoid collisions.
module std/data/hash
import std/num/int64
import std/test/test
import std/core-extras

extern import 
  c file "inline/hash"

pub inline extern thread/get-seed() : int64
  c "kk_thread_seed"

// A hashing function for integers. It takes an int `i` and an implicit `seed` which is is an `int64`.
// Note: Big Ints may not work as expected.
pub inline extern extern-int-hash( i : int, seed : int64 ) : int
  c "kk_integer_hash"

pub val thread/seed: int64 = thread/get-seed()

pub fun int/hash(i: int, ?seed: int64): int
  extern-int-hash(i, ?seed)

// A hashing function for characters. It takes a char `c` and an implicit `seed` which is is an `int64`.
pub fun char/hash( c : char, ?seed : int64 ) : int
  c.int.hash()

// A hashing function for booleans. It takes a bool `b` and an implicit `seed` which is is an `int64`.
pub fun bool/hash( b : bool, ?seed : int64 ) : int
  match b
    True -> hash(1)
    False -> hash(0)

// A hashing function for strings. It takes a string `s` and an implicit `seed` which is is an `int64`.
pub inline extern string/hash( s : string, ?seed : int64 ) : int
  c "kk_string_hash"

// A hashing function for lists. It takes a list `l`, an implicit `hasher` for hashing each element, and an implicit `seed` which is is an `int64`.
// Note: Currently a vector and list with the same elements will have the same hash.
pub fun list/hash( l : list<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  val vec = unsafe-vector( l.length.ssize_t )
  list-hash-helper( l, vec, 0 )

  hash-vector-int64( vec, ?seed )

inline fun list-hash-helper( l : list<a>, buf : vector<int64>, index : int, ?hasher : (a, int64) -> int, ?seed : int64 ) : ()
  match l
    Nil -> ()
    Cons(x, xs) -> 
      buf.unsafe-assign( index.ssize_t, hasher(x, ?seed).int64 )
      list-hash-helper( xs, buf, index + 1 )

// A hashing function for vectors. It takes a vector `l`, an implicit `hasher` for hashing each element, and an implicit `seed` which is is an `int64`.
// Note: Currently a vector and list with the same elements will have the same hash.
pub fun vector/hash( v : vector<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  val vec = unsafe-vector( v.length.ssize_t )
  for( v.length ) fn (i)
    vec.unsafe-assign( i.ssize_t, hasher( v.unsafe-idx( i.ssize_t ), ?seed ).int64 )
  
  hash-vector-int64( vec, ?seed )

// Helper function for hashing vectors of int64
inline extern hash-vector-int64( v : vector<int64>, seed : int64 ) : int
  c "kk_hash_vector_int64"


// A hashing function for maybes. It takes a maybe `m`, an implicit `hasher` for `Just(a)`, and an implicit `seed` which is is an `int64`.
pub fun maybe/hash( m : maybe<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  match m
    Nothing -> int/hash( 109043358147367465933604847619)
    Just(x) -> 
      val vec = unsafe-vector( 2.ssize_t )
      vec.unsafe-assign( 0.ssize_t, hasher(x, ?seed).int64 )
      vec.unsafe-assign( 1.ssize_t, 636221073298515699161266525619.int64 )
      hash-vector-int64( vec, ?seed )


// A hashing function for eithers. It takes an either `e`, 2 implicit `hasher`s for hashing `Left` and `Right`, and an implicit `seed` which is is an `int64`.
pub fun either/hash( e : either<l, r>, ?l/hasher : (l, int64) -> int, ?r/hasher : (r, int64) -> int, ?seed : int64 ) : int
  val hash-key = match e
    Left(l) -> (hasher( l, ?seed ), 979671666476914879931210933431)
    Right(r) -> (hasher( r, ?seed ), 214237100480734178309831475373)
  val (the-hash, prime) = hash-key
  val vec = unsafe-vector( 2.ssize_t )
  vec.unsafe-assign( 0.ssize_t, the-hash.int64 )
  vec.unsafe-assign( 1.ssize_t, prime.int64 )
  hash-vector-int64( vec, ?seed )


fun test-hash()
  seed.println