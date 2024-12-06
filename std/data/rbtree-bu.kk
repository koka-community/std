// Copied and derived from https://github.com/koka-lang/koka/tree/artifact-pldi24/test/artifact/pldi24
module rbtree-bu

pub import std/data/rbtree
pub import std/core/undiv

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
