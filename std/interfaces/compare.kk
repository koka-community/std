/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
import std/test

value struct strict-compare<a>
  eq: (a, a) -> bool
  lt: (a, a) -> bool
  gt: (a, a) -> bool
  
fun eq/strict-compare(?(==): (a, a) -> bool, ?(<): (a, a) -> bool, ?(>): (a, a) -> bool): strict-compare<a>
  Strict-Compare((==), (<), (>))

fun cmp/strict-compare(?cmp: (a, a) -> order): strict-compare<a>
  Strict-Compare(fn(a0, a1) a0 == a1, fn(a0, a1) a0 < a1, fn(a0, a1) a0 > a1)

value struct compare<a>
  eq: (a, a) -> bool
  lt: (a, a) -> bool
  gt: (a, a) -> bool
  lte: (a, a) -> bool
  gte: (a, a) -> bool

fun cmp/compare(?cmp: (a, a) -> order): compare<a>
  Compare(fn(a0, a1) a0 == a1, fn(a0, a1) a0 < a1, fn(a0, a1) a0 > a1, fn(a0, a1) a0 <= a1, fn(a0, a1) a0 >= a1)

fun eq/compare(?(==): (a, a) -> bool, ?(<): (a, a) -> bool, ?(>): (a, a) -> bool, ?(<=): (a, a) -> bool, ?(>=): (a, a) -> bool): compare<a>
  Compare((==), (<), (>), (<=), (>=))

fun test-compare()
  basic/test("Int comparison")
    fun x(i: int, ?strict-compare: strict-compare<int>)
      (?strict-compare.eq)(i, 1)
    expect(True)
      x(1)
    expect(False)
      // You can use an explicit implicit for types that you know have more efficient >,<,== than comparison
      x(2, ?strict-compare=eq/strict-compare()) 