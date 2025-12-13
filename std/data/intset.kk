/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/intset
import std/core/undiv
import std/num/int64

/// An efficient set of integers based on Big-Endian Patricia Trees.
abstract type intSet
  ISNil
  Tip(key: int64)
  Bin(pre: int64, msk: int64, left: intSet, right: intSet)

/// The empty set.
pub val empty-intset = ISNil

/// Create an empty set.
pub fun empty() : intSet
  ISNil

/// Check if a set is empty.
/// ```
/// empty().is-empty == True
/// insert(empty(), 1.int64).is-empty == False
/// ```
pub fun is-empty(s: intSet) : bool
  match s
    ISNil -> True
    _ -> False

// ----------------------------------------------------------------------------
// Bit manipulation helpers
// ----------------------------------------------------------------------------

/// Calculate the prefix of `x` masked by `m`.
/// The mask `m` is expected to have exactly one bit set.
/// The result preserves the bits of `x` above the bit set in `m`, and clears the rest.
fip fun mask-prefix(x: int64, m: int64) : int64
  x.and((m.or(m - one)).not)

/// Check if `x` matches the prefix `p` with mask `m`.
/// Returns `True` if the bits of `x` above `m` do not match `p`.
fip fun nomatch(x: int64, p: int64, m: int64) : bool
  mask-prefix(x, m) != p

/// Check if the bit at mask `m` is zero in `x`.
fip fun zero-bit(x: int64, m: int64) : bool
  x.and(m) == zero

/// Find the highest bit where two bits differ.
/// Returns a mask with exactly that bit set.
fip fun highest-bit-mask(x: int64) : int64
  val z = clz(x)
  one.shl(63 - z)

/// Join two disjoint trees `t1` and `t2` with prefixes `p1` and `p2`.
/// Finds the highest bit where `p1` and `p2` differ and creates a new `Bin` node.
fip(1) fun join(p1: int64, t1: intSet, p2: int64, t2: intSet) : intSet
  val m = highest-bit-mask(p1.xor(p2))
  val p = mask-prefix(p1, m)
  if zero-bit(p1, m) then
    Bin(p, m, t1, t2)
  else
    Bin(p, m, t2, t1)

// ----------------------------------------------------------------------------
// Zipper for tail-recursive traversal
// ----------------------------------------------------------------------------

/// A zipper represents the path from the root to the current node,
/// allowing us to reconstruct the tree (zip up) after modification.
type intSetZipper
  Done
  BinL(pre: int64, msk: int64, up: intSetZipper, right: intSet)
  BinR(pre: int64, msk: int64, left: intSet, up: intSetZipper)

/// Reconstruct the tree by zipping up from the current position `t` using the zipper `z`.
pub fip fun zip-up(z: intSetZipper, t: intSet) : intSet
  match z
    Done -> t
    BinL(p, m, up, r) -> zip-up(up, Bin(p, m, t, r))
    BinR(p, m, l, up) -> zip-up(up, Bin(p, m, l, t))

/// Insert an integer into the set.
/// ```
/// empty().insert(1.int64).list == [1.int64]
/// empty().insert(1.int64).insert(1.int64).list == [1.int64]
/// ```
pub fun insert(t: intSet, x: int64) : intSet
  insert-loop(t, x, Done)

// Tail-recursive insert using a zipper.
fip(2) fun insert-loop(t: intSet, x: int64, z: intSetZipper) : intSet
  match t
    ISNil -> zip-up(z, Tip(x))
    Tip(y) ->
      if x == y then zip-up(z, Tip(y))
      else zip-up(z, join(x, Tip(x), y, Tip(y)))
    Bin(p, m, l, r) ->
      if nomatch(x, p, m) then zip-up(z, join(x, Tip(x), p, Bin(p, m, l, r)))
      else if zero-bit(x, m) then insert-loop(l, x, BinL(p, m, z, r))
      else insert-loop(r, x, BinR(p, m, l, z))

/// Check if an integer is in the set.
/// ```
/// empty().insert(1.int64).member(1.int64) == True
/// empty().insert(1.int64).member(2.int64) == False
/// ```
pub fun member(t: intSet, x: int64) : bool
  match t
    ISNil -> False
    Tip(y) -> x == y
    Bin(p, m, l, r) ->
      if nomatch(x, p, m) then False
      else if zero-bit(x, m) then member(l, x)
      else member(r, x)

// Smart constructor that avoids creating Bins with empty children.
fun bin(p: int64, m: int64, l: intSet, r: intSet) : intSet
  match l
    ISNil -> r
    _ -> match r
      ISNil -> l
      _ -> Bin(p, m, l, r)

/// Remove an integer from the set.
/// ```
/// empty().insert(1.int64).remove(1.int64).is-empty == True
/// empty().insert(1.int64).remove(2.int64).list == [1.int64]
/// ```
pub fun remove(t: intSet, x: int64) : intSet
  remove-loop(t, x, Done)

// Tail-recursive remove using a zipper.
fbip fun remove-loop(t: intSet, x: int64, z: intSetZipper) : intSet
  match t
    ISNil -> zip-up(z, ISNil)
    Tip(y) ->
      if x == y then
        match z
          Done -> ISNil
          BinL(_, _, up, r) -> zip-up(up, r)
          BinR(_, _, l, up) -> zip-up(up, l)
      else zip-up(z, Tip(y))
    Bin(p, m, l, r) ->
      if nomatch(x, p, m) then zip-up(z, Bin(p, m, l, r))
      else if zero-bit(x, m) then remove-loop(l, x, BinL(p, m, z, r))
      else remove-loop(r, x, BinR(p, m, l, z))

