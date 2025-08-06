module std/algebraic/additive

import std/algebraic/groups

// Additive monoids have an identity element of the associative operator which is known as zero.
pub inline fun default/zero(?additive-monoid: monoid<t>) : t
  additive-monoid.identity
// Addition for additive monoids is an associative operator.
pub inline fun default/(+)(x: t, y: t, ?additive-monoid: monoid<t>) : t
  additive-monoid.associative-op.(x, y)
// Additive monoids inherit all monoid operators.
pub inline fun default/monoid(?additive-monoid: monoid<t>) : monoid<t>
  additive-monoid

// Additive groups inherit properties from additive monoids.
pub inline fun default/additive-monoid(?additive-group: group<t>) : monoid<t>
  Monoid(additive-group.identity, additive-group.associative-op)
// Additive groups inherit operators from groups.
pub inline fun default/group(?additive-group: group<t>) : group<t>
  additive-group

// Additive groups with an inverse have `(-)` as the binary operator for subtraction.
pub inline fun default/(-)(x: t, y: t, ?additive-group: group<t>) : t
  additive-group.associative-op.(x, additive-group.inverse.(y))

