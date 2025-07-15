// Copied and derived from https://github.com/koka-lang/koka/tree/artifact-pldi24/test/artifact/pldi24
module rbtree-td

import std/num/random
import std/num/int32
pub import std/data/rbtree
pub import std/core/undiv

// rotate current `t`, parent `p`, and grand parent `g` where the color of `t` and `p` are red.
// Return an updated red `t` and its single new parent. The parent is always black with red children.
// See <https://www.franceskaxhakaj.com/papers/xhakaj,liew,iticse2015.pdf> figure 1 for the essential rotations.
fip fun rotate( t : dtree<k,v>, p : dtree<k,v>, g : dtree<k,v> ) : (dtree<k,v>,dtree<k,v>)
  match (t,p,g)
    // single rotations:
    (t,DNodeL(_,_,px,pv,pr),DNodeL(_,_,gx,gv,gr)) // parent / grandparent have holes in the left
      // make this the parent, and the grandparent has it's hole in the left filled with the parent
      // we don't fill the parent hole with the current, because it could require further rotations
      -> (t, DNodeL(Black,Hole,px,pv,Node(Red,pr,gx,gv,gr))) 
    (t,DNodeR(_,pl,px,pv,_),DNodeR(_,gl,gx,gv,_)) // inverted condition
      -> (t, DNodeR(Black,Node(Red,gl,gx,gv,pl),px,pv,Hole))
    // double rotations:
    (DNodeL(_,_,x,v,r),DNodeR(_,pl,px,pv,_),DNodeL(_,_,gx,gv,gr)) 
      -> (DNodeR(Red,pl,px,pv,Hole), DNodeL(Black,Hole,x,v,Node(Red,r,gx,gv,gr)))
    (DNodeR(_,l,x,v,_),DNodeR(_,pl,px,pv,_),DNodeL(_,_,gx,gv,gr))
      -> (DNodeL(Red,Hole,gx,gv,gr), DNodeR(Black,Node(Red,pl,px,pv,l),x,v,Hole))
    (DNodeL(_,_,x,v,r),DNodeL(_,_,px,pv,pr),DNodeR(_,gl,gx,gv,_))
      -> (DNodeR(Red,gl,gx,gv,Hole), DNodeL(Black,Hole,x,v,Node(Red,r,px,pv,pr)))
    (DNodeR(_,l,x,v,_),DNodeL(_,_,px,pv,pr),DNodeR(_,gl,gx,gv,_))
      -> (DNodeL(Red,Hole,px,pv,pr), DNodeR(Black,Node(Red,gl,gx,gv,l),x,v,Hole))
    // cannot happen:
    (t,p,_)
      -> (t,p)  // discarding `g` ? not fip.. but otherwise koka thinks its partial

// If a node is black with red children, then flip the colors
// If black->black, or red->black then wait to flip till a black-red is found.
// Precondition, no red-red
fip fun flip-color( t : rbtree<k,v> ) : rbtree<k,v>
  match t
    Node(Black, Node(Red,ll,lx,lv,lr), x, v, Node(Red,rl,rx,rv,rr))
      -> Node(Red, Node(Black,ll,lx,lv,lr), x, v, Node(Black,rl,rx,rv,rr))
    t -> t

// find and possibly insert `k`,`w` into a tree `t` with parent `p` and grandparent `g` under `acc`.
pub fbip(1) fun dtree/set(t : rbtree<k,v>, k : k, w : v, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>>, ^?order2: (k, k) -> order2<k>) : div rbtree<k,v>
  match flip-color(t)
    // If flipping the color would cause a red-red, we need a partially applied rotation
    Node(Red, l, x, v, r) | is-red(p) ->  // rotate to fix red-red between t and p ?
      match order2(x, k) 
        Lt2(x', k') -> val (p',g') = rotate( DNodeR(Red,l,x',v,Hole), p, g ) in set(r, k', w, p', g', acc) // Recur on the right
        Gt2(k', x') -> val (p',g') = rotate( DNodeL(Red,Hole,x',v,r), p, g ) in set(l, k', w, p', g', acc) // Recur on the left
        Eq2(x') -> done(Node(Red,l,x',w,r), p, g, acc) // Found the key, update the value
    Node(c, l, x, v, r) ->
      match order2(x, k)
        Lt2(x', k') -> set(r, k', w, DNodeR(c,l,x',v,Hole), p, acc ++ g) // Recur on the right
        Gt2(k', x') -> set(l, k', w, DNodeL(c,Hole,x',v,r), p, acc ++ g) // Recur on the left
        Eq2(x') -> done( Node(c,l,x',w,r), p, g, acc ) // Found the key, update the value
    Leaf -> done( Node(Red,Leaf,k,w,Leaf), p, g, acc ) // No key, insert the value

