// Tarjan, Levy, and Timmel's zip trees.
// a zip tree is an ordered binary search tree where ever node also has a _rank_
// the rank of a node is greater than the rank of the left child,
// and greater or equal to the right child. 
// It is max heap-ordered with respect to ranks with ties broken in favor of smaller keys.
// 
// We derive the rank "pseudo randomly" from the key so we can combine search 
// and insert. This determines the shape of the tree completely.
//
// When we "unzip" along a key k, we split the path in a tree with smaller
// element than k, and another tree with larger elements than k. (and then
// put node k on top)
module ziptree-bu

import std/num/int32
import std/num/random
import ziptree

type zipper<k,v>
  NodeR( rank : rank, left : ztree<k,v>, key : k, value: v, up : zipper<k,v> )
  NodeL( rank : rank, up : zipper<k,v>, key : k, value: v, right : ztree<k,v> )
  Done

/*
pub fun access( t : ztree, k : key ) : ztree 
  find( t, rank-of(k), k, Done ) 

fun find( t : ztree, rank : rank, k : key, z : zipper ) : ztree 
  match t
    Node(rnk,l,x,r) | is-higher-rank( (rnk,x), (rank,k) )
      -> if (x < k) then find(r, rank, k, NodeR(rnk, l, x, z))
                    else find(l, rank, k, NodeL(rnk, z, x, r))
    Node(_,_,x,_) | x == k
      -> rebuild( z, t )
    _ -> match unzip(t,k,Done,Done)
           (s,b) -> rebuild( z, Node(rank,s,k,b) )
*/

pub inline fun int/hash(x: int): int32
  x.int32

pub fip(1) fun access( t : ztree<int,int>, k : int ) : ztree<int,int>
  find( t, rank-of(k), k, k, ctx _) 

fip fun has-key( ^t : ztree<k,v>, k : k, ^?order2: (k,k) -> order2<k> ) : bool
  match t 
    Node(_,_,x,_) -> order2(x, k).is-Eq2
    _             -> False  

fip(1) fun find( t : ztree<k,v>, rank : rank, k : k, new-v: v, acc : ctx<ztree<k,v>>, ^?order2: (k,k) -> order2<k> ) : ztree<k,v> 
  match t
    Node(rnk,l,x,v,r) | is-higher-rank( (rnk,x), (rank,k) )
      -> 
        match order2(x,k)
          Lt2(kk,kx) -> find(r, rank, kk, new-v, acc ++ ctx Node(rnk, l, kx, v, _))
          Gt2(kx,kk) -> find(l, rank, kk, new-v, acc ++ ctx Node(rnk, _, kx, v, r))
          Eq2(kx) -> find(l, rank, kx, new-v, acc ++ ctx Node(rnk, _, kx, v, r))
    t -> if t.has-key(k) then acc ++. t
                         else match unzip(t,k,Done,Done)
                                (s,b) -> acc ++. Node(rank,s,k,new-v,b) 

fip fun unzip( t : ztree<k,v>, k : k, zs : zipper<k,v>, zb : zipper<k,v>, ^?order2: (k,k) -> order2<k>) : (ztree<k,v>,ztree<k,v>)         
  match t
    Node(rnk,l,x,v,r) -> 
      match order2(x,k)
        Lt2(kk,kx) -> unzip( r, kk, NodeR(rnk,l,kx,v,zs), zb)
        Gt2(kx,kk) -> unzip( l, kk, zs, NodeL(rnk,zb,kx,v,r))
        Eq2(kx)  -> unzip( l, kx, zs, NodeL(rnk,zb,kx,v,r))
    Leaf -> (rebuild(zs,Leaf), rebuild(zb,Leaf))

fip fun rebuild( z : zipper<k,v>, t : ztree<k,v> ) : ztree<k,v>
  match z 
    NodeR(rnk,l,x,v,up) -> rebuild(up, Node(rnk,l,x,v,t))
    NodeL(rnk,up,x,v,r) -> rebuild(up, Node(rnk,t,x,v,r))
    Done              -> t

pub fun main() : io ()
  benchmain(access)