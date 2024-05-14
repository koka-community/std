module ziptree

import std/os/env
import std/num/random
import std/num/int32
import std/num/int64
import tree-common

pub alias rank = int

pub fip fun is-higher-rank( (r1,k1) : (rank,k), (r2,k2) : (rank,k) , ^?order2: (k,k) -> order2<k>) : bool
  (r1 > r2 || (r1 == r2 && (order2(k1,k2).is-Lt2)))

pub type ztree<k,v>
  Leaf
  Node(rank : rank, left : ztree<k,v>, k : k, v: v, right : ztree<k,v>)

pub type root<k,v>
  Root(rank : rank, left : ztree<k,v>, k : k, v: v, right : ztree<k,v>)

// rank is hashed from the k so we can combine search and insert
pub fip fun rank-of1( k : k , ?hash: (k) -> int32 ) : rank
  // pseudo random shuffle by Chris Wellons, see: <https://nullprogram.com/blog/2018/07/31/>
  val x0 = k.hash.inc
  val x1 = xor(x0,shr(x0,15)) * 0x2c1b3c6d.int32
  val x2 = xor(x1,shr(x1,12)) * 0x297a2d39.int32
  val x  = xor(x2,shr(x2,15))
  x.ctz

pub fip fun rank-of( k : k, ?hash: (k) -> int32 ) : rank
  val x0 = k.hash.inc
  val x1 = xor(x0,shr(x0,16)) *  0x297a2d39.int32
  val x  = xor(x1,shr(x1,16))
  x.ctz


// ---------------------------------------------------------
// show and print trees

pub fun show( t : ztree<k,v>, ?show: (k) -> string ) : string
  t.render.lines.unlines

pub fun show-trees( ts : list<ztree<k,v>>, ?show: (k) -> string  ) : string
  ts.map-indexed( fn(i,t) "ztree<k,v> " ++ show(i+1) ++ ":\n\n" ++ t.show ).join("\n\n")

pub fun print( t : ztree<k,v>, ?show: (k) -> string  ) : io ()
  t.show.println

pub fun print-trees( ts : list<ztree<k,v>>, ?show: (k) -> string  ) : io ()
  ts.show-trees.println


// sequence of accesses
pub fun seq( t : ztree<k,v>, access : (ztree<k,v>,k) -> e ztree<k,v>, accesses : list<k> ) : e list<ztree<k,v>>
  match accesses
    Nil -> []
    Cons(i,is) -> val t1 = t.access(i) in Cons(t1,seq(t1,access,is))

// Show sequence of accesses
pub fun seqprint( t0 : ztree<k,v>, access : (ztree<k,v>,k) -> <io|e> ztree<k,v>, accesses : list<k>, ?show: (k)->string ) : <io|e> ()
  println("original:\n")
  t0.show.println
  zip(accesses,seq(t0,access,accesses)).foreach fn((i,t))
    println("\naccess " ++ i.show ++ ":\n")
    t.show.println


pub fun render( t : ztree<k,v>, ?show: (k) -> string ) : render
  val minwidth = 3
  match t
    Leaf -> Render(0,[])
    Node(rnk,l,x,_,r) ->
      beside(l.render,"-" ++ (x.show ++ "@" ++ rnk.show).pad-left(minwidth) ++ "-",r.render)

fun indent( lines : list<string>, i : int ) : list<string>
  val sp = spaces(i)
  lines.map(fn(l) sp ++ l)

// --------------------------------------------------------------------------------------

fun node( l : ztree<k,v>, i : k, v: v, r : ztree<k,v>, ?hash: (k) -> int32) : ztree<k,v>
  val rnk = rank-of(i)
  Node(rnk,l,i,v,r)


// --------------------------------------------------------------------------------------
// Benchmarking

fun top( t : ztree<k,v> ) : exn k
  match t
    Leaf -> throw("top of empty tree")
    Node(_,_,x) -> x

fun max-height(t : ztree<k,v> ) : int
  match t
    Leaf          -> 0
    Node(_,l,_,_,r) -> 1 + max(max-height(l),max-height(r))

fun min-height(t : ztree<k,v> ) : int
  match t
    Leaf          -> 0
    Node(_,l,_,_,r) -> 1 + min(min-height(l),min-height(r))


fun sum-acc( t : ztree<int,v>, acc : int ) : int
  match t
    Leaf -> acc
    Node(_,l,x,_,r) -> sum-acc(r, sum-acc(l,acc + x))

fun sum(t : ztree<int,v>) : int
  sum-acc( t, 0 )

pub alias rndstate = sfc
alias rndres = sfc-result

fun rnd-step( r : rndstate ) : rndres
  sfc-step(r)

fun rnd-init( s0 : int, s1 : int ) : rndstate
  (sfc-init32(s0.int32,s1.int32))


fun bench-iter( i : int, n : int, access : (ztree<int,int>,int) -> ztree<int,int>, rs : rndstate, tree : ztree<int,int> ) : div (int,ztree<int,int>)
  if (i > 0) then
    val step = rnd-step(rs)
    val t = tree.access((step.rnd.int % n))
    bench-iter( i - 1, n, access, step.rstate, t)
  else
    (rnd-step(rs).rnd.int, tree)


pub fun bench( n : int, iter : int, access : (ztree<int,int>,int) -> ztree<int,int> ) : div (int,ztree<int,int>)
  bench-iter( n*iter, n, access, rnd-init(42,43), Leaf)

pub inline fun benchmain( access : (ztree<int,int>,int) -> ztree<int,int>, scaledown : int = 1) : io ()
  val n = get-args().head("").parse-int.default(100000)
  //val n = 50000
  val (i,t) = bench(n / scaledown, 100 / scaledown, access)
  val tp = top(t)
  val maxh = max-height(t)
  val minh = min-height(t)
  println("sum: " ++ sum(t).show ++ ", height: " ++ maxh.show ++ "/" ++ minh.show ++ ", top: " ++ tp.show ++ ", final access: " ++ i.show) // ++ ", size: " ++ size(t).show)
  //t.print