// pub fip(1) fun dtree/remove(t : rbtree<k,v>, k : k, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>>, ^?order2: (k, k) -> order2<k>) : pure rbtree<k,v>
//   match flip-color(t)
//     // If flipping the color would cause a red-red, we need a partially applied rotation
//     Node(Red, l, x, v, r) | is-red(p) ->  // rotate to fix red-red between t and p ?
//       match order2(x, k) 
//         Lt2(x', k') -> val (p',g') = rotate( DNodeR(Red,l,x',v,Hole), p, g ) in remove(r, k', p', g', acc) // Recur on the right
//         Gt2(k', x') -> val (p',g') = rotate( DNodeL(Red,Hole,x',v,r), p, g ) in remove(l, k', p', g', acc) // Recur on the left
//         _ -> done2(l, r, p, g, acc) // Found the key, remove the value
//     Node(c, l, x, v, r) ->
//       match order2(x, k)
//         Lt2(x', k') -> remove(r, k', DNodeR(c,l,x',v,Hole), p, acc ++ g) // Recur on the right
//         Gt2(k', x') -> remove(l, k', DNodeL(c,Hole,x',v,r), p, acc ++ g) // Recur on the left
//         _ -> done2( l, r, p, g, acc ) // Found the key, remove the value
//     Leaf -> done( Leaf, p, g, acc ) // No key, remove the value

// Need a new done that takes in two children, and combines appropriately
// fip fun done2( l : rbtree<k,v>, r : rbtree<k,v>, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>> ) : exn rbtree<k,v>
//   match (l,r)
//     (Leaf,Leaf) -> acc ++. (g ++. (p ++. Leaf))
//     (Leaf,r) -> acc ++. (g ++. r)
//     (l,Leaf) -> acc ++. (g ++. l)
//     (Node, Node) ->
//       throw("Not implemented") 

// Insert node `t` with parent `p` and grandparent `g` under `acc`.
fip fun done( t : rbtree<k,v>, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>> ) : rbtree<k,v>
  match t
    Node(Red,l,x,v,r) | is-red(p) -> 
      // sometimes we need rotate to fix red-red between t and p
      val (p',g') = rotate( DNodeL(Red,Hole,x,v,r), p, g )
      // Combine the accumulator with the grandparent composed with the parent composed with the tree.
      // There are only three levels of pointers that need to be adjusted
      // because we fixed all potential rotation violations on the way down
      acc ++. (g' ++. (p' ++. l))
    t -> acc ++. (g ++. (p ++. t))

pub tail fun td/set(t : rbtree<k,v>, k : k, w : v, ^?order2: (k, k) -> order2<k>) : rbtree<k,v>
  pretend-no-div
    dtree/set(t, k, w, NodeNone, NodeNone, ctx hole)

// pub fip(1) fun td/remove(t : rbtree<k,v>, k : k, ^?order2: (k, k) -> order2<k>) : exn rbtree<k,v>
//   pretend-no-div
//     dtree/remove(t, k, NodeNone, NodeNone, ctx hole).set-black

// type rbbtree<k, v>
//   BNode(color : color, lchild : rbtree<k,v>, key : k, value : v, rchild : rbtree<k,v>)
//   BLeaf
//   BBlack

// pub fip(1) fun dtree/remove(t: rbtree<k,v>, k0: k, ^?order2: (k, k) -> order2<k>)
//   match t
//     Leaf -> Leaf
//     Node(Red, Leaf, k1, v, Leaf) | k0 == k1 -> BLeaf
//     Node(Black, Node(Red, l, k1, v1, r), k2, v2, Leaf) | k0 == k2 -> BNode(Black, l, k1, v1, r)
//     Node(Black, Leaf, k1, v, Leaf) | k0 == k1 -> BBlack
    // Node(c, l, k1, v, r) ->
    //   match order2(k0, k1)
    //     Lt2(k0, k1) -> rotatex(BNode(c, remove(l, k0, order2)))

/*
// a tad faster but less elegant?
fip(1) fun set(t : rbtree<k,v>, k : k, w : tval, p : dtree<k,v>, g : dtree<k,v>, acc : ctx<rbtree<k,v>>) : div rbtree<k,v>
  match t
    Node(Black, Node(Red,ll,lx,lv,lr), x, v, Node(Red,rl,rx,rv,rr))
      val l = Node(Black,ll,lx,lv,lr)
      val r = Node(Black,rl,rx,rv,rr)
      if is-red(p) && x != k then
        if x < k then val (p',g') = rotate( DNodeR(Red,l,x,v,Hole), p, g ) in set(r, k, w, p', g', acc)
                 else val (p',g') = rotate( DNodeL(Red,Hole,x,v,r), p, g ) in set(l, k, w, p', g', acc)
      else
        if   x < k then set(r, k, w, DNodeR(Red,l,x,v,Hole), p, acc ++ g)
        elif x > k then set(l, k, w, DNodeL(Red,Hole,x,v,r), p, acc ++ g)
                   else done( Node(Red,l,k,w,r), p, g, acc )
    Node(c,l,x,v,r) ->
      if   x < k then set(r, k, w, DNodeR(c,l,x,v,Hole), p, acc ++ g)
      elif x > k then set(l, k, w, DNodeL(c,Hole,x,v,r), p, acc ++ g)
                 else done( Node(c,l,k,w,r), p, g, acc )
    Leaf -> done( Node(Red,Leaf,k,w,Leaf), p, g, acc )
*/