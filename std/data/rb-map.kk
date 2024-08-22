/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/rb-map

import std/data/rbtree-bu

pub value struct rbmap<k,v>
  tree: rbtree<k,v>

pub fun set(s: rbmap<k,v>, k: k, v: v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  val Rbmap(tree) = s 
  Rbmap(tree.set(k, v))

pub fun add(s: rbmap<k,v>, k: k, v: v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  val Rbmap(tree) = s 
  Rbmap(tree.add(k, v))

pub fun insert(s: rbmap<k,v>, k: k, f: (maybe<v>) -> e v, ^?order2: (k,k) -> e order2<k>): e rbmap<k,v>
  val Rbmap(tree) = s 
  Rbmap(tree.insert(k, f))

pub fun contains(s: rbmap<k,v>, k: k, ^?order2: (k,k) -> e order2<k>): e bool
  val Rbmap(tree) = s 
  tree.contains(k)

pub fun empty(): rbmap<k,v>
  Rbmap(empty())

pub fun list(s: rbmap<k,v>) : list<(k,v)>
  val Rbmap(tree) = s
  tree.list

pub fun keys(s: rbmap<k,v>) : list<k>
  val Rbmap(tree) = s
  tree.keys

pub fun values(s: rbmap<k,v>) : list<v>
  val Rbmap(tree) = s
  tree.values

pub fun lookup(s: rbmap<k,v>, k: k, ^?order2: (k,k) -> e order2<k>): e maybe<v>
  val Rbmap(tree) = s 
  tree.lookup(k)

pub fun show(s: rbmap<k,v>, ?k/show: k -> e string, ?v/show: v -> e string): e string
  val Rbmap(tree) = s 
  tree.list.show