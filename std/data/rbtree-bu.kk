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

pub fbip(1) fun zip/set(t : rbtree<k,v>, key : k, v : v, z : zipper<k,v>, ^?order2: (k,k) -> e order2<k>) : e rbtree<k,v>
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

value type tup2<k,v>
  DB(rbtree: rbtree<k,v>, k: k, v: v)
  T(rbtree: rbtree<k,v>)

pub tail fun zip/remove(t: rbtree<k,v>, key: k, z: zipper<k,v>, ^?order2: (k,k) -> order2<k>) : exn rbtree<k,v>
  match t
    Node(c, l, kx, vx, r) ->
      match order2(key, kx)
        Lt2(ki, kj) -> remove(l, ki, ZNodeL(c, z, kj, vx, r))
        Gt2(kj, ki) -> remove(r, ki, ZNodeR(c, l, kj, vx, z))
        Eq2(_) -> 
          do-remove(c, z, l, r) // Actually do the removing
    Leaf -> rebuild(z, Leaf) // Not found - Figure 3

pub tail fun bu/remove(t: rbtree<k,v>, key: k, ^?order2: (k,k) -> order2<k>) : exn rbtree<k,v>
  t.remove(key, Done)

// Balance final zipper
pub inline fip fun db-balance-rebuild(zip : zipper<k,v>, t: rbtree<k,v>): rbtree<k,v>
  match t
    Node(Black, Node(Red, Node(Red, a, x, vx, b), y, vy, c), z, vz, d)
      -> zip.rebuild(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)))
    Node(Black, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z, vz, d)
      -> zip.rebuild(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)))
    Node(Black, a, x, vx, Node(Red, Node(Red, b, y, vy, c), z, vz, d))
      -> zip.rebuild(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)))
    Node(Black, a, x, vx, Node(Red, b, y, vy, Node(Red, c, z, vz, d)))
      -> zip.rebuild(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)))
    t' -> zip.rebuild(t')

