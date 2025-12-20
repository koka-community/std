/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/sort

import std/core/undiv

pub fun sort(l: list<a>, ^?(<): (a, a) -> e bool): e list<a>
  match l
    Nil -> Nil
    Cons(h, Nil) -> Cons(h, Nil)
    Cons(pivot, rst) -> 
      val (smaller, greater) = rst.partition fn(it) { it < pivot }
      sort(smaller.pretend-decreasing) ++ Cons(pivot, sort(greater.pretend-decreasing))

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