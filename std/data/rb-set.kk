/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module std/data/rb-set

import std/data/rbtree-bu

pub value struct rbset<k>
  tree: rbtree<k,()>

pub fun set/add(s: rbset<k>, k: k, ^?order2: (k,k) -> e order2<k>): e rbset<k>
  val Rbset(tree) = s 
  Rbset(tree.set(k, ()))

pub fun check/add(s: rbset<k>, k: k, ^?order2: (k,k) -> e order2<k>): e (bool, rbset<k>)
  val Rbset(tree) = s 
  if tree.contains(k) then (False, Rbset(tree))
  else (True, Rbset(tree.set(k, ())))

pub fun contains(s: rbset<k>, k: k, ^?order2: (k,k) -> e order2<k>): e bool
  val Rbset(tree) = s 
  tree.contains(k)

pub fun empty(): rbset<k>
  Rbset(empty())

pub fun list(s: rbset<k>) : list<k>
  val Rbset(tree) = s
  tree.keys

pub fun show(s: rbset<k>, ?k/show: k -> e string): e string
  val Rbset(tree) = s 
  tree.keys.show

pub fun order2(t1: rbtree<k,()>, t2: rbtree<k,()>, orig1: rbset<k>, orig2: rbset<k>,  ^?order2: (k,k) -> e order2<k>): e order2<rbset<k>>
  match t1
    Leaf -> match t2
      Leaf -> Eq2(orig1)
      Node -> Lt2(orig1, orig2)
    Node(_,l1,k1,_,r1) -> match t2
      Leaf -> Gt2(orig2, orig1)
      Node(_,l2,k2,_,r2) -> 
        match order2(k1, k2)
          Lt2 -> Lt2(orig1, orig2)
          Gt2 -> Gt2(orig2, orig1)
          Eq2 -> 
            match order2(l1, l2, orig1, orig2)
              Lt2 -> Lt2(orig1, orig2)
              Gt2 -> Gt2(orig2, orig1)
              Eq2 -> order2(r1, r2, orig1, orig2)