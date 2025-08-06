module std/algebraic/lattice

import std/core/undiv

// A join-semilattice is a set (type) with a least upper bound (join) operator that is associative, commutative, and idempotent.
pub value struct join-semilattice<t,e>
  join: (t, t) -> e t

// A meet-semilattice is a set (type) with a greatest lower bound (meet) operator that is associative, commutative, and idempotent.
pub value struct meet-semilattice<t,e>
  meet: (t, t) -> e t

// A lattice is a join-semilattice and a meet-semilattice.
pub value struct lattice<t,e>
  join: (t, t) -> e t
  meet: (t, t) -> e t

// Create the dual lattice by swapping the join and meet operators.
pub fun default/lattice/dual(?lattice: lattice<t,e>) : lattice<t,e>
  Lattice(lattice.meet, lattice.join)

