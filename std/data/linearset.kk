/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/linearset

import std/core-extras
import std/test

pub struct linearSet<v>
  internal: list<v>

pub fun linear-set(l: list<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  l.foldl(LinearSet([]), fn(acc, x) acc.add(x))

pub fun set/show(l: linearSet<v>, ?show: v -> e string): e string
  "{" ++ l.internal.map(show).join(",") ++ "}"

pub fun (==)(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e bool
  l1.internal.length == l2.internal.length && l1.internal.all(fn(x) l2.member(x)) 

pub inline fun is-empty(l: linearSet<v>): bool
  l.internal.is-nil

pub inline fun member(l: linearSet<v>, a: v, ?(==): (v,v) -> e bool): e bool
  l.internal.any(fn(x) x == a)

pub fun union(l: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  l2.internal.foldl(l, fn(acc, x) acc.add(x))

pub fun unions(ls: list<linearSet<v>>, ?(==): (v, v) -> <exn|e> bool): <exn|e> linearSet<v>
  match ls
    Nil -> LinearSet([])
    Cons(x, xs) -> xs.foldl(x, fn(acc, x') acc.union(x'))

pub fun add(l: linearSet<v>, a: v, ?(==): (v, v) -> e bool): e linearSet<v>
  if (l.member(a)) then l else 
    match l
      LinearSet(l') -> LinearSet(Cons(a, l'))

pub fun member/(+)(l: linearSet<v>, a: v, ?(==): (v, v) -> e bool): e linearSet<v>
  if (l.member(a)) then l else 
    val LinearSet(l') = l
    LinearSet(Cons(a, l'))

pub fun set/(+)(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  l1.union(l2)

pub fun member/(-)(l: linearSet<v>, v: v, ?(==): (v, v) -> e bool): e linearSet<v>
  val LinearSet(l') = l
  LinearSet(l'.filter(fn(x) !(==)(x, v)))

pub fun member-maybe/(-)(l: linearSet<v>, v: maybe<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  match v
    Just(vv) -> 
      val LinearSet(l') = l
      LinearSet(l'.filter(fn(x) !(==)(x, vv)))
    Nothing -> l

pub fun set/(-)(l: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  val LinearSet(l') = l
  LinearSet(l'.filter(fn(x) !l2.member(x)))

pub fun intersection(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  val LinearSet(l') = l1
  LinearSet(l'.filter(fn(x) l2.member(x)))

pub fun disjoint(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e bool
  l1.intersection(l2).is-empty

pub fun common(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e bool
  !l1.disjoint(l2)

pub fun is-subset-of(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e bool
  l1.internal.all(fn(x) l2.member(x))

pub fun test-set()
  basic/test("Basics")
    val s = linear-set([1, 2, 3])
    val s2 = linear-set([2, 3, 4])
    val s3 = s + s2
    s3.set/show.println