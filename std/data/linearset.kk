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
  l1.internal.length == l2.internal.length && l1.internal.all(l2.member(_)) 

pub inline fun is-empty(l: linearSet<v>): bool
  l.internal.is-nil

pub inline fun member(l: linearSet<v>, a: v, ?(==): (v,v) -> e bool): e bool
  l.internal.any(_ == a)

pub fun union(l: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  l2.internal.foldl(l, fn(acc, x) acc.add(x))

pub fun unions(ls: list<linearSet<v>>, ?(==): (v, v) -> e bool): e linearSet<v>
  match ls
    Nil -> LinearSet([])
    Cons(x, xs) -> xs.foldl(x, fn(acc, x') acc.union(x'))

pub fun add(l: linearSet<v>, a: v, ?(==): (v, v) -> e bool): e linearSet<v>
  if (l.member(a)) then l else 
    match l
      LinearSet(l') -> LinearSet(Cons(a, l'))

pub fun remove(l: linearSet<v>, a: v, ?(==): (v, v) -> e bool): e linearSet<v>
  val LinearSet(l') = l
  LinearSet(l'.filter(!(_ == a)))

pub fun member/(+)(l: linearSet<v>, a: v, ?(==): (v, v) -> e bool): e linearSet<v>
  l.add(a)

pub fun set/(+)(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  l1.union(l2)

pub fun list/(+)(l1: linearSet<v>, l2: list<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  l2.foldl(l1, fn(s, v) s + v)

pub fun member/(-)(l: linearSet<v>, v: v, ?(==): (v, v) -> e bool): e linearSet<v>
  l.remove(v)

pub fun member-maybe/(-)(l: linearSet<v>, v: maybe<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  match v
    Just(vv) -> 
      val LinearSet(l') = l
      LinearSet(l'.filter(!(_ == vv)))
    Nothing -> l

pub fun set/(-)(l: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  val LinearSet(l') = l
  LinearSet(l'.filter(!l2.member(_)))

pub fun list/(-)(l: linearSet<v>, l2: list<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  l2.foldl(l, fn(s, v) s - v)

pub fun filter(l: linearSet<v>, f: (v) -> e bool): e linearSet<v>
  val LinearSet(l') = l
  LinearSet(l'.filter(f))

pub fun intersection(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e linearSet<v>
  val LinearSet(l') = l1
  LinearSet(l'.filter(l2.member(_)))

pub fun disjoint(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e bool
  l1.intersection(l2).is-empty

pub fun common(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e bool
  !l1.disjoint(l2)

pub fun is-subset-of(l1: linearSet<v>, l2: linearSet<v>, ?(==): (v, v) -> e bool): e bool
  l1.internal.all(l2.member(_))

pub fun list(l: linearSet<v>): e list<v>
  l.internal

pub fun length(l: linearSet<v>): int
  l.internal.length
