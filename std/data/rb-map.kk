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

pub fun kvalue/map(s: rbmap<k,v>, f: (k, v) -> e x): e rbmap<k,x>
  val Rbmap(tree) = s 
  Rbmap(tree.map(f))

pub fun value/map(s: rbmap<k,v>, f: (v) -> e x): e rbmap<k,x>
  val Rbmap(tree) = s 
  Rbmap(tree.map(f(_)))

pub fun (==)(s1: rbmap<k,v>, s2: rbmap<k,v>, ^?k/order2: (k,k) -> e order2<k>, ^?v/order2: (v,v) -> e order2<v>): e bool
  match order2(s1, s2)
    Eq2 -> True
    _ -> False

pub fun order2(orig1: rbmap<k,v>, orig2: rbmap<k,v>, ^?k/order2: (k,k) -> e order2<k>, ^?v/order2: (v,v) -> e order2<v>): e order2<rbmap<k,v>>
  match orig1
    Rbmap(t1) -> 
      match orig2
        Rbmap(t2) -> order2(t1, t2, orig1, orig2)

fun rec/order2(t1: rbtree<k,v>, t2: rbtree<k,v>, orig1: rbmap<k,v>, orig2: rbmap<k,v>, ^?k/order2: (k,k) -> e order2<k>, ^?v/order2: (v,v) -> e order2<v>): e order2<rbmap<k,v>>
  match t1
    Leaf -> match t2
      Leaf -> Eq2(orig1)
      Node -> Lt2(orig1, orig2)
    Node(_,l1,k1,v1,r1) -> match t2
      Leaf -> Gt2(orig2, orig1)
      Node(_,l2,k2,v2,r2) -> 
        match order2(k1, k2)
          Lt2 -> Lt2(orig1, orig2)
          Gt2 -> Gt2(orig2, orig1)
          Eq2 -> 
            match order2(v1, v2)
              Lt2 -> Lt2(orig1, orig2)
              Gt2 -> Gt2(orig2, orig1)
              Eq2 ->
                match order2(l1, l2, orig1, orig2)
                  Lt2 -> Lt2(orig1, orig2)
                  Gt2 -> Gt2(orig2, orig1)
                  Eq2 -> order2(r1, r2, orig1, orig2)