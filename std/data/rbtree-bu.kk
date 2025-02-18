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
    match t // BB cases
      Node(_, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z, vz, d) ->
        Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      Node(_, a, x, vx, Node(Red, Node(Red, b, y, vy, c), z, vz, d)) ->
        Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d))
      t' -> t' // TODO: Fix this, needs rotate / balance after ascending one link
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
      t' -> t'

// pub fun db-rotate-node(t : rbtree<k,v>, right-bb: bool, ?k/show: (k) -> string, ?v/show: (v) -> string): rbtree<k,v>
  


// TODO: the zipper needs to rerotate?
pub fun db-rotate(z: zipper<k,v>, t: rbtree<k,v>, is-double-black: bool, ?k/show: (k) -> string, ?v/show: (v) -> string): rbtree<k,v>
  match z
    // First case Figure 6, t is x, z is y, double black is discharged and we can just rebuild normally
    ZNodeL(Red, z', y, vy, Node(Black, c, kz, vz, d)) | is-double-black ->
      trace("Firsta")
      val x' = Node(Black, Node(Red, t, y, vy, c), kz, vz, d)
      // trace(x'.show)
      val balanced = db-balance(x', False)
      // trace(balanced.show)
      z'.rebuild-no-set(balanced)
    ZNodeR(Red, Node(Black, a, x, vx, b), y, vy, z') | is-double-black ->
      trace("Firstb")
      val node = Node(Black, a, x, vx, Node(Red, b, y, vy, t))
      // trace(node.show)
      val balanced = db-balance(node, False)
      // trace(balanced.show)
      val res = z'.rebuild-no-set(balanced)
      // trace(res.show)
      res
    // Second case Figure 7, t is x, z is y
    ZNodeL(Black, z', y, vy, Node(Black, c, kz, vz, d)) | is-double-black ->
      trace("Seconda")
      z'.rebuild-no-set(db-balance(Node(Black, Node(Red, t, y, vy, c), kz, vz, d), True))
    ZNodeR(Black, Node(Black, a, x, vx, b), y, vy, z') | is-double-black ->
      trace("Secondb")
      z'.rebuild-no-set(db-balance(Node(Black, a, x, vx, Node(Red, b, y, vy, t)), True))
    // Third case Figure 9, t is w, z is x
    ZNodeL(Black, z', x, vx, Node(Red, Node(Black, c, y, vy, d), kz, vz, e)) ->
      trace("Thirda")
      z'.rebuild-no-set(Node(Black, db-balance(Node(Black, Node(Red, t, x, vx, c), y, vy, d), False), kz, vz, e))
    ZNodeR(Black, Node(Red, a, w, vw, Node(Black, b, x, vx, c)), y, vy, z') ->
      trace("Thirdb")
      z'.rebuild-no-set(Node(Black, a, w, vw, db-balance(Node(Black, b, x, vx, Node(Red, c, y, vy, t)), False)))
    z' -> 
      trace("Noa")
      z'.rebuild-no-set(t)


pub fun do-remove(c: color, z: zipper<k,v>, l: rbtree<k,v>, r: rbtree<k,v>, ?k/show: (k) -> string, ?v/show: (v) -> string): rbtree<k,v>
  if l.is-leaf then 
    if r.is-leaf then 
      // No children (just replace with leaf)
      //  - if the node to delete was red this doesn't change the black height
      if c.is-red then rebuild-no-set(z, Leaf) // Figure 4
      //  - if the node to delete was black we need to rebalance
      else 
        db-rotate(z, Leaf, True) // Deletion curse of RB tree
    else rebuild-no-set(z, r.set-black) // Figure 4: Only has one child, so we set the child to black, and rebuild from here
  elif r.is-leaf then
    rebuild-no-set(z, l.set-black) // Figure 4: One child
  else
    trace("remove inorder")
    trace(c.showc)
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
    // Second case
    Node(Red, Leaf, k, v, Leaf) ->
      trace("2nd case")
      // trace(rz.rebuild-no-set(Leaf).show)
      // Replace the inorder successor with a leaf, and move it's key / value to the deleted node.
      rebuild-no-set(z, Node(c, l, k, v, rz.rebuild-no-set(Leaf)))
    // Third case
    Node(Black, Leaf, k, v, Node(Red, rl, kr, vr, rr)) ->
      trace("3rd case")
      // Replace the inorder successor with it's right child - setting it to black, and move it's key / value to the deleted node.
      rebuild-no-set(z, Node(c, l, k, v, rz.rebuild-no-set(Node(Black, rl, kr, vr, rr))))
    // Double black case
    Node(Black, Leaf, k, v, rr) -> // Inorder found
      trace("Black inorder")
      // trace(r.show ++ "\n")
      // trace(l.show ++ "\n")
      // trace(rz.rebuild(Leaf).show ++ "\n")
      // trace(z.rebuild(Leaf).show ++ "\n")
      // trace(Node(c, l, k, v, rr).show ++ "\n")
      // trace(db-rotate(rz, rr, True).show ++ "\n")
      match db-rotate(rz, rr, True)
        Leaf -> 
          trace("Here: ")
          // TODO: WE need a db balance
          val res = db-rotate(ZNodeR(c, l, k, v, Done), Leaf, True)
          trace(res.show)
          balance(z, res.root)
        r' ->
          trace("Here") 
          balance(z, Node(c, l, k, v, r').root)
    // Recur case
    Node(rc, rl, k, v, rr) -> // Inorder search 
      trace("recur inorder " ++ rc.showc ++ " " ++ k.show)
      do-remove-inorder(c, z, l, rl, ZNodeL(rc, rz, k, v, rr))
    // First case
    Leaf -> Leaf // Should never be reached due to invariants

pub fip(1) fun bu/remove(t: rbtree<k,v>, key: k, ^?order2: (k,k) -> order2<k>, ?k/show: (k) -> string, ?v/show: (v) -> string) : exn rbtree<k,v>
  t.remove(key, Done)
