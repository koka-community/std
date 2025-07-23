// Copied and derived from https://github.com/koka-lang/koka/tree/artifact-pldi24/test/artifact/pldi24
module rbtree

import std/os/env
import std/num/random
import std/num/int32
import std/data/tree-common

pub type color
  Red
  Black

pub type rbtree<k,v>
  Leaf
  Node(color : color, left : rbtree<k,v>, key : k, value : v, right : rbtree<k,v>)

pub type root<k,v>
  Root(color : color, left : rbtree<k,v>, key : k, value : v, right : rbtree<k,v>)

pub type zipper<k,v>
  ZNodeR(color : color, lchild : rbtree<k,v>, key : k, value : v, zip : zipper<k,v>)
  ZNodeL(color : color, zip : zipper<k,v>, key : k, value : v, rchild : rbtree<k,v>)
  Done

// Derivative trees
pub type dtree<k,v>
  DNodeR(color : color, lchild : rbtree<k,v>, key : k, value : v, dhole : dhole)
  DNodeL(color : color, dhole : dhole, key : k, value : v, rchild : rbtree<k,v>)
  NodeNone   // for convenience

pub reference type dhole   // define as a reference type so the derivative tree constructors can reuse with Node's
  Hole

// TODO: Keep an inline size
pub fun tree/(==)(t1: rbtree<k,v>, t2: rbtree<k,v>, ?order2: (k, k) -> order2<k>, ?(==): (v, v) -> bool) : bool
  t1.list.length == t2.list.length && t1.list.all fn((k, v)) 
    match t2.lookup(k)
      Nothing -> False 
      Just(v') -> v == v'

// Common functionality
// TODO: Optimize
pub fun list(t: rbtree<k,v>) : list<(k,v)>
  match t
    Leaf -> []
    Node(_,l,k,v,r) -> l.list ++ Cons((k,v), r.list)

pub fun keys(t: rbtree<k,v>) : list<k>
  match t
    Leaf -> []
    Node(_,l,k,_,r) -> l.keys ++ Cons(k, r.keys)

pub fun values(t: rbtree<k,v>) : list<v>
  match t
    Leaf -> []
    Node(_,l,_,v,r) -> l.values ++ Cons(v, r.values)

pub inline fun empty() : rbtree<k,v>
  Leaf

pub inline fip fun set-black( t : rbtree<k,v> ) : rbtree<k,v>
  match t
    Node(_,l,x,v,r) -> Node(Black,l,x,v,r)
    Leaf            -> Leaf

pub fun contains(t: rbtree<k,v>, key: k, ^?order2: (k,k) -> e order2<k>) : e bool
  match t
    Leaf -> False
    Node(_, l, kx, _, r) ->
      match order2(key, kx)
        Lt2 -> contains(l, key)
        Gt2 -> contains(r, key)
        Eq2 -> True

pub fun lookup(t: rbtree<k,v>, key: k, ^?order2: (k,k) -> e order2<k>) : e maybe<v>
  match t
    Leaf -> Nothing
    Node(_, l, kx, v, r) ->
      match order2(key, kx)
        Lt2 -> lookup(l, key)
        Gt2 -> lookup(r, key)
        Eq2 -> Just(v)

pub inline fip fun rbtree/is-red(^t : rbtree<k,v>) : bool
  match t
    Node(Red) -> True
    _         -> False

// Helpers for other variants of the tree
pub inline fip fun dt/is-red( ^t : dtree<k,v> ) : bool
  match t
    DNodeR(Red) -> True
    DNodeL(Red) -> True
    _          -> False

// Cormen et al. textbook version
pub fip fun rebuild(z : zipper<k,v>, t : rbtree<k,v>): rbtree<k,v>
  match z
    ZNodeR(c, l, k, v, z1) -> rebuild(z1, Node(c, l, k, v, t))
    ZNodeL(c, z1, k, v, r) -> rebuild(z1, Node(c, t, k, v, r))
    Done -> t.set-black


pub fip fun rebuild-no-set(z : zipper<k,v>, t : rbtree<k,v>): rbtree<k,v>
  match z
    ZNodeR(c, l, k, v, z1) -> rebuild-no-set(z1, Node(c, l, k, v, t))
    ZNodeL(c, z1, k, v, r) -> rebuild-no-set(z1, Node(c, t, k, v, r))
    Done -> t

// append a `dtree<k,v>` to a context `acc`.
pub inline fip fun (++)( acc : ctx<rbtree<k,v>>, t : dtree<k,v> ) : ctx<rbtree<k,v>>
  match t
    DNodeR(c,l,x,v,_) -> acc ++ ctx Node(c,l,x,v,hole)
    DNodeL(c,_,x,v,r) -> acc ++ ctx Node(c,hole,x,v,r)
    NodeNone         -> acc

// plug an `rbtree<k,v>`` into a `dtree<k,v>`
pub inline fip fun (++.)( d : dtree<k,v>, t : rbtree<k,v> ) : rbtree<k,v>
  match d
    DNodeR(c,l,x,v,_) -> Node(c,l,x,v,t)
    DNodeL(c,_,x,v,r) -> Node(c,t,x,v,r)
    NodeNone         -> t

pub inline fip fun to-node( root : root<k,v> ) : rbtree<k,v>
  match root
    Root(c,l,k,v,r) -> Node(c,l,k,v,r)


// ---------------------------------------------------------
// show and print trees

pub fun render( t : rbtree<k,v>, ?key/show: (k) -> e string, ?value/show: (v) -> e string  ) : e render
  val minwidth = 3
  match t
    Leaf -> Render(0,[])
    Node(c,l,x,_,r) -> 
      beside(l.render,"-" ++ (x.show ++ "@" ++ c.showc).pad-left(minwidth) ++ "-",r.render)

pub fun show( t : rbtree<k,v> , ?key/show: (k) -> e string, ?value/show: (v) -> e string ) : e string
  t.render.lines.unlines

pub fun showc( c : color ) : string
  match c
    Red -> "r"
    Black -> "b"

pub fun show-trees( ts : list<rbtree<k,v>>, ?key/show: (k) -> e string, ?value/show: (v) -> e string ) : e string
  ts.map-indexed( fn(i,t) "rbtree<k,v> " ++ show(i+1) ++ ":\n\n" ++ t.show ).join("\n\n")

pub fun print( t : rbtree<k,v>, ?key/show: (k) -> <io|e> string, ?value/show: (v) -> <io|e> string ) : <io|e> ()
  t.show.println

pub fun print-trees( ts : list<rbtree<k,v>>, ?key/show: (k) -> <io|e> string, ?value/show: (v) -> <io|e> string ) : <io|e> ()
  ts.show-trees.println

// `d` is the default value for leaf nodes, `f` combines
pub fun bu/fold( t : rbtree<k,v>, d: a, f : (a,a,k,v) -> a ) : a
  match t
    Leaf -> d
    Node(_,Leaf,k,v,r) -> 
      f(r.fold(d, f), d, k, v)
    Node(_,r,k,v,Leaf) -> 
      f(r.fold(d, f), d, k, v)
    Node(_,l,k,v,r) -> 
      f(r.fold(d, f), l.fold(d, f), k, v)

// `acc` is the accumulated value, `f` combines
pub fun td/fold( t : rbtree<k,v>, acc: a, f : (a,k,v) -> a ) : a
  match t
    Leaf -> acc
    Node(_,l,k,v,r) -> 
      val res = td/fold(r, f(acc, k, v), f)
      td/fold(l, res, f)

// `acc` is the accumulated value, `f` combines
pub fun tdzip/fold( t : rbtree<k,v>, acc: a, c: zipper<k,v>, f : (a,k,v) -> a) : div a
  match t
    Leaf ->
      match c
        Done -> acc
        ZNodeL(_,z,_,_,r) -> fold(r, acc, z, f)
        ZNodeR(_,l,_,_,z) -> fold(l, acc, z, f)
    Node(col,l,k,v,r) ->
      fold(r, f(acc, k, v), ZNodeR(col,l,k,v,c), f)

// `acc` is the accumulated value, `f` combines
pub fun buacc/fold( t : rbtree<k,v>, acc: a, f : (a,k,v) -> a ) : a
  match t
    Leaf -> acc 
    // Consider the following cases so we don't double count the accumulator for left and right leaves
    Node(_,Leaf,k,v,r) -> 
      f(r.buacc/fold(acc, f), k, v) 
    Node(_,r,k,v,Leaf) -> 
      f(r.buacc/fold(acc, f), k, v)
    Node(_,l,k,v,r) ->
      f(r.buacc/fold(l.buacc/fold(acc, f), f), k, v)

// TODO: Optimize
pub fun rb/map( t : rbtree<k,v>, f : (v) -> e x ) : e rbtree<k,x>
  match t
    Leaf -> Leaf
    Node(c,l,k,v,r) ->
      Node(c, l.map(f), k, f(v), r.map(f))

pub fun keyvalue/map( t : rbtree<k,v>, f : (k, v) -> e x ) : e rbtree<k,x>
  match t
    Leaf -> Leaf
    Node(c,l,k,v,r) ->
      Node(c, l.map(f), k, f(k, v), r.map(f))
