import errors

struct finite-map<m,k,v>
  s-empty: m<k,v>
  s-insert: (m<k,v>, k, v) -> m<k,v>
  s-lookup: (m<k,v>, k) -> efind<k> v

pub type tree<k,v>
  E
  T(l: tree<k,v>, key: k, value: v, r: tree<k,v>)

struct map<k,v>
  internal: tree<k,v>

fun map/empty(): map<k,v>
  Map(E)

fun tree/lookup(s: tree<k,v>, x: k, ?(<): (k,k) -> bool): efind<v> v
  match s
    E -> not-found()
    T(l, y, v, r) -> if x < y then lookup(l, x) else if y < x then lookup(r, x) else v

fun map/lookup(m: map<k,v>, x: k, ?(<): (k,k) -> bool): exn v
  with handler
    final ctl found(a) a
    final ctl not-found() throw("not found")
  tree/lookup(m.internal, x)

fun tree/bind(s: tree<k,v>, x: k, y: v, ?(<): (k,k) -> bool): tree<k,v>
  match s
    E -> T(E, x, y, E)
    T(l, z, w, r) -> if x < z then T(bind(l, x, y), z, w, r) else if z < x then T(l, z, w, bind(r, x, y)) else T(l, x, y, r)

fun map/bind(m: map<k,v>, x: k, y: v, ?(<): (k,k) -> bool): map<k,v>
  Map(tree/bind(m.internal, x, y))