// Double black rotation (final zipper)
pub tail fun db-rotate(z: zipper<k,v>, t: rbtree<k,v>): rbtree<k,v>
  tail fun db-balance-rotate-build(zip, t')
    match t' // BB cases
      // Node(Black,  a = Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z' =x, vz= vx, d =Node(Red, b, y, vy, t))
      Node(_, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z', vz, d) ->
        zip.rebuild(Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z', vz, d)))
      Node(_, a, x, vx, Node(Red, Node(Red, b, y, vy, c), z', vz, d)) ->
        zip.rebuild(Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z', vz, d)))
      t'' -> db-rotate(zip.pretend-decreasing, t'')
  match z
    // First case Figure 6, t is x, z is y, double black is discharged and we can just rebuild normally
    ZNodeL(Red, z', y, vy, Node(Black, c, kz, vz, d)) ->
      db-balance-rebuild(z', Node(Black, Node(Red, t, y, vy, c), kz, vz, d))
    ZNodeR(Red, Node(Black, a, x, vx, b), y, vy, z') ->
      db-balance-rebuild(z', Node(Black, a, x, vx, Node(Red, b, y, vy, t)))
    // Second case Figure 7, t is x, z is y
    ZNodeL(Black, z', y, vy, Node(Black, c, kz, vz, d)) ->
      // match c // Try to inline & specialize db-balance-rotate-build
      //   Node(Red, b', y', vy', c') -> z'.rebuild(Node(Black, Node(Black, t, y, vy, b'), y', vy', Node(Black, c', kz, vz, d)))
      //   c' -> 
      //     match d
      //       Node(Red, Node(Red, b', y', vy', c''), z'', vz', d') ->
      //         z'.rebuild(Node(Black, Node(Black, Node(Red, t, y, vy, c'), kz, vz, b'), y', vy', Node(Black, c'', z'', vz', d')))
      //       d' -> db-rotate(z'.pretend-decreasing, Node(Black, Node(Red, t, y, vy, c'), kz, vz, d'))
      z'.db-balance-rotate-build(Node(Black, Node(Red, t, y, vy, c), kz, vz, d))
    ZNodeR(Black, Node(Black, a, x, vx, b), y, vy, z') ->
      // match b // Try to inline & specialize db-balance-rotate-build
      //   Node(Red, b', y', vy', c') ->
      //     z'.rebuild(Node(Black, Node(Black, a, x, vx, b'), y', vy', Node(Black, c', y, vy, t)))
      //   b' ->
      //     match a
      //       Node(Red, a', x', vx', Node(Red, b'', y', vy', c')) ->
      //         z'.rebuild(Node(Black, Node(Black, a', x', vx', b''), y', vy', Node(Black, c', x, vx, Node(Red, b', y, vy, t))))
      //       a' -> db-rotate(z'.pretend-decreasing, Node(Black, a', x, vx, Node(Red, b', y, vy, t)))
      z'.db-balance-rotate-build(Node(Black, a, x, vx, Node(Red, b, y, vy, t)))
    // Third case Figure 9, t is w, z is x
    ZNodeL(Black, z', x, vx, Node(Red, Node(Black, c, y, vy, d), kz, vz, e)) ->
      ZNodeL(Black, z', kz, vz, e).db-balance-rebuild(Node(Black, Node(Red, t, x, vx, c), y, vy, d))
    ZNodeR(Black, Node(Red, a, w, vw, Node(Black, b, x, vx, c)), y, vy, z') ->
      ZNodeR(Black, a, w, vw, z').db-balance-rebuild(Node(Black, b, x, vx, Node(Red, c, y, vy, t)))
    // Rebuild one step then rebalance
    ZNodeR(c, l, k, v, z1) -> db-rotate(z1, Node(c, l, k, v, t))
    ZNodeL(c, z1, k, v, r) -> db-rotate(z1, Node(c, t, k, v, r))
    Done -> t.set-black // Error to get here with still being double black

pub fip fun rebuild-no-set2(z : zipper<k,v>, t : rbtree<k,v>, ^f: (rbtree<k,v>, bool) -> rbtree<k,v>): rbtree<k,v>
  match z
    ZNodeR(c, l, k, v, z1) -> rebuild-no-set2(z1, Node(c, l, k, v, t), f)
    ZNodeL(c, z1, k, v, r) -> rebuild-no-set2(z1, Node(c, t, k, v, r), f)
    Done -> f(t, False)

// Balance inner zipper
pub inline fip fun db-balance-rebuild-no-set(zip : zipper<k,v>, t: rbtree<k,v>, ^f: (rbtree<k,v>, bool) -> rbtree<k,v>): rbtree<k,v>
  match t
    Node(Black, Node(Red, Node(Red, a, x, vx, b), y, vy, c), z, vz, d)
      -> zip.rebuild-no-set2(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)), f)
    Node(Black, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z, vz, d)
      -> zip.rebuild-no-set2(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)), f)
    Node(Black, a, x, vx, Node(Red, Node(Red, b, y, vy, c), z, vz, d))
      -> zip.rebuild-no-set2(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)), f)
    Node(Black, a, x, vx, Node(Red, b, y, vy, Node(Red, c, z, vz, d)))
      -> zip.rebuild-no-set2(Node(Red, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z, vz, d)), f)
    t' -> zip.rebuild-no-set2(t', f)

pub tail fun db-rotate-done(z: zipper<k,v>, t: rbtree<k,v>, ^f: (rbtree<k,v>, bool) -> rbtree<k,v>): rbtree<k,v>
  fbip fun db-balance-rotate-done(zip, t', ^f1)
    match t' // BB cases
      Node(_, Node(Red, a, x, vx, Node(Red, b, y, vy, c)), z', vz, d) ->
        zip.rebuild-no-set2(Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z', vz, d)), f1)
      Node(_, a, x, vx, Node(Red, Node(Red, b, y, vy, c), z', vz, d)) ->
        zip.rebuild-no-set2(Node(Black, Node(Black, a, x, vx, b), y, vy, Node(Black, c, z', vz, d)), f1)
      t'' -> db-rotate-done(zip.pretend-decreasing, t'', f1)
  match z
    // First case Figure 6, t is x, z is y, double black is discharged and we can just rebuild normally
    ZNodeL(Red, z', y, vy, Node(Black, c, kz, vz, d)) ->
      z'.db-balance-rebuild-no-set(Node(Black, Node(Red, t, y, vy, c), kz, vz, d), f)
    ZNodeR(Red, Node(Black, a, x, vx, b), y, vy, z') ->
      z'.db-balance-rebuild-no-set(Node(Black, a, x, vx, Node(Red, b, y, vy, t)), f)
    // Second case Figure 7, t is x, z is y
    ZNodeL(Black, z', y, vy, Node(Black, c, kz, vz, d)) ->
      // match c // Try to inline & specialize db-balance-rotate-done
      //   Node(Red, b', y', vy', c') -> z'.rebuild-no-set2(Node(Black, Node(Black, t, y, vy, b'), y', vy', Node(Black, c', kz, vz, d)), f)
      //   c' -> 
      //     match d
      //       Node(Red, Node(Red, b', y', vy', c''), z'', vz', d') ->
      //         z'.rebuild-no-set2(Node(Black, Node(Black, Node(Red, t, y, vy, c'), kz, vz, b'), y', vy', Node(Black, c'', z'', vz', d')), f)
      //       d' -> db-rotate-done(z'.pretend-decreasing, Node(Black, Node(Red, t, y, vy, c'), kz, vz, d'), f)
      z'.db-balance-rotate-done(Node(Black, Node(Red, t, y, vy, c), kz, vz, d), f)
    ZNodeR(Black, Node(Black, a, x, vx, b), y, vy, z') ->
      // match b // Try to inline & specialize db-balance-rotate-done
      //   Node(Red, b', y', vy', c') ->
      //     z'.rebuild-no-set2(Node(Black, Node(Black, a, x, vx, b'), y', vy', Node(Black, c', y, vy, t)), f)
      //   b' ->
      //     match a
      //       Node(Red, a', x', vx', Node(Red, b'', y', vy', c')) ->
      //         z'.rebuild-no-set2(Node(Black, Node(Black, a', x', vx', b''), y', vy', Node(Black, c', x, vx, Node(Red, b', y, vy, t))), f)
      //       a' -> db-rotate-done(z'.pretend-decreasing, Node(Black, a', x, vx, Node(Red, b', y, vy, t)), f)
      z'.db-balance-rotate-done(Node(Black, a, x, vx, Node(Red, b, y, vy, t)), f)
    // Third case Figure 9, t is w, z is x
    ZNodeL(Black, z', x, vx, Node(Red, Node(Black, c, y, vy, d), kz, vz, e)) ->
      ZNodeL(Black, z', kz, vz, e).db-balance-rebuild-no-set(Node(Black, Node(Red, t, x, vx, c), y, vy, d), f)
    ZNodeR(Black, Node(Red, a, w, vw, Node(Black, b, x, vx, c)), y, vy, z') ->
      ZNodeR(Black, a, w, vw, z').db-balance-rebuild-no-set(Node(Black, b, x, vx, Node(Red, c, y, vy, t)), f)
    // Rebuild one step then rebalance
    ZNodeR(c, l, k, v, z1) -> db-rotate-done(z1, Node(c, l, k, v, t), f)
    ZNodeL(c, z1, k, v, r) -> db-rotate-done(z1, Node(c, t, k, v, r), f)
    Done -> f(t, True)

pub tail fun do-remove(c: color, z: zipper<k,v>, l: rbtree<k,v>, r: rbtree<k,v>): rbtree<k,v>
  if l.is-leaf then 
    if r.is-leaf then // No children (just replace with leaf)
      if c.is-red then //  - if the node to delete was red this doesn't change the black height
        rebuild(z, Leaf) // Figure 4
      else // - if the node to delete was black we need to rebalance
        db-rotate(z, Leaf) // Deletion curse of RB tree
    else rebuild(z, r.set-black) // Figure 4: Only has one child, so we set the child to black, and rebuild from here
  elif r.is-leaf then // Other case with one child
    rebuild(z, l.set-black) // Figure 4: One child
  else
    // Otherwise we have a tree of children, replace with inorder successor, deleting the inorder successor as you go
    do-remove-inorder(c, z, l, r, Done)

pub tail fun do-remove-inorder(c: color, z: zipper<k,v>, l: rbtree<k,v>, r: rbtree<k,v>, rz: zipper<k,v>): rbtree<k,v>
  match r
    // Replace the inorder successor with a leaf, and move it's key / value to the deleted node.
    Node(Red, Leaf, k, v, Leaf) -> 
      // trace("2nd case")
      rebuild(z, Node(c, l, k, v, rz.rebuild-no-set(Leaf)))
    // Replace the inorder successor with it's right child - setting it to black, and move it's key / value to the deleted node.
    Node(Black, Leaf, k, v, Node(Red, rl, kr, vr, rr)) -> 
      // trace("3rd case")
      rebuild(z, Node(c, l, k, v, rz.rebuild-no-set(Node(Black, rl, kr, vr, rr))))
    // Double black case
    Node(Black, Leaf, k, v, rr) -> // Inorder black leaf node, requires balancing
      // trace(rr.show)
      db-rotate-done(rz, rr) fn(r', is-double-black)
        // trace(r'.show ++ " idb " ++ is-double-black.show)
        if is-double-black then
          db-rotate(ZNodeR(c, l, k, v, z), r')
        else
          ZNodeR(c, l, k, v, z).rebuild(r')
    // Recur case
    Node(rc, rl, k, v, rr) -> // Inorder search 
      // trace("recur inorder " ++ rc.showc ++ " " ++ k.show)
      do-remove-inorder(c, z, l, rl, ZNodeL(rc, rz, k, v, rr))
    // First case
    Leaf -> Leaf // Should never be reached due to invariants
