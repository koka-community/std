import std/core/undiv

type lazy-list<a::V,e::E>
  LNil
  LCons(start: a, rest: delayed<e,lazy-list<a,e>>)

fun reverse(l0: lazy-list<a,e>): e lazy-list<a,e>
  fun rev(l: lazy-list<a,e>, acc: lazy-list<a,e>): e lazy-list<a,e> 
    match l
      LNil -> acc
      LCons(x, xs) -> rev(xs.force.pretend-decreasing, LCons(x, delay{acc}))
  rev(l0, LNil)

fun append(l0: lazy-list<a,e>, r0: lazy-list<a,e>): e lazy-list<a,e>
  fun app(l: lazy-list<a,e>, r: lazy-list<a,e>): e lazy-list<a,e> 
    match l
      LNil -> r
      LCons(x, xs) -> LCons(x, delay{app(xs.force.pretend-decreasing, r)})
  app(l0, r0)

fun (++)(l: lazy-list<a,e>, r: lazy-list<a,e>): e lazy-list<a,e>
  append(l, r)