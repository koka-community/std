/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/sort

import std/core/undiv

// Stable merge sort: O(n log n) comparisons (the behavior of Haskell's
// `Data.List.sortBy`); equal elements keep their input order, as they did in
// the quicksort this replaces, so results are unchanged.
//
// That quicksort took the FIRST element as pivot: O(n^2) with O(n) recursion
// depth on already (nearly) sorted input -- the common case, e.g. a range map
// built in source order, where it made one LSP hover take ~50s.
pub fun sort(l: list<a>, ^?(<): (a, a) -> e bool): e list<a>
  match l
    Nil -> Nil
    Cons(_, Nil) -> l
    _ -> merge-all(l.map(fn(x) Cons(x, Nil)))

// merge adjacent runs pairwise until one run is left
fun merge-all(runs: list<list<a>>, ^?(<): (a, a) -> e bool): e list<a>
  match runs
    Nil -> Nil
    Cons(r, Nil) -> r
    _ -> merge-all(merge-pairs(runs).pretend-decreasing)

fun merge-pairs(runs: list<list<a>>, ^?(<): (a, a) -> e bool): e list<list<a>>
  match runs
    Cons(xs, Cons(ys, rest)) -> Cons(merge(xs, ys), merge-pairs(rest))
    _ -> runs

// stable: on a tie the LEFT element goes first
fun merge(xs: list<a>, ys: list<a>, ^?(<): (a, a) -> e bool): e list<a>
  match xs
    Nil -> ys
    Cons(x, xx) -> match ys
      Nil -> xs
      Cons(y, yy) ->
        if y < x then Cons(y, merge(xs, yy.pretend-decreasing))
        else Cons(x, merge(xx.pretend-decreasing, ys))

pub tail fun group(l: list<a>, ?(==): (a, a) -> e bool): e list<list<a>>
  match l
    Nil -> Nil
    Cons(h, Nil) -> Cons(Cons(h, Nil), Nil)
    Cons(pivot, rst) ->
      val (equal, other) = rst.partition fn(it) { it == pivot }
      Cons(Cons(pivot, equal), group(other.pretend-decreasing))

pub inline fun group-by(l: list<a>, same-group: (a, a) -> e bool): e list<list<a>>
  group(l, ?(==) = same-group)

pub fun quicksort(xs : list<a>, res : list<a>, ^?(<): (a, a) -> bool) : list<a>
  match xs
    Cons(x, xx) ->
      val (lo, hi) = qpartition(x, xx)
      quicksort(lo.pretend-decreasing, Cons(x, quicksort(hi.pretend-decreasing, res)))
    Nil -> res

pub fun qpartition(x : a, ys : list<a>, ^?(<): (a, a) -> bool) : (list<a>, list<a>)
  match ys
    Cons(y, yy) ->
      if y < x then
        val (lo, hi) = qpartition(x, yy)
        (Cons(y, lo), hi)
      else
        val (lo, hi) = qpartition(x, yy)
        (lo, Cons(y, hi))
    Nil -> (Nil, Nil)