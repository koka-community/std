/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
// Ordered maps over bottom-up red-black trees (`rbtree-bu`), keyed by `?cmp`.
//
// Every operation compares with a plain `order`, keys borrowed. The
// `std/data/rb-map-order2` variant writes with `?order2` instead, which hands
// the compared keys back so an in-place rebalance keeps ownership of them --
// but every comparison then ALLOCATES its `Lt2`/`Gt2`/`Eq2` result. For keys
// that are cheap to keep (names, ints) that allocation is the dominant cost
// (7% of the compiler's warm build went to `order2` map unions), so `?cmp` is
// the default. Both variants build identical trees over the same `rbmap`.
module std/data/rb-map

import std/data/rbtree-bu

pub value struct rbmap<k,v>
  tree: rbtree<k,v>

pub fun set(s: rbmap<k,v>, k: k, v: v, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  val Rbmap(tree) = s
  Rbmap(cmp/set(tree, k, v))

// the existing value wins
pub fun add(s: rbmap<k,v>, k: k, v: v, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  val Rbmap(tree) = s
  Rbmap(cmp/add(tree, k, v))

pub fun insert(s: rbmap<k,v>, k: k, f: (maybe<v>) -> e v, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  val Rbmap(tree) = s
  Rbmap(cmp/insert(tree, k, f))

pub fun remove(s: rbmap<k,v>, k: k, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  val Rbmap(tree) = s
  Rbmap(cmp/remove(tree, k))

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

pub fun show(s: rbmap<k,v>, ?k/show: k -> e string, ?v/show: v -> e string): e string
  val Rbmap(tree) = s
  tree.list.show

pub fun kvalue/map(s: rbmap<k,v>, f: (k, v) -> e x): e rbmap<k,x>
  val Rbmap(tree) = s
  Rbmap(tree.map(f))

pub fun value/map(s: rbmap<k,v>, f: (v) -> e x): e rbmap<k,x>
  val Rbmap(tree) = s
  Rbmap(tree.map(f(_)))

// lexicographic over the entries in key order
pub fun cmp(s1: rbmap<k,v>, s2: rbmap<k,v>, ^?k/cmp: (k,k) -> e order, ^?v/cmp: (v,v) -> e order): e order
  fun go(xs, ys)
    match xs
      Nil -> if ys.is-nil then Eq else Lt
      std/core/types/Cons((k1, v1), xx) -> match ys
       Nil -> Gt
       std/core/types/Cons((k2, v2), yy) -> match k/cmp(k1, k2)
         Eq -> match v/cmp(v1, v2)
           Eq -> go(xx, yy)
           o -> o
         o -> o
  go(s1.list, s2.list)

pub fun (==)(s1: rbmap<k,v>, s2: rbmap<k,v>, ^?k/cmp: (k,k) -> e order, ^?v/cmp: (v,v) -> e order): e bool
  cmp(s1, s2) == Eq

//----------------------------------------------------------------------------
// Map operations
//
// Iteration (`list`, `keys`, `foldl`, `foreach`) is in KEY ORDER, as
// `Data.Map`'s is.
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
pub fun from-list(l: list<(k,v)>, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  l.foldl(empty(), fn(acc, kv) { val (k, v) = kv; acc.set(k, v) })

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
pub fun update(s: rbmap<k,v>, k: k, b: v, f: (v, v) -> e v, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  fun combine(mb)
    match mb
      Just(old) -> f(old, b)
      Nothing   -> b
  s.insert(k, combine)

// ADD-IF-ABSENT for every pair (the existing value wins), as `add`
pub fun add-all(s: rbmap<k,v>, l: list<(k,v)>, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  l.foldl(s, fn(acc, kv) { val (k, v) = kv; acc.add(k, v) })

pub fun listadd/(+)(s: rbmap<k,v>, l: list<(k,v)>, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  s.add-all(l)

pub fun foldl(s: rbmap<k,v>, acc: a, f: (a, k, v) -> e a): e a
  s.list.foldl(acc, fn(x, kv) { val (k, v) = kv; f(x, k, v) })

pub fun foreach(s: rbmap<k,v>, f: (k, v) -> e ()): e ()
  s.list.foreach(fn(kv) { val (k, v) = kv; f(k, v) })

pub fun filter(s: rbmap<k,v>, pred: (k, v) -> e bool, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  s.list.foldl(empty()) fn(acc, kv)
    val (k, v) = kv
    if pred(k, v) then acc.set(k, v) else acc

// Folds `s2` INTO `s1`, so `f` sees (value-from-s1, value-from-s2).
pub fun union-with(s1: rbmap<k,v>, s2: rbmap<k,v>, f: (v, v) -> e v, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  s2.list.foldl(s1, fn(acc, kv) { val (k, v) = kv; acc.update(k, v, f) })

// left-biased: the value from `s1` wins
pub fun union(s1: rbmap<k,v>, s2: rbmap<k,v>, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  union-with(s1, s2, fn(x, _) x)

// LATER maps' values come FIRST in `combine`: the new map is folded into the
// accumulator (iterating the small side) with the arguments flipped.
pub fun unions-with(l: list<rbmap<k,v>>, combine: (v, v) -> e v, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  l.foldl(empty(), fn(acc, m) union-with(acc, m, fn(x, y) combine(y, x)))

// earlier maps win
pub fun unions(l: list<rbmap<k,v>>, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  l.foldl(empty(), fn(acc, m) union(acc, m))

// Remove every key in `ks` (`foldr M.delete m ks`); absent keys are ignored.
pub fun remove-all(s: rbmap<k,v>, ks: list<k>, ^?cmp: (k,k) -> e order): e rbmap<k,v>
  ks.foldr(s, fn(k, acc) acc.remove(k))
