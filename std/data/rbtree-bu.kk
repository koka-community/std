// Copied and derived from https://github.com/koka-lang/koka/tree/artifact-pldi24/test/artifact/pldi24
module rbtree-bu

import std/num/int32
pub import std/data/rbtree
import std/data/tree-common
import std/core/undiv
import std/core-extras

pub fip fun balance( z : zipper<k,v>, t : root<k,v> ) : rbtree<k,v>
  match z
    ZNodeR(Red, l1, k1, v1, z1) -> match z1
      ZNodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance(z2, Root(Red, l2.set-black, k2, v2, Node(Black, l1, k1, v1, t.to-node) ))
        else rebuild(z2, Node(Black, Node(Red,l2,k2,v2,l1), k1, v1, t.to-node))
      ZNodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance(z2, Root(Red, Node(Black,l1,k1,v1,t.to-node), k2, v2, r2.set-black))
        else match t
          Root(_, l, k, v, r) -> rebuild(z2, Node(Black, Node(Red,l1,k1,v1,l), k, v, Node(Red,r,k2,v2,r2)))
      Done -> Node(Black, l1, k1, v1, t.to-node)
    ZNodeL(Red, z1, k1, v1, r1) -> match z1
      ZNodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance(z2, Root(Red, Node(Black, t.to-node, k1, v1, r1), k2, v2, r2.set-black ))
        else rebuild(z2, Node(Black, t.to-node, k1, v1, Node(Red,r1,k2,v2,r2)))
      ZNodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance(z2, Root(Red, l2.set-black, k2, v2, Node(Black,t.to-node,k1,v1,r1) ))
        else match t
          Root(_, l, k, v, r) -> rebuild(z2, Node(Black, Node(Red,l2,k2,v2,l), k, v, Node(Red,r,k1,v1,r1)))
      Done -> Node(Black, t.to-node, k1, v1, r1)
    z -> rebuild(z, t.to-node)

pub fip(1) fun zip/set(t : rbtree<k,v>, key : k, v : v, z : zipper<k,v>, ^?order2: (k,k) -> e order2<k>) : e rbtree<k,v>
  match t
    Node(c, l, kx, vx, r) ->
      match order2(key, kx)
        Lt2(ki, kj) -> set(l, ki, v, ZNodeL(c, z, kj, vx, r))
        Gt2(kj, ki) -> set(r, ki, v, ZNodeR(c, l, kj, vx, z))
        Eq2(ki) -> rebuild(z, Node(c, l, ki, v, r)) // Actually override the value, no balancing needed
    Leaf -> balance(z, Root(Red, Leaf, key, v, Leaf)) // Insert a new node and balance

pub fbip(1) fun zip/add(t : rbtree<k,v>, key : k, v : v, z : zipper<k,v>, ^?order2: (k,k) -> e order2<k>) : e rbtree<k,v>
  match t
    Node(c, l, kx, vx, r) ->
      match order2(key, kx)
        Lt2(ki, kj) -> add(l, ki, v, ZNodeL(c, z, kj, vx, r))
        Gt2(kj, ki) -> add(r, ki, v, ZNodeR(c, l, kj, vx, z))
        Eq2(kx') -> rebuild(z, Node(c,l,kx',vx,r)) // No overriding
    Leaf -> balance(z, Root(Red, Leaf, key, v, Leaf)) // Insert a new node and balance

// Take a function that is called with Just the old value if it exists, or Nothing if it doesn't
pub fip(1) fun zip/insert(t : rbtree<k,v>, key : k, z : zipper<k,v>, ^f: (maybe<v>) -> e v, ^?order2: (k,k) -> e order2<k>) : e rbtree<k,v>
  match t
    Node(c, l, kx, vx, r) ->
      match order2(key, kx)
        Lt2(ki, kj) -> insert(l, ki, ZNodeL(c, z, kj, vx, r), f)
        Gt2(kj, ki) -> insert(r, ki, ZNodeR(c, l, kj, vx, z), f)
        Eq2(kx') -> rebuild(z, Node(c,l,kx',f(Just(vx)),r)) // No overriding
    Leaf -> balance(z, Root(Red, Leaf, key, f(Nothing), Leaf)) // Insert a new node and balance

