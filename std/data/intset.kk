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
pub tail fun member(t: intSet, x: int64) : bool
  match t
    ISNil -> False
    Tip(y) -> x == y
    Bin(p, m, l, r) ->
      if nomatch(x, p, m) then False
      else if zero-bit(x, m) then member(l, x)
      else member(r, x)

// Smart constructor that avoids creating Bins with empty children.
inline fun bin(p: int64, m: int64, l: intSet, r: intSet) : intSet
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

// Tail-recursive fold using a zipper to simulate the stack.
fun fold-loop(t: intSet, acc: a, ^f: (a, int64) -> a, z: intSetZipper) : a
  // Move up the zipper, processing the other branch if necessary.
  tail fun fold-up(z1: intSetZipper, acc1: a, ^f1: (a, int64) -> a) : a
    match z1
      Done -> acc1
      BinL(_, _, up, r) -> fold-loop(r.pretend-decreasing, acc1, f1, up)
      BinR(_, _, l, up) -> fold-loop(l.pretend-decreasing, acc1, f1, up)
  match t
    ISNil -> fold-up(z.pretend-decreasing, acc, f)
    Tip(x) -> fold-up(z.pretend-decreasing, f(acc, x), f)
    Bin(p, m, l, r) -> fold-loop(l.pretend-decreasing, acc, f, BinL(p, m, z, r))

/// Create a set from a list of integers.
pub fun from-list(xs: list<int64>) : intSet
  xs.foldl(ISNil, insert)

// Zipper for tail-recursive boolean checks on two trees (e.g. equality, subset, disjoint).
// Stores pending checks for right subtrees.
type checkZipper
  CheckDone
  CheckRight(r1: intSet, r2: intSet, up: checkZipper)

/// Check if two sets are equal.
pub fun (==)(t1: intSet, t2: intSet) : bool
  eq-loop(t1, t2, CheckDone)

fun eq-loop(t1: intSet, t2: intSet, z: checkZipper): bool
  tail fun eq-zip-up(z1: checkZipper) : bool
    match z1
      CheckDone -> True
      CheckRight(r1, r2, up) -> eq-loop(r1.pretend-decreasing, r2.pretend-decreasing, up)
  match t1
    ISNil -> match t2
      ISNil -> eq-zip-up(z)
      _ -> False
    Tip(x) -> match t2
      Tip(y) -> if x == y then eq-zip-up(z) else False
      _ -> False
    Bin(p1, m1, l1, r1) -> match t2
      Bin(p2, m2, l2, r2) ->
        if p1 == p2 && m1 == m2 then
          eq-loop(l1.pretend-decreasing, l2.pretend-decreasing, CheckRight(r1, r2, z))
        else False
      _ -> False

/// Check if two sets are not equal.
pub fun (!=)(t1: intSet, t2: intSet) : bool
  neq-loop(t1, t2, CheckDone)

fun neq-loop(t1: intSet, t2: intSet, z: checkZipper) : bool
  tail fun neq-zip-up(z1: checkZipper) : bool
    match z1
      CheckDone -> False
      CheckRight(r1, r2, up) -> neq-loop(r1.pretend-decreasing, r2.pretend-decreasing, up)
  match t1
    ISNil -> match t2
      ISNil -> neq-zip-up(z)
      _ -> True
    Tip(x) -> match t2
      Tip(y) -> if x == y then neq-zip-up(z) else True
      _ -> True
    Bin(p1, m1, l1, r1) -> match t2
      Bin(p2, m2, l2, r2) ->
        if p1 == p2 && m1 == m2 then
          neq-loop(l1.pretend-decreasing, l2.pretend-decreasing, CheckRight(r1, r2, z))
        else True
      _ -> True

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

/// Compute the intersection of two sets.
/// ```
/// intersection(from-list([1.int64, 2.int64]), from-list([2.int64, 3.int64])).list == [2.int64]
/// ```
pub fun intersection(t1: intSet, t2: intSet) : div intSet
  intersection-loop(t1, t2, IntDone)

// Zipper for tail-recursive intersection.
type intersectZipper
  IntDone
  // Processing left children (l1, l2). Preserve right children (r1, r2) to process next.
  IntSplit(pre: int64, msk: int64, r1: intSet, r2: intSet, up: intersectZipper)
  // Processing right children (r1, r2). Preserve result of left side (l_res).
  IntSplitRight(pre: int64, msk: int64, l_res: intSet, up: intersectZipper)

