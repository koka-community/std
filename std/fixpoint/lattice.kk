module std/fixpoint/lattice
import std/data/linearset

pub struct change-lattice<r,c>
  bottom: r
  join: (r, c) -> div (bool, r)
  changes: (r) -> list<c>

pub fun list/join(old: list<a>, new: a, ?(==): (a, a) -> div bool): div (bool, list<a>)
  if old.any(fn(x) x == new) then (False, old) else (True, Cons(new, old))

pub fun list/change-lattice(?(==): (a, a) -> div bool): div change-lattice<list<a>, a>
  Change-lattice([], fn(r, c) list/join(r, c), fn(x) x)

pub fun set/join(old: linearSet<a>, new: a, ?(==): (a, a) -> div bool): div (bool, linearSet<a>)
  match old
    LinearSet(l) -> 
      val (change, l') = l.join(new)
      (change, LinearSet(l'))

pub fun set/change-lattice(?(==): (a, a) -> div bool): change-lattice<linearSet<a>, a>
  Change-lattice(LinearSet([]), fn(r, c) set/join(r, c), fn(x) x.list)