pub fbip(1) fun bu/set(t: rbtree<k,v>, key: k, value: v, ^?order2: (k,k) -> e order2<k>): e rbtree<k,v>
  t.set(key, value, Done)

pub fbip(1) fun bu/add(t: rbtree<k,v>, key: k, value: v, ^?order2: (k,k) -> e order2<k>): e rbtree<k,v>
  t.add(key, value, Done)

pub fbip(1) fun bu/insert(t: rbtree<k,v>, key: k, f: (maybe<v>) -> e v, ^?order2: (k,k) -> e order2<k>): e rbtree<k,v>
  t.insert(key, Done, f)

pub fip fun balance-root( z : zipper<k,v>, t : root<k,v> ) : root<k,v>
  match z
    ZNodeR(Red, l1, k1, v1, z1) -> match z1
      ZNodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance-root(z2, Root(Red, l2.set-black, k2, v2, Node(Black, l1, k1, v1, t.to-node) ))
        else rebuild-root(z2, Root(Black, Node(Red,l2,k2,v2,l1), k1, v1, t.to-node))
      ZNodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance-root(z2, Root(Red, Node(Black,l1,k1,v1,t.to-node), k2, v2, r2.set-black))
        else match t
          Root(_, l, k, v, r) -> rebuild-root(z2, Root(Black, Node(Red,l1,k1,v1,l), k, v, Node(Red,r,k2,v2,r2)))
      Done -> Root(Black, l1, k1, v1, t.to-node)
    ZNodeL(Red, z1, k1, v1, r1) -> match z1
      ZNodeL(_,z2,k2,v2,r2) -> // black
        if is-red(r2) then balance-root(z2, Root(Red, Node(Black, t.to-node, k1, v1, r1), k2, v2, r2.set-black ))
        else rebuild-root(z2, Root(Black, t.to-node, k1, v1, Node(Red,r1,k2,v2,r2)))
      ZNodeR(_,l2,k2,v2,z2) -> // black
        if is-red(l2) then balance-root(z2, Root(Red, l2.set-black, k2, v2, Node(Black,t.to-node,k1,v1,r1) ))
        else match t
          Root(_, l, k, v, r) -> rebuild-root(z2, Root(Black, Node(Red,l2,k2,v2,l), k, v, Node(Red,r,k1,v1,r1)))
      Done -> Root(Black, t.to-node, k1, v1, r1)
    z -> rebuild-root(z, t)

pub fbip(1) fun zip/remove(t: rbtree<k,v>, key: k, z: zipper<k,v>, ^?order2: (k,k) -> order2<k>, ?k/show: (k) -> string, ?v/show: (v) -> string) : exn rbtree<k,v>
  match t
    Node(c, l, kx, vx, r) ->
      match order2(key, kx)
        Lt2(ki, kj) -> remove(l, ki, ZNodeL(c, z, kj, vx, r))
        Gt2(kj, ki) -> remove(r, ki, ZNodeR(c, l, kj, vx, z))
        Eq2(_) -> do-remove(c, z, l, r) // Actually do the removing
    Leaf -> rebuild(z, Leaf) // Not found - Figure 3

pub inline fun db-balance(t: rbtree<k,v>, is-double-black: bool): rbtree<k,v>
  if is-double-black then
    match t
      Node(_, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z, vz, d) ->
        Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      Node(_, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z, vz, d) ->
        Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      _ -> db-balance(t.pretend-decreasing, False)
  else
    match t
      Node(Black, Node(Red, Node(Red, a, x, vx, b), y, vy, c), z, vz, d)
        -> Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      Node(Black, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z, vz, d)
        -> Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      Node(Black, a, x, vx, Node(Red, Node(Red, b, y, vy, c), z, vz, d))
        -> Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      Node(Black, a, x, vx, Node(Red, b, y, vy, Node(Red, c, z, vz, d)))
        -> Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      _ -> t

