module rbtree-td

import std/num/random
import std/num/int32
import rbtree

pub fip fun is-red(^t : rbtree<k,v>) : bool
  match t
    Node(Red) -> True
    _         -> False

pub fip fun set-black( t : rbtree<k,v> ) : rbtree<k,v>
  match t
    Node(_,l,x,v,r) -> Node(Black,l,x,v,r)
    Leaf            -> Leaf

// Derivative trees
pub type dtree<k,v>
  NodeR(color : color, lchild : rbtree<k,v>, key : k, value : v, dhole : dhole)
  NodeL(color : color, dhole : dhole, key : k, value : v, rchild : rbtree<k,v>)
  NodeNone   // for convenience

pub ref type dhole   // define as a reference type so the derivative tree constructors can reuse with Node's
  Hole

// append a `dtree<k,v>` to a context `acc`.
fip fun (++)( acc : ctx<rbtree<k,v>>, t : dtree<k,v> ) : ctx<rbtree<k,v>>
  match t
    NodeR(c,l,x,v,_) -> acc ++ ctx Node(c,l,x,v,_)
    NodeL(c,_,x,v,r) -> acc ++ ctx Node(c,_,x,v,r)
    NodeNone         -> acc

// plug an `rbtree<k,v>`` into a `dtree<k,v>`
fip fun (++.)( d : dtree<k,v>, t : rbtree<k,v> ) : rbtree<k,v>
  match d
    NodeR(c,l,x,v,_) -> Node(c,l,x,v,t)
    NodeL(c,_,x,v,r) -> Node(c,t,x,v,r)
    NodeNone         -> t

fip fun is-redd( ^t : dtree<k,v> ) : bool
  match t
    NodeR(Red) -> True
    NodeL(Red) -> True
    _          -> False

// rotate current `t`, parent `p`, and grand parent `g` where the color of `t` and `p` are red.
// Return an updated red `t` and its single new parent. The parent is always black with red children.
// See <https://www.franceskaxhakaj.com/papers/xhakaj,liew,iticse2015.pdf> figure 1 for the essential rotations.
fip fun rotate( t : dtree<k,v>, p : dtree<k,v>, g : dtree<k,v> ) : (dtree<k,v>,dtree<k,v>)
  match (t,p,g)
    // single rotations:
    (t,NodeL(_,_,px,pv,pr),NodeL(_,_,gx,gv,gr))
      -> (t, NodeL(Black,Hole,px,pv,Node(Red,pr,gx,gv,gr)))
    (t,NodeR(_,pl,px,pv,_),NodeR(_,gl,gx,gv,_))
      -> (t, NodeR(Black,Node(Red,gl,gx,gv,pl),px,pv,Hole))
    // double rotations:
    (NodeL(_,_,x,v,r),NodeR(_,pl,px,pv,_),NodeL(_,_,gx,gv,gr))
      -> (NodeR(Red,pl,px,pv,Hole), NodeL(Black,Hole,x,v,Node(Red,r,gx,gv,gr)))
    (NodeR(_,l,x,v,_),NodeR(_,pl,px,pv,_),NodeL(_,_,gx,gv,gr))
      -> (NodeL(Red,Hole,gx,gv,gr), NodeR(Black,Node(Red,pl,px,pv,l),x,v,Hole))
    (NodeL(_,_,x,v,r),NodeL(_,_,px,pv,pr),NodeR(_,gl,gx,gv,_))
      -> (NodeR(Red,gl,gx,gv,Hole), NodeL(Black,Hole,x,v,Node(Red,r,px,pv,pr)))
    (NodeR(_,l,x,v,_),NodeL(_,_,px,pv,pr),NodeR(_,gl,gx,gv,_))
      -> (NodeL(Red,Hole,px,pv,pr), NodeR(Black,Node(Red,gl,gx,gv,l),x,v,Hole))
    // cannot happen:
    (t,p,_)
      -> (t,p)  // discarding `g` ? not fip.. but otherwise koka thinks its partial

