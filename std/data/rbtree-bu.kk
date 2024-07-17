module rbtree-bu

import std/num/int32
pub import std/data/rbtree

pub type zipper<k,v>
  NodeR(color : color, lchild : rbtree<k,v>, key : k, value : v, zip : zipper<k,v>)
  NodeL(color : color, zip : zipper<k,v>, key : k, value : v, rchild : rbtree<k,v>)
  Done

pub fip fun is-red(^t : rbtree<k,v>) : bool
  match t
    Node(Red) -> True
    _         -> False

pub fip fun set-black( t : rbtree<k,v> ) : rbtree<k,v>
  match t
    Node(_,l,x,v,r) -> Node(Black,l,x,v,r)
    Leaf            -> Leaf

// Cormen et al. textbook version
pub fip fun rebuild(z : zipper<k,v>, t : rbtree<k,v>): rbtree<k,v>
  match z
    NodeR(c, l, k, v, z1) -> rebuild(z1, Node(c, l, k, v, t))
    NodeL(c, z1, k, v, r) -> rebuild(z1, Node(c, t, k, v, r))
    Done -> t.set-black

pub fip fun to-node( root : root<k,v> ) : rbtree<k,v>
  match root
    Root(c,l,k,v,r) -> Node(c,l,k,v,r)

pub fip fun balance( z : zipper<k,v>, t : root<k,v> ) : rbtree<k,v>
  match z
    NodeR(Red, l1, k1, v1, z1) -> match z1
      NodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance(z2, Root(Red, l2.set-black, k2, v2, Node(Black, l1, k1, v1, t.to-node) ))
        else rebuild(z2, Node(Black, Node(Red,l2,k2,v2,l1), k1, v1, t.to-node))
      NodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance(z2, Root(Red, Node(Black,l1,k1,v1,t.to-node), k2, v2, r2.set-black))
        else match t
          Root(_, l, k, v, r) -> rebuild(z2, Node(Black, Node(Red,l1,k1,v1,l), k, v, Node(Red,r,k2,v2,r2)))
      Done -> Node(Black, l1, k1, v1, t.to-node)
    NodeL(Red, z1, k1, v1, r1) -> match z1
      NodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance(z2, Root(Red, Node(Black, t.to-node, k1, v1, r1), k2, v2, r2.set-black ))
        else rebuild(z2, Node(Black, t.to-node, k1, v1, Node(Red,r1,k2,v2,r2)))
      NodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance(z2, Root(Red, l2.set-black, k2, v2, Node(Black,t.to-node,k1,v1,r1) ))
        else match t
          Root(_, l, k, v, r) -> rebuild(z2, Node(Black, Node(Red,l2,k2,v2,l), k, v, Node(Red,r,k1,v1,r1)))
      Done -> Node(Black, t.to-node, k1, v1, r1)
    z -> rebuild(z, t.to-node)


pub fip fun balance-root( z : zipper<k,v>, t : root<k,v> ) : root<k,v>
  match z
    NodeR(Red, l1, k1, v1, z1) -> match z1
      NodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance-root(z2, Root(Red, l2.set-black, k2, v2, Node(Black, l1, k1, v1, t.to-node) ))
        else rebuild-root(z2, Root(Black, Node(Red,l2,k2,v2,l1), k1, v1, t.to-node))
      NodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance-root(z2, Root(Red, Node(Black,l1,k1,v1,t.to-node), k2, v2, r2.set-black))
        else match t
          Root(_, l, k, v, r) -> rebuild-root(z2, Root(Black, Node(Red,l1,k1,v1,l), k, v, Node(Red,r,k2,v2,r2)))
      Done -> Root(Black, l1, k1, v1, t.to-node)
    NodeL(Red, z1, k1, v1, r1) -> match z1
      NodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance-root(z2, Root(Red, Node(Black, t.to-node, k1, v1, r1), k2, v2, r2.set-black ))
        else rebuild-root(z2, Root(Black, t.to-node, k1, v1, Node(Red,r1,k2,v2,r2)))
      NodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance-root(z2, Root(Red, l2.set-black, k2, v2, Node(Black,t.to-node,k1,v1,r1) ))
        else match t
          Root(_, l, k, v, r) -> rebuild-root(z2, Root(Black, Node(Red,l2,k2,v2,l), k, v, Node(Red,r,k1,v1,r1)))
      Done -> Root(Black, t.to-node, k1, v1, r1)
    z -> rebuild-root(z, t)

