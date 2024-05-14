module mtr-tree-bu

import std/num/int32
import mtr-tree

pub fip(1) fun access( t : tree<int,int>, k : int ) : tree<int,int>
  insert(t,k,k)

pub fip(1) fun insert( t : tree<k,v>, k : k, v: v, ^?order2 : (k,k) -> order2<k>) : tree<k,v>
  insertz(t,k,v,Done)

type zipper<k,v>
  NodeR( left : tree<k,v>, key : k, value: v, up : zipper<k,v> )
  NodeL( up : zipper<k,v>, key : k, value: v, right : tree<k,v> )
  Done

fip(1) fun insertz( t : tree<k,v>, k : k, new-v: v, z : zipper<k,v>, ^?order2 : (k,k) -> order2<k> ) : tree<k,v>
  match t
    Node(l,x,v,r) -> 
      match order2(x,k)
        Lt2(kk,kx) -> insertz( r, kk, new-v, NodeR(l,kx,v,z) )
        Gt2(kx,kk) -> insertz( l, kk, new-v,NodeL(z,kx,v,r) )
        Eq2(kk) -> mtr( Root(l,kk,new-v,r), z )
    Leaf        -> mtr( Root(Leaf,k,new-v,Leaf), z )  // insert if not found


fip fun mtr( root : root<k,v>, z : zipper<k,v> ) : tree<k,v>
  match root
    Root(l,x,v,r) -> match z
      NodeR(zl,zx,zv,up) -> mtr( Root(Node(zl,zx,zv,l),x,v,r), up )
      NodeL(up,zx,zv,zr) -> mtr( Root(l,x,v,Node(r,zx,zv,zr)), up )
      Done            -> Node(l,x,v,r)

pub fun test()
  test5(access)   // does not follow Fig 6
  //test6(access)

pub fun main()
  benchmain(access)