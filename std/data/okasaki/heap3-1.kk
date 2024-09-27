import errors
import std/core/undiv

struct heap<m,k>
  h-empty: m<k>
  h-is-empty: m<k> -> bool
  h-insert: (m<k>, k) -> m<k>
  h-merge: (m<k>, m<k>) -> m<k>
  h-find-min: m<k> -> err-empty k
  h-delete-min: m<k> -> err-empty m<k>

// Leftist heap 
// Property: Rank of any left child is at least as large as the range of it's right sibling
pub type tree<k>
  E
  T(rank: int, l: tree<k>, value: k, r: tree<k>)

struct leftist-heap<k>
  internal: tree<k>

fun rank(s: tree<k>): int
  match s
    E -> 0
    T(r,_,_,_) -> r

fun makeT(a: tree<k>, x: k, b: tree<k>): tree<k>
  if rank(a) >= rank(b) then T(rank(b) + 1, a, x, b) else T(rank(a) + 1, b, x, a)

fun empty()
  Leftist-heap(E)

fun is-empty(this: leftist-heap<k>)
  this.internal.is-E

fun tree/merge(l: tree<k>, r: tree<k>, ?(<=): (k, k) -> bool): tree<k>
  match (l, r)
    (E, _) -> r
    (_, E) -> l
    (T(_,a,x,b), T(_,c,y,d)) -> 
      if x <= y then makeT(a, x, merge(b.pretend-decreasing, r))
      else makeT(c, y, merge(l.pretend-decreasing, d))

fun heap/merge(l: leftist-heap<k>, r: leftist-heap<k>, ?(<=): (k, k) -> bool): leftist-heap<k>
  Leftist-heap(tree/merge(l.internal, r.internal))

fun insert(x: k, h: leftist-heap<k>, ?(<=): (k, k) -> bool): leftist-heap<k>
  Leftist-heap(merge(T(1, E, x, E), h.internal))

fun err/find-min(h: leftist-heap<k>): err-empty k
  match h.internal
    E -> err-empty()
    T(_, _, x, _) -> x

fun maybe/min(h: leftist-heap<k>): maybe<k>
  match h.internal
    E -> Nothing
    T(_, _, x, _) -> Just(x)

fun err/delete-min(h: leftist-heap<k>, ?(<=): (k, k) -> bool): err-empty leftist-heap<k>
  match h.internal
    E -> err-empty()
    T(_, a, _, b) -> Leftist-heap(merge(a, b))

fun maybe/delete(h: leftist-heap<k>, ?(<=): (k, k) -> bool): maybe<leftist-heap<k>>
  match h.internal
    E -> Nothing
    T(_, a, _, b) -> Just(Leftist-heap(merge(a, b)))


// Exercise 3.1: Prove that the right spine of a leftist heap of size n contains at most floor(log2(n + 1)) elements.
// Exercise 3.2: Define insert directly rather than via a call to merge
// Exercise 3.3: Implement a function fromList of type list<t> -> leftist-heap<t> that converts an unordered list by transforming into singleton heaps and then mergine
//               Instead of using one pass using fold, merge the heaps in ceil(log2(n)) passes where each pass merges adjacent pairs of heaps.
//               Show that it only takes O(n) time total
// Exercise 3.4: Cho and Sahni: Weight-biased leftist heaps (change the leftist property to the size of any left child is at least as large as the size of its right sibling)
//               a) Prove that the right spine contains at most floor(log2(n + 1)) elements
//               b) Modify leftist heaps to implement weight biased leftist heaps
//               c) Currently merge operates in two passes - top down to merge, and bottom up to makeT. Modify merge to operate in one top-down pass.
//               d) What advantages would the top-down version of merge have in a lazy environment? In a concurrent environment?


