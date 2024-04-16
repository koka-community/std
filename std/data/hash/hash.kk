module std/data/hash/hash

// Simple hash function for integers using Knuth's multiplicative method.
// This should be changed to something more optimal.
pub fun hash( x : int ) : int
  x * 2654435761 % (2 ^ 32)

pub fun hash( c : char ) : int
  c.int().hash()

pub fun hash( b : bool ) : int
  match b
    True -> 3
    False -> 2

pub fun hash( s : string ) : int
  var m : int := 1000000000 + 9
  var p_pow : int := 1
  str.list().foldl(0) fn (hash-value : int, c : char)
    val value = (hash-value + (c.int() + 1) * p_pow) % m
    p_pow := (p_pow * 31) % m
    value
  
pub fun hash( l : list<a>, ?hasher : (a) -> int ) : int
  var m : int := 1000000000 + 9
  var p_pow : int := 1
  l.foldl(0) fn (hash-value : int, c : a)
    val value = (hash-value + (c.hasher + 1) * p_pow) % m
    p_pow := (p_pow * 31) % m
    value

pub fun hash( v : vector<a>, ?hasher : (a) -> int ) : int
  var m : int := 1000000000 + 9
  var p_pow : int := 1
  var hash-value := 0
  v.foreach() fn (a) 
    val value = (hash-value + (a.hasher + 1) * p-pow) % m
    p-pow := (p-pow * 31) % m
    value

pub fun hash( m : maybe<a>, ?hasher : (a) -> int ) : int
  match m
    Nothing -> 0
    Just(x) -> hasher(x)

pub fun hash( e : either<l, r>, ?hasher-l : (l) -> int, ?hasher-r : (r) -> int ) : int
  match e
    Left(l) -> hasher-l(l) * 2
    Right(r) -> hasher-r(r) * 3
