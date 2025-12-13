/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/intset

import std/num/int64

abstract type intSet
  ISNil
  Tip(key: int64)
  Bin(pre: int64, msk: int64, left: intSet, right: intSet)

pub val empty-intset = ISNil

pub fun empty() : intSet
  ISNil

pub fun is-empty(s: intSet) : bool
  match s
    ISNil -> True
    _ -> False

fun mask-prefix(x: int64, m: int64) : int64
  x.and((m.or(m - one)).not)

fun nomatch(x: int64, p: int64, m: int64) : bool
  mask-prefix(x, m) != p

fun zero-bit(x: int64, m: int64) : bool
  x.and(m) == zero

fun highest-bit-mask(x: int64) : int64
  val z = clz(x)
  one.shl(63 - z)

fun join(p1: int64, t1: intSet, p2: int64, t2: intSet) : intSet
  val m = highest-bit-mask(p1.xor(p2))
  val p = mask-prefix(p1, m)
  if zero-bit(p1, m) then
    Bin(p, m, t1, t2)
  else
    Bin(p, m, t2, t1)

pub fun insert(t: intSet, x: int64) : intSet
  match t
    ISNil -> Tip(x)
    Tip(y) ->
      if x == y then t
      else join(x, Tip(x), y, t)
    Bin(p, m, l, r) ->
      if nomatch(x, p, m) then join(x, Tip(x), p, t)
      else if zero-bit(x, m) then Bin(p, m, insert(l, x), r)
      else Bin(p, m, l, insert(r, x))

pub fun member(t: intSet, x: int64) : bool
  match t
    ISNil -> False
    Tip(y) -> x == y
    Bin(p, m, l, r) ->
      if nomatch(x, p, m) then False
      else if zero-bit(x, m) then member(l, x)
      else member(r, x)

fun bin(p: int64, m: int64, l: intSet, r: intSet) : intSet
  match l
    ISNil -> r
    _ -> match r
      ISNil -> l
      _ -> Bin(p, m, l, r)

pub fun remove(t: intSet, x: int64) : intSet
  match t
    ISNil -> ISNil
    Tip(y) -> if x == y then ISNil else t
    Bin(p, m, l, r) ->
      if nomatch(x, p, m) then t
      else if zero-bit(x, m) then bin(p, m, remove(l, x), r)
      else bin(p, m, l, remove(r, x))

pub fun size(t: intSet) : int
  match t
    ISNil -> 0
    Tip(_) -> 1
    Bin(_, _, l, r) -> size(l) + size(r)

pub fun list(t: intSet) : list<int64>
  fold(t, [], fn(acc, x) Cons(x, acc))

pub fun fold(t: intSet, init: a, f: (a, int64) -> a) : a
  match t
    ISNil -> init
    Tip(x) -> f(init, x)
    Bin(_, _, l, r) -> fold(r, fold(l, init, f), f)

pub fun from-list(xs: list<int64>) : intSet
  xs.foldl(ISNil, insert)

// Equality
pub fun (==)(t1: intSet, t2: intSet) : div bool
  match (t1, t2)
    (ISNil, ISNil) -> True
    (Tip(x), Tip(y)) -> x == y
    (Bin(p1, m1, l1, r1), Bin(p2, m2, l2, r2)) ->
      m1 == m2 && p1 == p2 && l1 == l2 && r1 == r2
    _ -> False

// Show
pub fun show(t: intSet) : string
  "{" ++ list(t).map(show).join(", ") ++ "}"

fun prefix-val(t: intSet) : int64
  match t
    Tip(x) -> x
    Bin(p, _, _, _) -> p
    ISNil -> zero

fun shorter(m1: int64, m2: int64) : bool
  clz(m1) < clz(m2)

