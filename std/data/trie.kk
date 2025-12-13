/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/trie
import std/data/linearmap
import std/core/unsafe
import std/core/undiv

/// A Trie (prefix tree) implementation for strings.
/// Stores a set of strings.
///
/// This implementation uses a Patricia Trie (Radix Tree) structure where
/// edges are labeled with string slices (path segments) to compress the tree.
abstract type trie
  // `path`: The string segment associated with the incoming edge.
  // `path-len`: The length of the path segment (cached for performance).
  // `value`: The full string value stored at this node (if `is-final` is true).
  // `is-final`: Whether a string ends at this node.
  // `children`: A map from the first character of the next segment to the child node.
  Trie(path: string, path-len: int, value: string, is-final: bool, children: linearMap<char,trie>)

/// Create an empty trie.
pub fun empty() : trie
  Trie("", 0, "", False, LinearMap([]))

/// Look up a string in the trie.
/// Returns `Just(s)` if the string `s` is in the trie, `Nothing` otherwise.
pub fun lookup(t: trie, k: string): maybe<string>
  with pretend-no-div
  t.lookup-node(k.slice, k.count)

inline fun lookup-in-children(m: linearMap<char,trie>, is-final: bool, v: string, kn: sslice, kncount: int): div maybe<string>
  match kn.next
    Nothing -> if is-final then Just(v) else Nothing
    Just((char, k')) ->
      val sub = m.lookup(char)
      match sub 
        Nothing -> Nothing
        Just(s) -> lookup-node(s, k', kncount - 1)

fun lookup-node(t: trie, k: sslice, kcount: int): div maybe<string>
  match t
    Trie(p, pcount, v, is-final, m) -> 
      if k.is-prefixed-by(p.slice, kcount, pcount) then
        // TODO: Optimize, drop + prefixed both traverse the same part of the string.
        lookup-in-children(m, is-final, v, k.drop(pcount), kcount - pcount)
      else Nothing

/// Add a string to the trie.
pub fun add(t: trie, s: string): trie
  with pretend-no-div
  insert-node(t, s.slice, s, s.slice.count)

inline fun insert-child(m: linearMap<char,trie>, is-final: bool, p: string, v: string, kchar: char, kn: sslice, ksfull: string, pcount: int, kcount': int): div trie
  val sub = m.lookup(kchar)
  match sub
    Nothing -> Trie(p, pcount, v, is-final, m.set(kchar, Trie(kn.string, kcount' - 1, ksfull, True, LinearMap([]))))
    Just(sub) -> Trie(p, pcount, v, is-final, m.set(kchar, insert-node(sub.pretend-decreasing, kn, ksfull, kcount' - 1)))

fun insert-node(t: trie, k: sslice, original: string, kcount: int): div trie
  match t
    Trie(p, pcount, v, is-final, m) ->
      fun common-prefix(k': sslice, p': sslice, acc: sslice, acccount: int)
        match (k'.next, p'.next)
          (Just((chark, k'')), Just((charp, p''))) -> 
            if chark == charp then
              // Characters match, continue extending the common prefix.
              common-prefix(k''.pretend-decreasing, p'', acc.extend(1), acccount + 1)
            else
              // Characters differ. Split the node here.
              // Create a new parent node with the common prefix `acc`.
              // The old node becomes a child starting with `charp`.
              // The new string becomes a child starting with `chark`.
              val m' = LinearMap([
                (chark, Trie(k''.string, k''.count, original, True, LinearMap([]))),
                (charp, Trie(p''.string, p''.count, v, is-final, m)) 
              ])
              Trie(acc.string, acccount, v.slice.extend(0 - acccount).string, False, m')
          (Just((chark, k'')), Nothing) ->
            // The node's prefix `p` is fully matched by `k`, but `k` has more characters.
            // We need to descend into the children.
            insert-child(m, is-final, p, v, chark, k'', original, pcount, kcount - pcount)
          (Nothing, Just((charp, p''))) ->
            // `k` ended, but the node's prefix `p` has more characters.
            // Split `p`. The new node will have the common prefix (which is all of `k`).
            // The old node becomes a child of the new node.
            // The new node is marked as final with `original`.
            Trie(k.string, kcount, original, True, LinearMap([(charp, Trie(p''.string, pcount - kcount - 1, v, True, m))]))
          (Nothing, Nothing) -> 
            // Exact match. Mark the node as final.
            Trie(p, pcount, v, True, m)
          _ -> impossible()
      common-prefix(k, p.slice, k.truncate, 0)

fun is-prefixed-by(a: sslice, b: sslice, acount: int, bcount: int): bool
  bcount <= acount &&
    a.take(bcount) == b

pub fun trie/show(t: trie): string
  with pretend-no-div
  show-div(t)

pub fun show-div(t: trie): div string
  match t
    Trie(p, pcount, v, is-final, m) -> "Trie(" ++ p.show ++ ", " ++ pcount.show ++ ", " ++ v.show ++ ", " ++ is-final.show ++ " " ++ m.show(?value/show=show-div) ++ ")"
