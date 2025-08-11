module std/algebraic/groups

import std/core/undiv

// A semigroup is a set (type) with an associative operator.
pub value struct semigroup<t,e>
  associative-op: (t, t) -> e t

// Combines two elements using the semigroup's associative operator.
pub inline fun default/semigroup/(++)(x: t, y: t, .?semigroup: semigroup<t,e>) : e t
  associative-op.(x, y)
// Combines two elements using the semigroup's associative operator.
pub inline fun default/semigroup/combine(x: t, y: t, .?semigroup: semigroup<t,e>) : e t
  associative-op.(x, y)
// Repeats the associative operator `n` times on `x` with itself
pub inline fun default/semigroup/repeat(x: t, n: int, .?semigroup: semigroup<t,e>) : e t
  if n == 0 then x 
  else x ++ x.pretend-decreasing.repeat(n - 1)
// Concatenates a list of elements using the semigroup operator.
// This does a `foldl` with the accumulated list on the left of the semigroup operator. 
// This may or may not be most efficient depending on the semigroup operator.
pub inline fun default/semigroup/concat-maybe(xs: list<t>, .?semigroup: semigroup<t,e>) : e maybe<t>
  match xs
    Nil -> Nothing
    Cons(x, rst) -> Just(rst.foldl(x, combine))
// Joins a list of elements interspersed with `y` using the semigroup operator.
// This does a `foldl` with the accumulated list on the left of the semigroup operator. 
// This may or may not be most efficient depending on the semigroup operator.
pub inline fun default/semigroup/join-maybe(xs: list<t>, y: t, .?semigroup: semigroup<t,e>) : e maybe<t>
  match xs
    Nil -> Nothing
    Cons(x, rst) -> Just(rst.foldl(x, fn(acc, v) acc ++ y ++ v))
// Reverse the order of the semigroup operator.
pub inline fun default/semigroup/reverse(.?semigroup: semigroup<t,e>) : semigroup<t,e>
  Semigroup(fn(x, y) associative-op(y, x))

// A monoid is a semigroup (set with an associative operator) 
//  with the addition of an identity element.
pub value struct monoid<t,e>
  identity: t
  associative-op: (t, t) -> e t

// Cast to a semigroup for basic semigroup operators.
pub inline fun default/monoid/semigroup(.?monoid: monoid<t,e>): semigroup<t,e>
  Semigroup(associative-op)
// An alternative name for the monoid's identity element
pub inline fun default/monoid/empty(?monoid: monoid<t,e>): t
  monoid.identity
// Checks if `x` is the identity element of the monoid.
pub inline fun default/monoid/is-empty(x: t, .?monoid: monoid<t,e>, ?(==): (t, t) -> e bool): e bool
  x == identity
// Concatenates a list of elements using the monoid operator.
// This does a `foldl` with the accumulated list on the left of the monoid operator. 
// This may or may not be most efficient depending on the monoid operator.
pub inline fun default/monoid/concat(xs: list<t>, .?monoid: monoid<t,e>) : e t
  xs.foldl(identity, fn(acc, v) acc.associative-op(v))
// Joins a list of elements interspersed with `y` using the monoid operator.
// This does a `foldl` with the accumulated list on the left of the monoid operator. 
// This may or may not be most efficient depending on the monoid operator.
pub inline fun default/monoid/join(xs: list<t>, y: t, .?monoid: monoid<t,e>) : e t
  xs.foldl(identity, fn(acc, v) acc.associative-op(y.associative-op(v)))

// A group is a set (type) with an associative operator, inverse operator and identity element.
pub value struct group<t,e>
  associative-op: (t, t) -> e t
  inverse: t -> e t
  identity: t

// Cast to monoid for inherited operator.
pub inline fun default/group/monoid(.?group: group<t,e>): monoid<t,e>
  Monoid(identity, associative-op)
// `(~)` or `inverse` is the inverse operator for groups
pub inline fun default/group/(~)(x: t, .?group: group<t,e>): e t
  inverse(x)
// `inverse` is the inverse operator for groups
pub inline fun default/group/inverse(x: t, .?group: group<t,e>): e t
  inverse(x)