fun intersection-loop(t1: intSet, t2: intSet, z: intersectZipper) : intSet
  tail fun intersect-zip-up(z1: intersectZipper, t: intSet) : intSet
    match z1
      IntDone -> t
      IntSplit(p, m, r1, r2, up) ->
        intersection-loop(r1.pretend-decreasing, r2.pretend-decreasing, IntSplitRight(p, m, t, up))
      IntSplitRight(p, m, l_res, up) ->
        intersect-zip-up(up, bin(p, m, l_res, t))
  match t1
    ISNil -> intersect-zip-up(z, ISNil)
    Tip(x) -> 
      if member(t2, x) then intersect-zip-up(z, t1)
      else intersect-zip-up(z, ISNil)
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> intersect-zip-up(z, ISNil)
        Tip(x) -> 
          if member(t1, x) then intersect-zip-up(z, t2)
          else intersect-zip-up(z, ISNil)
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then
            if nomatch(p2, p1, m1) then intersect-zip-up(z, ISNil)
            else if zero-bit(p2, m1) then intersection-loop(l1.pretend-decreasing, t2.pretend-decreasing, z)
            else intersection-loop(r1.pretend-decreasing, t2.pretend-decreasing, z)
          else if shorter(m2, m1) then
            if nomatch(p1, p2, m2) then intersect-zip-up(z, ISNil)
            else if zero-bit(p1, m2) then intersection-loop(t1.pretend-decreasing, l2.pretend-decreasing, z)
            else intersection-loop(t1.pretend-decreasing, r2.pretend-decreasing, z)
          else if p1 == p2 then
            intersection-loop(l1.pretend-decreasing, l2.pretend-decreasing, IntSplit(p1, m1, r1, r2, z))
          else
            intersect-zip-up(z, ISNil)


/// Compute the difference of two sets (elements in t1 but not in t2).
/// Implemented as a tail-recursive traversal with short-circuiting.
/// ```
/// difference(from-list([1.int64, 2.int64]), from-list([2.int64, 3.int64])).list == [1.int64]
/// ```
pub fun difference(t1: intSet, t2: intSet) : intSet
  difference-loop(t1, t2, DifDone)

// Zipper for tail-recursive difference.
// This tracks the state of the traversal as we descend into the trees.
type diffZipper
  // Finished processing.
  DifDone
  // Processing left child of t1; t2 was wholly contained in left prefix.
  // Preserve right child of t1 to reattach later.
  DifPreserveR(pre: int64, msk: int64, right: intSet, up: diffZipper)
  // Processing right child of t1; t2 was wholly contained in right prefix.
  // Preserve left child of t1 to reattach later.
  DifPreserveL(pre: int64, msk: int64, left: intSet, up: diffZipper)
  // Processing left children (l1, l2) after a prefix match.
  // Preserve right children (r1, r2) to process next.
  DifSplit(pre: int64, msk: int64, r1: intSet, r2: intSet, up: diffZipper)
  // Processing right children (r1, r2) after left side completed.
  // Preserve result of left side (l_res) to combine with right result.
  DifSplitRight(pre: int64, msk: int64, l_res: intSet, up: diffZipper)


// Tail-recursive difference loop.
// Maintains the invariant that we are computing `difference(t1, t2)`
// and will plug the result into zipper `z`.
fun difference-loop(t1: intSet, t2: intSet, z: diffZipper) : intSet
  // Reconstruct the tree by zipping up from the current result `t`.
  tail fun diff-zip-up(z1: diffZipper, t: intSet) : intSet
    match z1
      DifDone -> t
      DifPreserveR(p, m, r, up) -> diff-zip-up(up, bin(p, m, t, r))
      DifPreserveL(p, m, l, up) -> diff-zip-up(up, bin(p, m, l, t))
      DifSplit(p, m, r1, r2, up) ->
        // Left side finished (result t), now process right side (r1, r2)
        difference-loop(r1.pretend-decreasing, r2.pretend-decreasing, DifSplitRight(p, m, t, up))
      DifSplitRight(p, m, l_res, up) ->
        // Right side finished (result t), combine with left result (l_res)
        diff-zip-up(up, bin(p, m, l_res, t))
  match t1
    ISNil -> diff-zip-up(z, ISNil)
    Tip(x) -> 
      if member(t2, x) then diff-zip-up(z, ISNil)
      else diff-zip-up(z, t1)
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> diff-zip-up(z, t1)
        Tip(x) -> diff-zip-up(z, remove(t1, x))
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then
            // t1 branches before t2; check if t2 is wholly in one subtree of t1
            val p2_ = prefix-val(t2)
            if nomatch(p2_, p1, m1) then diff-zip-up(z, t1)
            else if zero-bit(p2_, m1) then difference-loop(l1.pretend-decreasing, t2.pretend-decreasing, DifPreserveR(p1, m1, r1, z))
            else difference-loop(r1.pretend-decreasing, t2.pretend-decreasing, DifPreserveL(p1, m1, l1, z))
          else if shorter(m2, m1) then
            // t2 branches before t1; descend into the appropriate subtree of t1
            val p1_ = prefix-val(t1)
            if nomatch(p1_, p2, m2) then diff-zip-up(z, t1)
            else if zero-bit(p1_, m2) then difference-loop(t1.pretend-decreasing, l2.pretend-decreasing, z)
            else difference-loop(t1.pretend-decreasing, r2.pretend-decreasing, z)
          else if p1 == p2 then
            // Same prefix and mask; recursively process both subtrees
            difference-loop(l1.pretend-decreasing, l2.pretend-decreasing, DifSplit(p1, m1, r1, r2, z))
          else
            // Different prefixes at same level; trees are disjoint
            diff-zip-up(z, t1)

