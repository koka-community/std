/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// A module to provide hashing functionality
module std/data/hash/hash
import std/num/int64
import std/test/test
import std/core-extras

/*
  Primes used for noise:
  2: either left
  3: either right
  5: maybe just
  7: list
  11: vector
*/

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

  hash-vector( vec, seed ) + 7

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
  
  hash-vector( vec, seed ) + 11

inline extern hash-vector( v : vector<int64>, seed : int64 ) : int
  c "kk_hash_vector"

pub fun maybe/hash( m : maybe<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  match m
    Nothing -> 0
    Just(x) -> hasher(x, seed) + 5

pub fun either/hash( e : either<l, r>, ?hasher-l : (l, int64) -> int, ?hasher-r : (r, int64) -> int, ?seed : int64 ) : int
  match e
    Left(l) -> hasher-l( l, seed ) + 2
    Right(r) -> hasher-r( r, seed ) + 3



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