// If a node is black with red children, then flip the colors
fip fun flip-color( t : rbtree<k,v> ) : rbtree<k,v>
  match t
    Node(Black, Node(Red,ll,lx,lv,lr), x, v, Node(Red,rl,rx,rv,rr))
      -> Node(Red, Node(Black,ll,lx,lv,lr), x, v, Node(Black,rl,rx,rv,rr))
    t -> t


// Insert node `t` with parent `p` and grandparent `g` under `acc`.
fip fun done( t : rbtree<k,v>, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>> ) : rbtree<k,v>
  match t
    Node(Red,l,x,v,r) | is-redd(p)   // sometimes we need rotate to fix red-red between t and p
      -> val (p',g') = rotate( NodeL(Red,Hole,x,v,r), p, g ) in acc ++. (g' ++. (p' ++. l))
    t -> acc ++. (g ++. (p ++. t))


fip fun (!=)(^x : k, ^y : k, ^?order2: (k, k) -> order2<k>) : bool
  match order2(x, y)
    Eq2 -> True
    _ -> False

fip fun (<)(^x : k, ^y : k, ^?order2: (k, k) -> order2<k>) : bool
  match order2(x, y)
    Lt2 -> True
    _ -> False

fip fun (>)(^x : k, ^y : k, ^?order2: (k, k) -> order2<k>) : bool
  match order2(x, y)
    Gt2 -> True
    _ -> False

// find and possibly insert `k`,`w` into a tree `t` with parent `p` and grandparent `g` under `acc`.
pub fip(1) fun set(t : rbtree<k,v>, k : k, w : v, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>>, ^?order2: (k, k) -> order2<k>) : div rbtree<k,v>
  match flip-color(t)
    Node(Red, l, x, v, r) | is-redd(p) && x != k ->  // rotate to fix red-red between t and p ?
      if x < k then val (p',g') = rotate( NodeR(Red,l,x,v,Hole), p, g ) in set(r, k, w, p', g', acc)
               else val (p',g') = rotate( NodeL(Red,Hole,x,v,r), p, g ) in set(l, k, w, p', g', acc)
    Node(c, l, x, v, r) ->
      if   x < k then set(r, k, w, NodeR(c,l,x,v,Hole), p, acc ++ g)
      elif x > k then set(l, k, w, NodeL(c,Hole,x,v,r), p, acc ++ g)
                 else done( Node(c,l,k,w,r), p, g, acc )
    Leaf -> done( Node(Red,Leaf,k,w,Leaf), p, g, acc )

/*
// a tad faster but less elegant?
fip(1) fun set(t : rbtree<k,v>, k : k, w : tval, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>>) : div rbtree<k,v>
  match t
    Node(Black, Node(Red,ll,lx,lv,lr), x, v, Node(Red,rl,rx,rv,rr))
      val l = Node(Black,ll,lx,lv,lr)
      val r = Node(Black,rl,rx,rv,rr)
      if is-red(p) && x != k then
        if x < k then val (p',g') = rotate( NodeR(Red,l,x,v,Hole), p, g ) in set(r, k, w, p', g', acc)
                 else val (p',g') = rotate( NodeL(Red,Hole,x,v,r), p, g ) in set(l, k, w, p', g', acc)
      else
        if   x < k then set(r, k, w, NodeR(Red,l,x,v,Hole), p, acc ++ g)
        elif x > k then set(l, k, w, NodeL(Red,Hole,x,v,r), p, acc ++ g)
                   else done( Node(Red,l,k,w,r), p, g, acc )
    Node(c,l,x,v,r) ->
      if   x < k then set(r, k, w, NodeR(c,l,x,v,Hole), p, acc ++ g)
      elif x > k then set(l, k, w, NodeL(c,Hole,x,v,r), p, acc ++ g)
                 else done( Node(c,l,k,w,r), p, g, acc )
    Leaf -> done( Node(Red,Leaf,k,w,Leaf), p, g, acc )
*/