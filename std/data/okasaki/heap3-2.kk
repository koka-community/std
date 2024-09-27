import errors
import std/core/undiv

struct heap<m,k>
  h-empty: m<k>
  h-is-empty: m<k> -> bool
  h-insert: (m<k>, k) -> m<k>
  h-merge: (m<k>, m<k>) -> m<k>
  h-find-min: m<k> -> err-empty k
  h-delete-min: m<k> -> err-empty m<k>

// Binomial heap (Binomial queues Vui 78, Bro 78)
// Property: rank 0 node is a singleton, rank r + 1 node is formed by linking two binomial trees of rank r
// Property: rank r node has 2^r children
// Property: Each list of children is in decreaesing order of rank, and elements are stored in heap order
pub type tree<k>
  T(rank: int, value: k, ts: list<tree<k>>)

// A heap is a collection of heap-ordered binomial trees in which no two trees have the same rank.
struct binomial-heap<k>
  trees: list<tree<k>>

fun link(t1: tree<k>, t2: tree<k>, ?(<=) : (k,k) -> bool): tree<k>
  match (t1, t2)
    (T(r, x1, ts1), T(_, x2, ts2)) ->
      if x1 <= x2 then T(r + 1, x1, Cons(t2, ts1))
      else T(r + 1, x2, Cons(t1, ts2))