/// Check if t1 is a subset of t2.
/// ```
/// is-subset-of(from-list([1.int64]), from-list([1.int64, 2.int64])) == True
/// is-subset-of(from-list([1.int64, 2.int64]), from-list([1.int64])) == False
/// ```
pub fun is-subset-of(t1: intSet, t2: intSet) : bool
  subset-loop(t1, t2, CheckDone)

// Tail-recursive subset loop.
tail fun subset-loop(t1: intSet, t2: intSet, z: checkZipper) : bool
  match t1
    ISNil -> match z
      CheckDone -> True
      CheckRight(r1, r2, up) -> subset-loop(r1.pretend-decreasing, r2.pretend-decreasing, up)
    Tip(x) -> if member(t2, x) then match z
      CheckDone -> True
      CheckRight(r1, r2, up) -> subset-loop(r1.pretend-decreasing, r2.pretend-decreasing, up)
    else False
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> False
        Tip(_) -> False
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then False
          else if shorter(m2, m1) then
            val p1_ = prefix-val(t1)
            if nomatch(p1_, p2, m2) then False
            else if zero-bit(p1_, m2) then subset-loop(t1.pretend-decreasing, l2.pretend-decreasing, z)
            else subset-loop(t1.pretend-decreasing, r2.pretend-decreasing, z)
          else if p1 == p2 then
            subset-loop(l1.pretend-decreasing, l2.pretend-decreasing, CheckRight(r1, r2, z))
          else
            False

/// Check if two sets are disjoint (have no elements in common).
/// ```
/// disjoint(from-list([1.int64]), from-list([2.int64])) == True
/// disjoint(from-list([1.int64]), from-list([1.int64, 2.int64])) == False
/// ```
pub fun disjoint(t1: intSet, t2: intSet) : bool
  disjoint-loop(t1, t2, CheckDone)

// Tail-recursive disjoint loop.
fun disjoint-loop(t1: intSet, t2: intSet, z: checkZipper) : bool
  // Continue with the next check in the zipper for disjoint.
  tail fun disjoint-zip-up(z1: checkZipper) : bool
    match z1
      CheckDone -> True
      CheckRight(r1, r2, up) -> disjoint-loop(r1.pretend-decreasing, r2.pretend-decreasing, up)
  match t1
    ISNil -> disjoint-zip-up(z)
    Tip(x) -> if !member(t2, x) then disjoint-zip-up(z) else False
    Bin(p1, m1, l1, r1) ->
      match t2
        ISNil -> disjoint-zip-up(z)
        Tip(x) -> if !member(t1, x) then disjoint-zip-up(z) else False
        Bin(p2, m2, l2, r2) ->
          if shorter(m1, m2) then
            val p2_ = prefix-val(t2)
            if nomatch(p2_, p1, m1) then disjoint-zip-up(z)
            else if zero-bit(p2_, m1) then disjoint-loop(l1.pretend-decreasing, t2.pretend-decreasing, z)
            else disjoint-loop(r1.pretend-decreasing, t2.pretend-decreasing, z)
          else if shorter(m2, m1) then
            val p1_ = prefix-val(t1)
            if nomatch(p1_, p2, m2) then disjoint-zip-up(z)
            else if zero-bit(p1_, m2) then disjoint-loop(t1.pretend-decreasing, l2.pretend-decreasing, z)
            else disjoint-loop(t1.pretend-decreasing, r2.pretend-decreasing, z)
          else
            if p1 != p2 then disjoint-zip-up(z)
            else disjoint-loop(l1.pretend-decreasing, l2.pretend-decreasing, CheckRight(r1, r2, z))
