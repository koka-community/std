module std/data/hash/hash
import std/num/int64
import std/test/test

extern import 
  c file "inline/hash"

pub inline extern int/hash( i : int, ?seed : int64 ) : int
  c "kk_integer_hash"


pub fun char/hash( c : char, ?seed : int64 ) : int
  c.int().int/hash( ?seed = seed )

pub fun bool/hash( b : bool, ?seed : int64 ) : int
  match b
    True -> int/hash(3)
    False -> int/hash(2)

pub fun string/hash( s : string ) : int
  var m : int := 1000000000 + 9
  var p_pow : int := 1
  s.list().foldl(0) fn (hash-value : int, c : char)
    val value = (hash-value + (c.int() + 1) * p_pow) % m
    p_pow := (p_pow * 31) % m
    value
  


pub fun maybe/hash( m : maybe<a>, ?hasher : (a, int64) -> int, ?seed : int64 ) : int
  match m
    Nothing -> 0
    Just(x) -> hasher(x, seed)

pub fun either/hash( e : either<l, r>, ?hasher-l : (l, int64) -> int, ?hasher-r : (r, int64) -> int, ?seed : int64 ) : int
  match e
    Left(l) -> hasher-l( l, seed ) * 2
    Right(r) -> hasher-r( r, seed ) * 3



fun test-hash()
  /*
  basic/test("vlist push")
    val vec = unit/vector-list() 
    val vec' = vec.push(2)
    val value = vec'.at(0)
    expect(Just(2), { value } , details="Expected Just(2) but got " ++ value.show)
  */
  val seed = 0.int64
  val hashed = int/hash(0, ?seed = seed)
  hashed.show.println
  hashed.int/hash( ?seed = seed ).show.println


