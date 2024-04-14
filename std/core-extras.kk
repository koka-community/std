/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

module std/core-extras
import std/core/undiv

extern import
  c file "inline/core-extras"


fun (==)(m1: maybe<a>, m2: maybe<a>, ?(==): (a, a) -> e bool): e bool
  match (m1, m2)
    (Just(m1'), Just(m2')) -> m1' == m2'
    (Nothing, Nothing) -> True
    _ -> False

fun and(l: list<bool>): bool
  match l
    Nil -> True
    Cons(True, l') -> l'.and
    Cons(False) -> False

fun string/is-prefix-of(s1: string, s2: string): bool
  s2.starts-with(s1).bool

fun list/is-prefix-of(l1: list<a>, l2: list<a>, ?(==): (a, a) -> e bool): e bool
  match (l1, l2)
    (Nil, _) -> True
    (_, Nil) -> False
    (Cons(h1, t1), Cons(h2, t2)) -> h1 == h2 && t1.pretend-decreasing.is-prefix-of(t2)

fun list/maximum-by(l0: list<a>, cmp0: (a, a) -> e order): e maybe<a>
  fun loop(l: list<a>, acc: maybe<a>, cmp: (a, a) -> e order): e maybe<a>
    match l
      Nil -> acc
      Cons(h, t) ->
        match acc
          Nothing -> loop(t, Just(h), cmp)
          Just(max) ->
            match cmp(h, max)
              Gt -> loop(t, Just(h), cmp)
              _ -> loop(t, acc, cmp)
  loop(l0, Nothing, cmp0)

fun to-upper(c: char): char
  c.string.to-upper.head-char.default(c)
  
fun to-lower(c: char): char
  c.string.to-lower.head-char.default(c)

fun split-by(s: string, pred: (char) -> bool): list<string>
  fun loop(sl: sslice, numchars: int, acc: ctx<list<string>>): list<string>
    match sl.next
      Nothing -> acc ++. Nil
      Just((c, sl')) -> 
        if pred(c)
          then loop(sl'.pretend-decreasing, 0, acc ++ ctx Cons(sl'.advance(0 - numchars).truncate.extend(numchars).string, _))
          else loop(sl'.pretend-decreasing, numchars + 1, acc)
  loop(s.slice, 0, ctx _)

pub inline fun flatten( item : maybe<maybe<a>> ) : maybe<a>
  match item
    Just(x) -> x
    Nothing -> Nothing

pub fun expect-unjust( m : maybe<a>, msg: string ) : exn a
  match m
    Just(a) -> a
    Nothing -> throw("expect-unjust: " ++ msg)

// This function should never be called directly unless you know exactly what you are doing
pub inline extern unsafe-assign : forall<a> ( v : vector<a>, i : ssize_t, x : a ) -> total ()
  c "kk_vector_unsafe_assign_community"
  cs inline "(#1)[#2] = #3"
  //js inline "(#1)[#2] = #3"

// Return the element at position `index`  in vector `v`  without bounds check!
// This function should never be called directly unless you know exactly what you are doing
pub inline extern unsafe-idx( ^v : vector<a>, index : ssize_t ) : total a
  c  "kk_vector_at_borrow_community"
  cs inline "(#1)[#2]"
  //js inline "(#1)[#2]"

pub fun set( ^v : vector<a>, ^index : int, value : a ) : maybe<vector<a>>
  if index < 0 || index >= v.length then
    Nothing
  else
    v.unsafe-assign(index.ssize_t, value)
    Just(v)