pub fip(1) fun zip/set(t : rbtree<k,v>, key : k, v : v, z : zipper<k,v>, ^?order2: (k,k) -> order2<k>) : rbtree<k,v>
  match t
    Node(c, l, kx, vx, r) ->
      match order2(key, kx)
        Lt2(ki, kj) -> set(l, ki, v, NodeL(c, z, kj, vx, r))
        Gt2(kj, ki) -> set(r, ki, v, NodeR(c, l, kj, vx, z))
        Eq2(ki) -> rebuild(z, Node(c, l, ki, v, r)) // Actually override the value, no balancing needed
    Leaf -> balance(z, Root(Red, Leaf, key, v, Leaf)) // Insert a new node and balance

pub fip(1) fun zip/remove(t: rbtree<k,v>, key: k, z: zipper<k,v>, ^?order2: (k,k) -> order2<k>) : rbtree<k,v>
  match t
    Node(c, l, kx, vx, r) ->
      match order2(key, kx)
        Lt2(ki, kj) -> remove(l, ki, NodeL(c, z, kj, vx, r))
        Gt2(kj, ki) -> remove(r, ki, NodeR(c, l, kj, vx, z))
        Eq2(_) -> do-remove(c, z, l, r) // Actually override the value, no balancing needed
    Leaf -> rebuild(z, Leaf) // Not found

pub inline fun do-remove(c: color, z: zipper<k,v>, l: rbtree<k,v>, r: rbtree<k,v>): rbtree<k,v>
  if l.is-leaf then 
    if r.is-leaf then 
      // No children (just replace with leaf)
      //  - if the node to delete was red this doesn't change the black height
      if c.is-red then rebuild(z, Leaf)
      //  - if the node to delete was black we need to rebalance
      else 
        remove-rebalance(z, Leaf, True)
    else rebuild(z, r.set-black) // Only has one child
  elif r.is-leaf then
    rebuild(z, l.set-black) // One child
  else
    do-remove-inorder(c, z, l, r, Done)

pub fip fun rebuild-root(z : zipper<k,v>, t : root<k,v>): root<k,v>
  match z
    NodeR(c, l, k, v, z1) -> rebuild-root(z1, Root(c, l, k, v, t.to-node))
    NodeL(c, z1, k, v, r) -> rebuild-root(z1, Root(c, t.to-node, k, v, r))
    Done -> t.set-black

pub fip fun root/set-black( t : root<k,v> ) : root<k,v>
  match t
    Root(_,l,x,v,r) -> Root(Black,l,x,v,r)

pub inline fun do-remove-inorder(c: color, z: zipper<k,v>, l: rbtree<k,v>, r: rbtree<k,v>, rz: zipper<k,v>): rbtree<k,v>
  match r
    Node(rc, Leaf, k, v, rr) -> // Inorder found
      if rc.is-red then rebuild(z, rebuild(rz, Node(c, l, k, v, rr)))
      else balance(z, balance-root(rz, Root(c, l, k, v, rr)))
    Node(rc, rl, k, v, rr) -> // Inorder search 
      do-remove-inorder(c, z, l, rl, NodeL(rc, rz, k, v, rr))
    Leaf -> Leaf // Should never be reached due to invariants

pub fip(1) fun bu/set(t: rbtree<k,v>, key: k, value: v, ^?order2: (k,k) -> order2<k>) : rbtree<k,v>
  t.set(key, value, Done)

pub fip(1) fun bu/remove(t: rbtree<k,v>, key: k, ^?order2: (k,k) -> order2<k>) : rbtree<k,v>
  t.remove(key, Done)