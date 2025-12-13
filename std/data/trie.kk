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
  t.lookup-node(k.slice, k.count)

fun is-prefixed-by(a: sslice, b: sslice, a-count: int, b-count: int): bool
  b-count <= a-count && a.take(b-count) == b

fun lookup-node(t: trie, k: sslice, kcount: int): maybe<string>
  tail fun lookup-in-children(m: linearMap<char,trie>, is-final: bool, v: string, kn: sslice, kncount: int): maybe<string>
    match kn.next
      Nothing -> if is-final then Just(v) else Nothing
      Just((char, k')) ->
        val sub = m.lookup(char)
        match sub 
          Nothing -> Nothing
          Just(s) -> lookup-node(s.pretend-decreasing, k', kncount - 1)
  match t
    Trie(p, pcount, v, is-final, m) -> 
      if k.is-prefixed-by(p.slice, kcount, pcount) then
        // TODO: In order to optimize this we need to have a slice.split-at(n), drop + prefixed both traverse the same part of the string.
        lookup-in-children(m, is-final, v, k.drop(pcount), kcount - pcount)
      else Nothing

/// Add a string to the trie.
pub fun add(t: trie, s: string): trie
  insert-loop(t, s.slice, s, s.slice.count, Done)

type trieZipper
  Done
  Child(path: string, path-len: int, value: string, is-final: bool, children: linearMap<char, trie>, key: char, up: trieZipper)

fun insert-loop(t: trie, k: sslice, original: string, kcount: int, z: trieZipper): trie
  tail fun zip-up(zipper: trieZipper, t': trie): trie
    match zipper
      Done -> t'
      Child(p, pl, v, f, m, k', up) -> zip-up(up, Trie(p, pl, v, f, m.set(k', t')))
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
              val m' = LinearMap([
                (chark, Trie(k''.string, k''.count, original, True, LinearMap([]))),
                (charp, Trie(p''.string, p''.count, v, is-final, m)) 
              ])
              zip-up(z, Trie(acc.string, acccount, v.slice.extend(0 - acccount).string, False, m'))
          (Just((chark, k'')), Nothing) ->
            // The node's prefix `p` is fully matched by `k`, but `k` has more characters.
            // We need to descend into the children.
            val sub = m.lookup(chark)
            match sub
              Nothing -> 
                val new-child = Trie(k''.string, kcount - pcount - 1, original, True, LinearMap([]))
                zip-up(z, Trie(p, pcount, v, is-final, m.set(chark, new-child)))
              Just(child) ->
                insert-loop(child.pretend-decreasing, k'', original, kcount - pcount - 1, Child(p, pcount, v, is-final, m, chark, z))
          (Nothing, Just((charp, p''))) ->
            // `k` ended, but the node's prefix `p` has more characters.
            // Split `p`.
            val new-child = Trie(p''.string, pcount - kcount - 1, v, True, m)
            val m' = LinearMap([(charp, new-child)])
            zip-up(z, Trie(k.string, kcount, original, True, m'))
          (Nothing, Nothing) -> 
            // Exact match. Mark the node as final.
            zip-up(z, Trie(p, pcount, v, True, m))
          _ -> impossible()
      common-prefix(k, p.slice, k.truncate, 0)

pub fun trie/show(t: trie): string
  with pretend-no-div
  show-div(t)

pub fun show-div(t: trie): div string
  match t
    Trie(p, pcount, v, is-final, m) -> "Trie(" ++ p.show ++ ", " ++ pcount.show ++ ", " ++ v.show ++ ", " ++ is-final.show ++ " " ++ m.show(?value/show=show-div) ++ ")"