/// Get the number of elements in the set.
/// ```
/// empty().insert(1.int64).insert(2.int64).size == 2
/// ```
pub fun size(t: intSet) : int
  match t
    ISNil -> 0
    Tip(_) -> 1
    Bin(_, _, l, r) -> size(l) + size(r)

/// Convert the set to a list of integers.
/// The order of elements is not specified.
pub fun list(t: intSet) : list<int64>
  fold(t, [], fn(acc, x) Cons(x, acc))

/// Fold over the elements of the set.
/// The order of elements is not specified.
pub tail fun fold(t: intSet, init: a, ^f: (a, int64) -> a) : a
  with pretend-no-div
  fold-loop(t, init, f, Done)

// Move up the zipper, processing the other branch if necessary.
tail fun fold-up(z: intSetZipper, acc: a, ^f: (a, int64) -> a) : div a
  match z
    Done -> acc
    BinL(_, _, up, r) -> fold-loop(r.pretend-decreasing, acc, f, up)
    BinR(_, _, l, up) -> fold-loop(l.pretend-decreasing, acc, f, up)

// Tail-recursive fold using a zipper to simulate the stack.
tail fun fold-loop(t: intSet, acc: a, ^f: (a, int64) -> a, z: intSetZipper) : div a
  match t
    ISNil -> fold-up(z.pretend-decreasing, acc, f)
    Tip(x) -> fold-up(z.pretend-decreasing, f(acc, x), f)
    Bin(p, m, l, r) -> fold-loop(l.pretend-decreasing, acc, f, BinL(p, m, z, r))

/// Create a set from a list of integers.
pub fun from-list(xs: list<int64>) : intSet
  xs.foldl(ISNil, insert)

/// Check if two sets are equal.
pub fun (==)(t1: intSet, t2: intSet) : div bool
  eq-loop([(t1, t2)])

// Tail-recursive equality check using an explicit stack.
tail fun eq-loop(stack: list<(intSet, intSet)>) : div bool
  match stack
    Nil -> True
    Cons((a, b), rest) ->
      match (a, b)
        (ISNil, ISNil) -> eq-loop(rest)
        (Tip(x), Tip(y)) -> if x == y then eq-loop(rest) else False
        (Bin(p1, m1, l1, r1), Bin(p2, m2, l2, r2)) ->
          if p1 == p2 && m1 == m2 then
            eq-loop(Cons((l1, l2), Cons((r1, r2), rest)))
          else
            False
        _ -> False

/// Convert the set to a string representation.
pub fun show(t: intSet) : string
  "{" ++ list(t).map(show).join(", ") ++ "}"

fun prefix-val(t: intSet) : int64
  match t
    Tip(x) -> x
    Bin(p, _, _, _) -> p
    ISNil -> zero

// Check if mask m1 is shorter (more significant) than m2.
// A shorter mask corresponds to a node higher in the tree.
fun shorter(m1: int64, m2: int64) : bool
  clz(m1) < clz(m2)

/// Compute the union of two sets.
/// ```
/// union(from-list([1.int64, 2.int64]), from-list([2.int64, 3.int64])).list == [1.int64, 2.int64, 3.int64]
/// ```
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

// Helper for intersection when t1 is a Bin and t2 is a subset of t1's prefix.
fun intersection-collision(t1: intSet, t2: intSet) : div intSet
  match t1
    Bin(p1, m1, l1, r1) ->
      val p2 = prefix-val(t2)
      if nomatch(p2, p1, m1) then ISNil
      else if zero-bit(p2, m1) then intersection(l1, t2)
      else intersection(r1, t2)
    _ -> ISNil

/// Compute the intersection of two sets.
/// ```
/// intersection(from-list([1.int64, 2.int64]), from-list([2.int64, 3.int64])).list == [2.int64]
/// ```
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

// Helper for difference when t1 is a Bin and t2 is a subset of t1's prefix.
fun difference-collision(t1: intSet, t2: intSet) : div intSet
  match t1
    Bin(p1, m1, l1, r1) ->
      val p2 = prefix-val(t2)
      if nomatch(p2, p1, m1) then t1
      else if zero-bit(p2, m1) then bin(p1, m1, difference(l1, t2), r1)
      else bin(p1, m1, l1, difference(r1, t2))
    _ -> t1

/// Compute the difference of two sets (elements in t1 but not in t2).
/// ```
/// difference(from-list([1.int64, 2.int64]), from-list([2.int64, 3.int64])).list == [1.int64]
/// ```
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

/// Check if t1 is a subset of t2.
/// ```
/// is-subset-of(from-list([1.int64]), from-list([1.int64, 2.int64])) == True
/// is-subset-of(from-list([1.int64, 2.int64]), from-list([1.int64])) == False
/// ```
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

// Helper for disjoint when t1 is a Bin and t2 is a subset of t1's prefix.
fun disjoint-collision(t1: intSet, t2: intSet) : div bool
  match t1
    Bin(p1, m1, l1, r1) ->
      val p2 = prefix-val(t2)
      if nomatch(p2, p1, m1) then True
      else if zero-bit(p2, m1) then disjoint(l1, t2)
      else disjoint(r1, t2)
    _ -> True

/// Check if two sets are disjoint (have no elements in common).
/// ```
/// disjoint(from-list([1.int64]), from-list([2.int64])) == True
/// disjoint(from-list([1.int64]), from-list([1.int64, 2.int64])) == False
/// ```
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