pub fun union(t1: intSet, t2: intSet) : div intSet
  match t1
    ISNil -> t2
    Tip(x) -> insert(t2, x)
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> t1
        Tip(x) -> insert(t1, x)
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then
            // m1 is coarser (less significant), t1 branches before t2
            if nomatch(p2, p1, m1) then join(p1, t1, p2, t2)
            else if zero-bit(p2, m1) then Bin(p1, m1, union(l1, t2), r1)
            else Bin(p1, m1, l1, union(r1, t2))
          else if shorter(m2, m1) then
            // m2 is coarser (less significant), t2 branches before t1
            if nomatch(p1, p2, m2) then join(p2, t2, p1, t1)
            else if zero-bit(p1, m2) then Bin(p2, m2, union(l2, t1), r2)
            else Bin(p2, m2, l2, union(r2, t1))
          else if p1 == p2 then
            // Same prefix and mask, merge recursively
            Bin(p1, m1, union(l1, l2), union(r1, r2))
          else
            join(p1, t1, p2, t2)

fun intersection-collision(t1: intSet, t2: intSet) : div intSet
  match t1
    Bin(p1, m1, l1, r1) ->
      val p2 = prefix-val(t2)
      if nomatch(p2, p1, m1) then ISNil
      else if zero-bit(p2, m1) then intersection(l1, t2)
      else intersection(r1, t2)
    _ -> ISNil

pub fun intersection(t1: intSet, t2: intSet) : div intSet
  match t1
    ISNil -> ISNil
    Tip(x) -> if member(t2, x) then t1 else ISNil
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> ISNil
        Tip(x) -> if member(t1, x) then t2 else ISNil
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then
            intersection-collision(t1, t2)
          else if shorter(m2, m1) then
            intersection-collision(t2, t1)
          else if p1 == p2 then
            bin(p1, m1, intersection(l1, l2), intersection(r1, r2))
          else
            ISNil

fun difference-collision(t1: intSet, t2: intSet) : div intSet
  match t1
    Bin(p1, m1, l1, r1) ->
      val p2 = prefix-val(t2)
      if nomatch(p2, p1, m1) then t1
      else if zero-bit(p2, m1) then bin(p1, m1, difference(l1, t2), r1)
      else bin(p1, m1, l1, difference(r1, t2))
    _ -> t1

pub fun difference(t1: intSet, t2: intSet) : div intSet
  match t1
    ISNil -> ISNil
    Tip(x) -> if member(t2, x) then ISNil else t1
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> t1
        Tip(x) -> remove(t1, x)
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then
            difference-collision(t1, t2)
          else if shorter(m2, m1) then
            val p1_ = prefix-val(t1)
            if nomatch(p1_, p2, m2) then t1
            else if zero-bit(p1_, m2) then difference(t1, l2)
            else difference(t1, r2)
          else if p1 == p2 then
            bin(p1, m1, difference(l1, l2), difference(r1, r2))
          else
            t1

pub fun is-subset-of(t1: intSet, t2: intSet) : div bool
  match t1
    ISNil -> True
    Tip(x) -> member(t2, x)
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> False
        Tip(_) -> False
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then False
          else if shorter(m2, m1) then
            val p1_ = prefix-val(t1)
            if nomatch(p1_, p2, m2) then False
            else if zero-bit(p1_, m2) then is-subset-of(t1, l2)
            else is-subset-of(t1, r2)
          else
            p1 == p2 && is-subset-of(l1, l2) && is-subset-of(r1, r2)

fun disjoint-collision(t1: intSet, t2: intSet) : div bool
  match t1
    Bin(p1, m1, l1, r1) ->
      val p2 = prefix-val(t2)
      if nomatch(p2, p1, m1) then True
      else if zero-bit(p2, m1) then disjoint(l1, t2)
      else disjoint(r1, t2)
    _ -> True

pub fun disjoint(t1: intSet, t2: intSet) : div bool
  match t1
    ISNil -> True
    Tip(x) -> !member(t2, x)
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> True
        Tip(x) -> !member(t1, x)
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then
            disjoint-collision(t1, t2)
          else if shorter(m2, m1) then
            disjoint-collision(t2, t1)
          else
            p1 != p2 || (disjoint(l1, l2) && disjoint(r1, r2))
