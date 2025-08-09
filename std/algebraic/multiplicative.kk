module std/algebraic/multiplicative

import std/algebraic/groups

// Multiplicative monoids have an identity element of the associative operator which is known as one
pub inline fun default/one(?multiplicative-monoid: monoid<t,e>) : e t
  multiplicative-monoid.identity
// Multiplication for multiplicative monoids is an associative operator.
pub inline fun default/(*)(x: t, y: t, ?multiplicative-monoid: monoid<t,e>) : e t
  multiplicative-monoid.associative-op.(x, y)
// Multiplicative monoids inherit all monoid operators.
pub inline fun default/monoid(?multiplicative-monoid: monoid<t,e>) : monoid<t,e>
  multiplicative-monoid

// Multiplicative groups inherit properties from multiplicative monoids.
pub inline fun default/multiplicative-monoid(?multiplicative-group: group<t,e>) : monoid<t,e>
  Monoid(multiplicative-group.identity, multiplicative-group.associative-op)
// Multiplicative groups inherit operators from groups.
pub inline fun default/group(?multiplicative-group: group<t,e>) : group<t,e>
  multiplicative-group

// Multiplicative groups with an inverse have `(/)` as the binary operator for division.
// This is a total operator (not like normal division for fields).
pub inline fun default/(/)(x: t, y: t, ?multiplicative-group: group<t,e>) : e t
  multiplicative-group.associative-op.(x, multiplicative-group.inverse.(y))
// Another name for the group's inverse operator is `reciprocal`.
pub inline fun default/reciprocal(x: t, ?multiplicative-group: group<t,e>) : e t
  multiplicative-group.inverse.(x)