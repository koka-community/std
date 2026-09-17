/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/rb-set

import std/data/rbtree-bu

pub value struct rbset<k>
  tree: rbtree<k,()>

pub fun set/add(s: rbset<k>, k: k, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  val Rbset(tree) = s 
  Rbset(tree.set(k, ()))

// Adds `k`, also reporting whether it was new. Not spelled `check/add`: a
// second `add` with the same parameter shape makes every unannotated
// `s.add(x)` ambiguous.
pub fun check-add(s: rbset<k>, k: k, ^?order2: (k,k) -> e order2<k>): e (bool, rbset<k>)
  val Rbset(tree) = s 
  if tree.contains(k) then (False, Rbset(tree))
  else (True, Rbset(tree.set(k, ())))

pub fun contains(s: rbset<k>, k: k, ^?order2: (k,k) -> e order2<k>): e bool
  val Rbset(tree) = s 
  tree.contains(k)

pub fun empty(): rbset<k>
  Rbset(empty())

pub fun list(s: rbset<k>) : list<k>
  val Rbset(tree) = s
  tree.keys

pub fun show(s: rbset<k>, ?k/show: k -> e string): e string
  val Rbset(tree) = s 
  tree.keys.show

pub fun order2(t1: rbtree<k,()>, t2: rbtree<k,()>, orig1: rbset<k>, orig2: rbset<k>,  ^?order2: (k,k) -> e order2<k>): e order2<rbset<k>>
  match t1
    Leaf -> match t2
      Leaf -> Eq2(orig1)
      Node -> Lt2(orig1, orig2)
    Node(_,l1,k1,_,r1) -> match t2
      Leaf -> Gt2(orig2, orig1)
      Node(_,l2,k2,_,r2) -> 
        match order2(k1, k2)
          Lt2 -> Lt2(orig1, orig2)
          Gt2 -> Gt2(orig2, orig1)
          Eq2 -> 
            match order2(l1, l2, orig1, orig2)
              Lt2 -> Lt2(orig1, orig2)
              Gt2 -> Gt2(orig2, orig1)
              Eq2 -> order2(r1, r2, orig1, orig2)
//----------------------------------------------------------------------------
// Set operations
//
// Iteration (`list`) is in KEY ORDER, as `Data.Set`'s is. There is deliberately
// no `any`/`all`/`foldl`/`foreach`: those names collide with `list`'s wherever
// a receiver's type is not yet known, and `linear-set` never had them either --
// go through `.list`.
// Reads take `?cmp` and writes take `?order2`, following `rb-map`: a lookup
// need not preserve ownership of the compared keys, an in-place rebalance does.
// The names follow `std/data/linear-set` so a container swap leaves call sites
// unchanged.
//----------------------------------------------------------------------------

pub fun member(s: rbset<k>, ^k: k, ^?cmp: (k,k) -> e order): e bool
  val Rbset(tree) = s
  cmp/contains(tree, k)

pub fun is-empty(s: rbset<k>): bool
  match s
    Rbset(Leaf) -> True
    _ -> False

pub fun size(s: rbset<k>): int
  s.list.length

// `linear-set` spells the size `length`
pub fun length(s: rbset<k>): int
  s.size

pub fun from-list(l: list<k>, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  l.foldl(empty(), fn(acc, x) acc.set/add(x))

pub fun remove(s: rbset<k>, k: k, ^?order2: (k,k) -> order2<k>): rbset<k>
  val Rbset(tree) = s
  Rbset(bu/remove(tree, k))

pub fun filter(s: rbset<k>, pred: (k) -> e bool, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  s.list.foldl(empty()) fn(acc, x)
    if pred(x) then acc.set/add(x) else acc

// Inserts `s2`'s elements into `s1`: O(|s2| log |s1|). Deliberately no
// "insert the smaller into the larger" check -- the tree stores no count, so
// `size` is a full walk, and paying it per step made `unions` over k sets
// quadratic in the accumulated size.
pub fun union(s1: rbset<k>, s2: rbset<k>, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  s2.list.foldl(s1, fn(acc, x) acc.set/add(x))

pub fun unions(ss: list<rbset<k>>, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  ss.foldl(empty(), fn(acc, s) union(acc, s))

pub fun difference(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  s1.list.foldl(empty()) fn(acc, x)
    if s2.member(x) then acc else acc.set/add(x)

pub fun intersection(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  s1.list.foldl(empty()) fn(acc, x)
    if s2.member(x) then acc.set/add(x) else acc

pub fun disjoint(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  !s1.list.any(fn(x) s2.member(x))

// `linear-set/common`: the sets share at least one element
pub fun common(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  s1.list.any(fn(x) s2.member(x))

pub fun is-subset-of(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  s1.list.all(fn(x) s2.member(x))

pub fun (==)(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order): e bool
  s1.size == s2.size && s1.is-subset-of(s2)

// --- operator spellings, as in `linear-set` -------------------------------

pub fun member/(+)(s: rbset<k>, k: k, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  s.set/add(k)

pub fun set/(+)(s1: rbset<k>, s2: rbset<k>, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  union(s1, s2)

pub fun list/(+)(s: rbset<k>, l: list<k>, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  l.foldl(s, fn(acc, x) acc.set/add(x))

pub fun member/(-)(s: rbset<k>, k: k, ^?order2: (k,k) -> order2<k>): rbset<k>
  s.remove(k)

pub fun member-maybe/(-)(s: rbset<k>, mk: maybe<k>, ^?order2: (k,k) -> order2<k>): rbset<k>
  match mk
    Just(k) -> s.remove(k)
    Nothing -> s

pub fun set/(-)(s1: rbset<k>, s2: rbset<k>, ^?cmp: (k,k) -> e order, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  difference(s1, s2)

pub fun list/(-)(s: rbset<k>, l: list<k>, ^?order2: (k,k) -> order2<k>): rbset<k>
  l.foldl(s, fn(acc, x) acc.remove(x))
