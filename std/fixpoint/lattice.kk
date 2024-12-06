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

pub value type simple-lattice<a>
  LValue(a: a)
  LTop
  LBot

pub fun order2(a: simple-lattice<a>, b: simple-lattice<a>, ?order2: (a, a) -> order2<a>): pure order2<simple-lattice<a>>
  match (a, b)
    (LValue(a'), LValue(b')) ->
      match order2(a', b')
        Lt2 -> Lt2(a, b)
        Gt2 -> Gt2(b, a)
        Eq2 -> Eq2(a)
    (LTop, LTop) -> Eq2(LTop)
    (LTop, _) -> Gt2(LTop, b)
    (_, LTop) -> Lt2(a, LTop)
    (LBot, LBot) -> Eq2(LBot)
    (LBot, _) -> Lt2(LBot, b)
    (_, LBot) -> Gt2(a, LBot)

pub fun show(s: simple-lattice<a>, ?show: a -> string): string
  match s
    LValue(a) -> "LValue(" ++ show(a) ++ ")"
    LTop -> "LTop"
    LBot -> "LBot"

pub fun (==)(a: simple-lattice<a>, b: simple-lattice<a>, ?(==): (a, a) -> pure bool): pure bool
  match (a, b)
    (LValue(a'), LValue(b')) -> a' == b'
    (LTop, LTop) -> True
    (LBot, LBot) -> True
    _ -> False

pub fun simple/join(a: simple-lattice<a>, b: simple-lattice<a>, ?(==): (a, a) -> pure bool): pure (bool, simple-lattice<a>)
  match (a, b)
    (LTop, _) -> (False, LTop)
    (_, LTop) -> (True, LTop)
    (LBot, x) -> (True, x)
    (x, LBot) -> (False, x)
    (LValue(a'), LValue(b')) -> if a' == b' then (False, a) else (True, LTop)

pub fun simple/change-lattice((==): (a, a) -> pure bool): pure change-lattice<simple-lattice<a>, simple-lattice<a>>
  Change-lattice(LBot, fn(r, c) simple/join(r, c), fn(x) [x])

pub value type product-change<a,b>
  CLeft(a: a)
  CRight(b: b)

pub fun product/change-lattice(l: change-lattice<r1,c1>, r: change-lattice<r2,c2>): change-lattice<(r1,r2), product-change<c1,c2>>
  Change-lattice((l.bottom, r.bottom), 
                 (fn((l1,r1), c)
                    match c
                      CLeft(c1) -> 
                        val (change, l2) = (l.join)(l1, c1)
                        return (change, (l2, r1))
                      CRight(c2) -> 
                        val (change, r2) = (r.join)(r1, c2)
                        return (change, (l1, r2))
                   ),
                 fn((l1,r1)) (l.changes)(l1).map(fn(x) CLeft(x)) ++ (r.changes)(r1).map(fn(x) CRight(x))
  )