/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// Ordered sets over bottom-up red-black trees (`rbtree-bu`), keyed by `?cmp`.
//
// As with `std/data/rb-map`, every operation compares with a plain `order`,
// keys borrowed; `std/data/rb-set-order2` is the variant whose writes use
// `?order2` (ownership-preserving, but allocating per comparison).
module std/data/rb-set

import std/data/rbtree-bu

pub value struct rbset<k>
  tree: rbtree<k,()>

pub fun set/add(s: rbset<k>, k: k, ^?cmp: (k,k) -> e order): e rbset<k>
  val Rbset(tree) = s
  Rbset(cmp/set(tree, k, ()))

// Adds `k`, also reporting whether it was new. Not spelled `check/add`: a
// second `add` with the same parameter shape makes every unannotated
// `s.add(x)` ambiguous.
pub fun check-add(s: rbset<k>, k: k, ^?cmp: (k,k) -> e order): e (bool, rbset<k>)
  val Rbset(tree) = s
  if cmp/contains(tree, k) then (False, Rbset(tree))
  else (True, Rbset(cmp/set(tree, k, ())))

pub fun contains(s: rbset<k>, ^k: k, ^?cmp: (k,k) -> e order): e bool
  val Rbset(tree) = s
  cmp/contains(tree, k)

pub fun empty(): rbset<k>
  Rbset(empty())

pub fun list(s: rbset<k>) : list<k>
  val Rbset(tree) = s
  tree.keys

pub fun show(s: rbset<k>, ?k/show: k -> e string): e string
  val Rbset(tree) = s
  tree.keys.show

// lexicographic over the elements in key order
pub fun cmp(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e order
  fun go(xs, ys)
    match xs
      Nil -> if ys.is-nil then Eq else Lt
      std/core/types/Cons(x, xx) -> match ys
        Nil -> Gt
        std/core/types/Cons(y, yy) -> match cmp(x, y)
          Eq -> go(xx, yy)
          o -> o
  go(s1.list, s2.list)

//----------------------------------------------------------------------------
// Set operations
//
// Iteration (`list`) is in KEY ORDER, as `Data.Set`'s is. There is deliberately
// no `any`/`all`/`foldl`/`foreach`: those names collide with `list`'s wherever
// a receiver's type is not yet known -- go through `.list`.
//----------------------------------------------------------------------------

pub fun member(s: rbset<k>, ^k: k, ^?cmp: (k,k) -> e order): e bool
  s.contains(k)

pub fun is-empty(s: rbset<k>): bool
  match s
    Rbset(Leaf) -> True
    _ -> False

pub fun size(s: rbset<k>): int
  s.list.length

pub fun length(s: rbset<k>): int
  s.size

pub fun from-list(l: list<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  l.foldl(empty(), fn(acc, x) acc.set/add(x))

pub fun remove(s: rbset<k>, k: k, ^?cmp: (k,k) -> e order): e rbset<k>
  val Rbset(tree) = s
  Rbset(cmp/remove(tree, k))

pub fun filter(s: rbset<k>, pred: (k) -> e bool, ^?cmp: (k,k) -> e order): e rbset<k>
  s.list.foldl(empty()) fn(acc, x)
    if pred(x) then acc.set/add(x) else acc

// Inserts `s2`'s elements into `s1`: O(|s2| log |s1|). Deliberately no
// "insert the smaller into the larger" check -- the tree stores no count, so
// `size` is a full walk, and paying it per step made `unions` over k sets
// quadratic in the accumulated size.
pub fun union(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  s2.list.foldl(s1, fn(acc, x) acc.set/add(x))

pub fun unions(ss: list<rbset<k>>, ^?cmp: (k,k) -> e order): e rbset<k>
  ss.foldl(empty(), fn(acc, s) union(acc, s))

pub fun difference(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  s1.list.foldl(empty()) fn(acc, x)
    if s2.member(x) then acc else acc.set/add(x)

pub fun intersection(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  s1.list.foldl(empty()) fn(acc, x)
    if s2.member(x) then acc.set/add(x) else acc

pub fun disjoint(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  !s1.list.any(fn(x) s2.member(x))

// the sets share at least one element
pub fun common(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  s1.list.any(fn(x) s2.member(x))

pub fun is-subset-of(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  s1.list.all(fn(x) s2.member(x))

pub fun (==)(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  s1.size == s2.size && s1.is-subset-of(s2)

// --- operator spellings -----------------------------------------------------

pub fun member/(+)(s: rbset<k>, k: k, ^?cmp: (k,k) -> e order): e rbset<k>
  s.set/add(k)

pub fun set/(+)(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  union(s1, s2)

pub fun list/(+)(s: rbset<k>, l: list<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  l.foldl(s, fn(acc, x) acc.set/add(x))

pub fun member/(-)(s: rbset<k>, k: k, ^?cmp: (k,k) -> e order): e rbset<k>
  s.remove(k)

pub fun member-maybe/(-)(s: rbset<k>, mk: maybe<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  match mk
    Just(k) -> s.remove(k)
    Nothing -> s

pub fun set/(-)(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  difference(s1, s2)

pub fun list/(-)(s: rbset<k>, l: list<k>, ^?cmp: (k,k) -> e order): e rbset<k>
  l.foldl(s, fn(acc, x) acc.remove(x))
