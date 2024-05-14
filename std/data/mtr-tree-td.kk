module mtr-tree-td

import std/num/int32
import mtr-tree

pub fip(1) fun insert( t : tree<k,v>, k : k, v: v, ^?order2 : (k,k) -> order2<k>) : tree<k,v>
  mtr(t,k,v,ctx _, ctx _)

fip(1) fun mtr( t : tree<k,v>, k : k, newV: v, accl : ctx<tree<k,v>>, accr : ctx<tree<k,v>>, ^?order2 : (k,k) -> order2<k>) : tree<k,v>
  match t
    Node(l,x,v,r) -> 
     match order2(x,k)
      Lt2(lt,gt) -> mtr( r, gt, newV, accl ++ ctx Node(l,lt,v,_), accr )
      Gt2(lt,gt) -> mtr( l, lt, newV, accl, accr ++ ctx Node(_,gt,v,r) )
      Eq2(xx) -> Node( accl ++. l, xx, newV, accr ++. r )
    Leaf        -> Node( accl ++. Leaf, k, newV, accr ++. Leaf )

pub fip(1) fun access( t : tree<int,int>, k : int ) : tree<int,int>
  insert(t,k,k)

pub fun test()
  test5(access)
  //test6(access)

pub fun main()
  benchmain(access)