// TODO: the zipper needs to rerotate?
pub fun db-rotate(z: zipper<k,v>, t: rbtree<k,v>, is-double-black: bool, ?k/show: (k) -> string, ?v/show: (v) -> string): rbtree<k,v>
  match z
    // First case Figure 6, t is x, z is y, double black is discharged and we can just rebuild normally
    ZNodeL(Red, z', y, vy, Node(Black, c, kz, vz, d)) | is-double-black ->
      trace("Firsta")
      val x' = Node(Black, Node(Red, t, y, vy, c), kz, vz, d)
      trace(x'.show)
      val balanced = db-balance(x', False)
      trace(balanced.show)
      z'.rebuild(balanced)
    ZNodeR(Red, Node(Black, a, x, vx, b), y, vy, z') | is-double-black ->
      trace("Firstb")
      z'.rebuild(db-balance(Node(Black, a, x, vx, Node(Red, b, y, vy, t)), False))
    // Second case Figure 7, t is x, z is y
    ZNodeL(Black, z', y, vy, Node(Black, c, kz, vz, d)) | is-double-black ->
      trace("Seconda")
      z'.rebuild(db-balance(Node(Black, Node(Red, t, y, vy, c), kz, vz, d), True))
    ZNodeR(Black, Node(Black, a, x, vx, b), y, vy, z') | is-double-black ->
      trace("Secondb")
      z'.rebuild(db-balance(Node(Black, a, x, vx, Node(Red, b, y, vy, t)), True))
    // Third case Figure 9, t is w, z is x
    ZNodeL(Black, z', x, vx, Node(Red, Node(Black, c, y, vy, d), kz, vz, e)) ->
      trace("Thirda")
      z'.rebuild(Node(Black, db-balance(Node(Black, Node(Red, t, x, vx, c), y, vy, d), False), kz, vz, e))
    ZNodeR(Black, Node(Red, a, w, vw, Node(Black, b, x, vx, c)), y, vy, z') ->
      trace("Thirdb")
      z'.rebuild(Node(Black, a, w, vw, db-balance(Node(Black, b, x, vx, Node(Red, c, y, vy, t)), False)))
    _ -> z.rebuild(t)


pub fun do-remove(c: color, z: zipper<k,v>, l: rbtree<k,v>, r: rbtree<k,v>, ?k/show: (k) -> string, ?v/show: (v) -> string): rbtree<k,v>
  if l.is-leaf then 
    if r.is-leaf then 
      // No children (just replace with leaf)
      //  - if the node to delete was red this doesn't change the black height
      if c.is-red then rebuild(z, Leaf) // Figure 4
      //  - if the node to delete was black we need to rebalance
      else 
        db-rotate(z, Leaf, True) // Deletion curse of RB tree
    else rebuild(z, r.set-black) // Figure 4: Only has one child, so we set the child to black, and rebuild from here
  elif r.is-leaf then
    rebuild(z, l.set-black) // Figure 4: One child
  else
    do-remove-inorder(c, z, l, r, Done)

pub fip fun rebuild-root(z : zipper<k,v>, t : root<k,v>): root<k,v>
  match z
    ZNodeR(c, l, k, v, z1) -> rebuild-root(z1, Root(c, l, k, v, t.to-node))
    ZNodeL(c, z1, k, v, r) -> rebuild-root(z1, Root(c, t.to-node, k, v, r))
    Done -> t.set-black

pub fip fun root/set-black( t : root<k,v> ) : root<k,v>
  match t
    Root(_,l,x,v,r) -> Root(Black,l,x,v,r)

pub fun root(t: rbtree<k,v>): root<k,v>
  match t
    Node(c, a, k, v, b) -> Root(c, a, k, v, b)
    _ -> pretend-not-reachable()

pub fun do-remove-inorder(c: color, z: zipper<k,v>, l: rbtree<k,v>, r: rbtree<k,v>, rz: zipper<k,v>, ?k/show: (k) -> string, ?v/show: (v) -> string): rbtree<k,v>
  match r
    Node(rc, Leaf, k, v, rr) -> // Inorder found
      if rc.is-red then 
        trace("Red inorder")
        rebuild(z, rebuild(rz, Node(c, l, k, v, rr)))
      else 
        trace("Black inorder")
        trace(r.show)
        balance(z, db-rotate(rz, Node(c, l, k, v, rr), True).root)
    Node(rc, rl, k, v, rr) -> // Inorder search 
      do-remove-inorder(c, z, l, rl, ZNodeL(rc, rz, k, v, rr))
    Leaf -> Leaf // Should never be reached due to invariants

pub fip(1) fun bu/remove(t: rbtree<k,v>, key: k, ^?order2: (k,k) -> order2<k>, ?k/show: (k) -> string, ?v/show: (v) -> string) : exn rbtree<k,v>
  t.remove(key, Done)
