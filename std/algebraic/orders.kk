module std/algebraic/orders

import std/core/undiv

// A partial order is a binary relation that is reflexive, antisymmetric, and transitive.
// It will compare two elements and return 
pub struct partial-order<t,e>
  partial-compare: (t, t) -> e maybe<order>

pub struct total-order<t,e>
  compare: (t, t) -> e order

