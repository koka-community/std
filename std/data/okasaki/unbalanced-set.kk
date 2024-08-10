pub type tree<t>
  E
  T(t: tree<t>, value: t, t: tree<t>)

struct set<t>
  internal: tree<t>

pub fun set/member(s: set<t>, x: t, ?(<): (t,t) -> bool): bool
  s.internal.member(x)

pub fun tree/member(s: tree<t>, x: t, ?(<): (t,t) -> bool): bool
  match s
    E -> False
    T(l, y, r) -> if x < y then member(l, x) else if y < x then member(r, x) else True

pub fun set/insert(s: set<t>, x: t, ?(<): (t,t) -> bool): set<t>
  Set(s.internal.insert(x))
  
pub fun tree/insert(s: tree<t>, x: t, ?(<): (t,t) -> bool): tree<t>
  match s
    E -> T(E, x, E)
    T(l, y, r) -> if x < y then T(l.insert(x), y, r) else if y < x then T(l, y, r.insert(x)) else T(l, x, r)

