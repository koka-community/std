/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/rb-map

import std/data/rbtree-bu

pub value struct rbmap<k,v>
  tree: rbtree<k,v>

pub fun set(s: rbmap<k,v>, k: k, v: v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  val Rbmap(tree) = s 
  Rbmap(tree.set(k, v))

pub fun add(s: rbmap<k,v>, k: k, v: v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  val Rbmap(tree) = s 
  Rbmap(tree.add(k, v))

pub fun insert(s: rbmap<k,v>, k: k, f: (maybe<v>) -> e v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  val Rbmap(tree) = s 
  Rbmap(tree.insert(k, f))

// cmp-based: read-only, so `order2`'s ownership preservation is unnecessary
// overhead here (see rbtree.kk `cmp/contains`)
pub fun contains(s: rbmap<k,v>, ^k: k, ^?cmp: (k,k) -> e order): e bool
  val Rbmap(tree) = s 
  cmp/contains(tree, k)

pub fun empty(): rbmap<k,v>
  Rbmap(empty())

pub fun list(s: rbmap<k,v>) : list<(k,v)>
  val Rbmap(tree) = s
  tree.list

pub fun keys(s: rbmap<k,v>) : list<k>
  val Rbmap(tree) = s
  tree.keys

pub fun values(s: rbmap<k,v>) : list<v>
  val Rbmap(tree) = s
  tree.values

pub fun lookup(s: rbmap<k,v>, ^k: k, ^?cmp: (k,k) -> e order): e maybe<v>
  val Rbmap(tree) = s 
  cmp/lookup(tree, k)

// Delete via the bottom-up zipper (`rbtree-bu`). An absent key rebuilds the
// tree unchanged (`Leaf -> rebuild(z, Leaf)`), matching the usual map
// semantics. Total: every helper in the delete path already was, and nothing
// in it throws -- the `exn` on rbtree-bu's entry points was over-annotation.
// Keeps `order2` -- unlike lookup, this MUTATES, and returning the
// compared keys is what preserves ownership for the in-place rebalance.
pub fun remove(s: rbmap<k,v>, k: k, ^?order2: (k,k) -> order2<k>): rbmap<k,v>
  val Rbmap(tree) = s
  Rbmap(bu/remove(tree, k))

pub fun show(s: rbmap<k,v>, ?k/show: k -> e string, ?v/show: v -> e string): e string
  val Rbmap(tree) = s 
  tree.list.show

pub fun kvalue/map(s: rbmap<k,v>, f: (k, v) -> e x): e rbmap<k,x>
  val Rbmap(tree) = s 
  Rbmap(tree.map(f))

pub fun value/map(s: rbmap<k,v>, f: (v) -> e x): e rbmap<k,x>
  val Rbmap(tree) = s 
  Rbmap(tree.map(f(_)))

pub fun (==)(s1: rbmap<k,v>, s2: rbmap<k,v>, ^?k/order2: (k,k) -> e order2<k>, ^?v/order2: (v,v) -> e order2<v>): e bool
  match order2(s1, s2)
    Eq2 -> True
    _ -> False

pub fun order2(orig1: rbmap<k,v>, orig2: rbmap<k,v>, ^?k/order2: (k,k) -> e order2<k>, ^?v/order2: (v,v) -> e order2<v>): e order2<rbmap<k,v>>
  match orig1
    Rbmap(t1) -> 
      match orig2
        Rbmap(t2) -> order2(t1, t2, orig1, orig2)

fun rec/order2(t1: rbtree<k,v>, t2: rbtree<k,v>, orig1: rbmap<k,v>, orig2: rbmap<k,v>, ^?k/order2: (k,k) -> e order2<k>, ^?v/order2: (v,v) -> e order2<v>): e order2<rbmap<k,v>>
  match t1
    Leaf -> match t2
      Leaf -> Eq2(orig1)
      Node -> Lt2(orig1, orig2)
    Node(_,l1,k1,v1,r1) -> match t2
      Leaf -> Gt2(orig2, orig1)
      Node(_,l2,k2,v2,r2) -> 
        match order2(k1, k2)
          Lt2 -> Lt2(orig1, orig2)
          Gt2 -> Gt2(orig2, orig1)
          Eq2 -> 
            match order2(v1, v2)
              Lt2 -> Lt2(orig1, orig2)
              Gt2 -> Gt2(orig2, orig1)
              Eq2 ->
                match order2(l1, l2, orig1, orig2)
                  Lt2 -> Lt2(orig1, orig2)
                  Gt2 -> Gt2(orig2, orig1)
                  Eq2 -> order2(r1, r2, orig1, orig2)
//----------------------------------------------------------------------------
// Map operations
//
// Iteration (`list`, `keys`, `foldl`, `foreach`) is in KEY ORDER, as
// `Data.Map`'s is. Reads take `?cmp`, writes take `?order2` (see `lookup` vs
// `set` above). Names and semantics follow `std/data/linear-map`, so a
// container swap leaves call sites unchanged.
//----------------------------------------------------------------------------

pub fun is-empty(s: rbmap<k,v>): bool
  match s
    Rbmap(Leaf) -> True
    _ -> False

pub fun size(s: rbmap<k,v>): int
  s.list.length

pub fun contains-key(s: rbmap<k,v>, ^k: k, ^?cmp: (k,k) -> e order): e bool
  s.contains(k)

// later entries win, as with repeated `set`
pub fun from-list(l: list<(k,v)>, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  l.foldl(empty(), fn(acc, kv) { val (k, v) = kv; acc.set(k, v) })

// `linear-map/entries`
pub fun entries(s: rbmap<k,v>): list<(k,v)>
  s.list

// lookup-or-throw
pub fun get(s: rbmap<k,v>, ^k: k, ^?cmp: (k,k) -> <exn|e> order): <exn|e> v
  match s.lookup(k)
    Just(x) -> x
    Nothing -> throw("rb-map/get: key not found")

pub fun get-default(s: rbmap<k,v>, ^k: k, default: v, ^?cmp: (k,k) -> e order): e v
  match s.lookup(k)
    Just(x) -> x
    Nothing -> default

// If `k` is present apply `f(old, b)`, otherwise insert `b`.
pub fun update(s: rbmap<k,v>, k: k, b: v, f: (v, v) -> e v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  fun combine(mb)
    match mb
      Just(old) -> f(old, b)
      Nothing   -> b
  s.insert(k, combine)

// ADD-IF-ABSENT for every pair (the existing value wins), as `add`
pub fun add-all(s: rbmap<k,v>, l: list<(k,v)>, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  l.foldl(s, fn(acc, kv) { val (k, v) = kv; acc.add(k, v) })

pub fun listadd/(+)(s: rbmap<k,v>, l: list<(k,v)>, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  s.add-all(l)

pub fun foldl(s: rbmap<k,v>, acc: a, f: (a, k, v) -> e a): e a
  s.list.foldl(acc, fn(x, kv) { val (k, v) = kv; f(x, k, v) })

pub fun foreach(s: rbmap<k,v>, f: (k, v) -> e ()): e ()
  s.list.foreach(fn(kv) { val (k, v) = kv; f(k, v) })

pub fun filter(s: rbmap<k,v>, pred: (k, v) -> e bool, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  s.list.foldl(empty()) fn(acc, kv)
    val (k, v) = kv
    if pred(k, v) then acc.set(k, v) else acc

// Folds `s2` INTO `s1`, so `f` sees (value-from-s1, value-from-s2).
pub fun union-with(s1: rbmap<k,v>, s2: rbmap<k,v>, f: (v, v) -> e v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  s2.list.foldl(s1, fn(acc, kv) { val (k, v) = kv; acc.update(k, v, f) })

// left-biased: the value from `s1` wins
pub fun union(s1: rbmap<k,v>, s2: rbmap<k,v>, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  union-with(s1, s2, fn(x, _) x)

// LATER maps' values come FIRST in `combine`: the new map is folded into the
// accumulator (iterating the small side) with the arguments flipped.
pub fun unions-with(l: list<rbmap<k,v>>, combine: (v, v) -> e v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  l.foldl(empty(), fn(acc, m) union-with(acc, m, fn(x, y) combine(y, x)))

// earlier maps win
pub fun unions(l: list<rbmap<k,v>>, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  l.foldl(empty(), fn(acc, m) union(acc, m))

// Remove every key in `ks` (`foldr M.delete m ks`); absent keys are ignored.
pub fun remove-all(s: rbmap<k,v>, ks: list<k>, ^?order2: (k,k) -> order2<k>): rbmap<k,v>
  ks.foldr(s, fn(k, acc) acc.remove(k))
