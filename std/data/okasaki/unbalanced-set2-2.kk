struct unbalanced-set<s,a>
  s-empty: s<a>
  s-member: (s<a>, a) -> bool
  s-insert: (s<a>, a) -> s<a>

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

// Exercise 2.2: Andersson[91]
// Rewrite member to take more than d + 1 comparisons by keeping track of a candidate element
//   that might be equal to the query element (the last element for which < returned false or <= returned true)
//   and checking for equality only when you hit the bottom of the tree
// pub fun tree/insertd(s: tree<t>, x: t, ?(<): (t,t) -> bool): maybe<tree<t>>

// Exercise 2.3:
// Inserting an existing element copies everything even if the element is not changed. Rewrite using exceptions.
// Note: Koka should be good at this (by returning unchanged the input, or jumping out of a tail recursive optimized call).
//       How would this look with ctx<>?

// Exercise 2.4:
// Combine the previous two exercises

// Exercise 2.5: Use sharing
// a) complete(x:elem, d:int) create a complete tree of depth `d` with `x` in every node. With sharing this should run in `O(d)` time.
// b) Extend the function to create balanced trees of arbitrary size. This function should run in O(log n) time. 
//    For a node, the two subtrees should differ in size by at most one.
//    (Hint: use a helper function create2 that, given a size m, creates a pair of trees, one of size m, and one of size m + 1)

// Exercise 2.6: Adapt to suport finite maps rather than sets.