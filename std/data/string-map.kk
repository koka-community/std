/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/string-map
import std/data/linear-map
import std/core/unsafe
import std/core/undiv
import std/core/maybe
import std/core/show

/// A Map from strings to values based on a Patricia Trie (Radix Tree).
abstract type string-map<v>
  // `path`: The string segment associated with the incoming edge.
  // `path-len`: The length of the path segment (cached for performance).
  // `value`: The value stored at this node (if any).
  // `children`: A map from the first character of the next segment to the child node.
  Node(path: string, path-len: int, value: maybe<v>, children: linear-map<char, string-map<v>>)

/// Create an empty map.
pub fun empty() : string-map<v>
  Node("", 0, Nothing, LinearMap([]))

/// Look up a value in the map.
pub fun lookup(t: string-map<v>, k: string): maybe<v>
  t.lookup-node(k.slice, k.count)

fun is-prefixed-by(a: sslice, b: sslice, a-count: int, b-count: int): bool
  b-count <= a-count && a.take(b-count) == b

fun lookup-node(t: string-map<v>, k: sslice, kcount: int): maybe<v>
  tail fun lookup-in-children(m: linear-map<char,string-map<v>>, value: maybe<v>, kn: sslice, kncount: int): maybe<v>
    match kn.next
      Nothing -> value
      Just((char, k')) ->
        val sub = m.lookup(char)
        match sub 
          Nothing -> Nothing
          Just(s) -> lookup-node(s.pretend-decreasing, k', kncount - 1)
  match t
    Node(p, pcount, v, m) -> 
      if k.is-prefixed-by(p.slice, kcount, pcount) then
        lookup-in-children(m, v, k.drop(pcount), kcount - pcount)
      else Nothing

/// Set a value in the map.
pub fun set(t: string-map<v>, key: string, value: v): string-map<v>
  insert-loop-with(t, key.slice, fn(_) value, key.count, Done)

/// Update a value in the map using a function that takes the old value.
pub fun update(t: string-map<v>, key: string, f: (maybe<v>) -> e v): e string-map<v>
  insert-loop-with(t, key.slice, f, key.count, Done)

type zipper<v>
  Done
  Child(path: string, path-len: int, value: maybe<v>, children: linear-map<char, string-map<v>>, key: char, up: zipper<v>)

fun insert-loop-with(t: string-map<v>, k: sslice, value-fn: (maybe<v>) -> e v, kcount: int, z: zipper<v>): e string-map<v>
  tail fun zip-up(zipper: zipper<v>, t': string-map<v>): string-map<v>
    match zipper
      Done -> t'
      Child(p, pl, v, m, k', up) -> zip-up(up, Node(p, pl, v, m.set(k', t')))
  match t
    Node(p, pcount, v, m) ->
      fun common-prefix(k': sslice, p': sslice, acc: sslice, acc-count: int)
        match (k'.next, p'.next)
          (Just((chark, k'')), Just((charp, p''))) -> 
            if chark == charp then
              // Characters match, continue extending the common prefix.
              common-prefix(k''.pretend-decreasing, p'', acc.extend(1), acc-count + 1)
            else
              // Characters differ. Split the node here.
              val m' = LinearMap([
                (chark, Node(k''.string, k''.count, Just(value-fn(Nothing)), LinearMap([]))),
                (charp, Node(p''.string, p''.count, v, m)) 
              ])
              zip-up(z, Node(acc.string, acc-count, Nothing, m'))
          (Just((chark, k'')), Nothing) ->
            // The node's prefix `p` is fully matched by `k`, but `k` has more characters.
            // We need to descend into the children.
            val sub = m.lookup(chark)
            match sub
              Nothing -> 
                val new-child = Node(k''.string, kcount - pcount - 1, Just(value-fn(Nothing)), LinearMap([]))
                zip-up(z, Node(p, pcount, v, m.set(chark, new-child)))
              Just(child) ->
                insert-loop-with(child.pretend-decreasing, k'', value-fn, kcount - pcount - 1, Child(p, pcount, v, m, chark, z))
          (Nothing, Just((charp, p''))) ->
            // `k` ended, but the node's prefix `p` has more characters.
            // Split `p`.
            val new-child = Node(p''.string, pcount - kcount - 1, v, m)
            val m' = LinearMap([(charp, new-child)])
            zip-up(z, Node(k.string, kcount, Just(value-fn(Nothing)), m'))
          (Nothing, Nothing) -> 
            // Exact match. Update the value.
            zip-up(z, Node(p, pcount, Just(value-fn(v)), m))
          _ -> impossible()
      common-prefix(k, p.slice, k.truncate, 0)

pub fun show(t: string-map<v>, ?show: (v) -> e string): e string
  with pretend-no-div
  show-div(t, ?show=fn(v) mask<div>{show(v)})

fun show-div(t: string-map<v>, ?show: (v) -> <div|e> string): <div|e> string
  match t
    Node(p, pcount, v, m) -> 
      val ps = p.show
      val pcs = pcount.show
      val vs = maybe/show(v)
      val ms = m.show(?value/show=show-div)
      "Node(" ++ ps ++ ", " ++ pcs ++ ", " ++ vs ++ ", " ++ ms ++ ")"
