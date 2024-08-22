module std/fixpoint/lattice
import std/data/rb-set

pub struct change-lattice<r,c>
  bottom: r
  join: (r, c) -> pure (bool, r)
  changes: (r) -> list<c>

pub fun list/join(old: list<a>, new: a, ?(==): (a, a) -> pure bool): pure (bool, list<a>)
  if old.any(fn(x) x == new) then (False, old) else (True, Cons(new, old))

pub fun list/change-lattice(?(==): (a, a) -> pure bool): pure change-lattice<list<a>, a>
  Change-lattice([], fn(r, c) list/join(r, c), fn(x) x)

pub fun set/join(old: rbset<a>, new: a, ?order2: (a, a) -> pure order2<a>): pure (bool, rbset<a>)
  val (change, l') = old.check/add(new)
  (change, l')

pub fun set/change-lattice(?order2: (a, a) -> pure order2<a>): change-lattice<rbset<a>, a>
  Change-lattice(rb-set/empty(), fn(r, c) set/join(r, c), fn(x) x.list)