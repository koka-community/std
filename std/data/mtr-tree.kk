module mtr-tree

import std/os/env
import std/num/random
import std/num/int32
import std/num/int64
import tree-common

// A move to root tree
pub type tree<k,v>
  Leaf
  Node(left : tree<k,v>, key : k, value: v, right : tree<k,v>)

pub type root<k,v>
  Root(left : tree<k,v>, key : k, value: v, right : tree<k,v>)  


// ---------------------------------------------------------
// show and print trees

pub fun show( t : tree<k,v> , ?show: (k) -> string) : string
  t.render.lines.unlines

pub fun show-trees( ts : list<tree<k,v>> , ?show: (k) -> string) : string
  ts.map-indexed( fn(i,t) "tree " ++ show(i+1) ++ ":\n\n" ++ t.show ).join("\n\n")

pub fun print( t : tree<k,v>, ?show: (k) -> string ) : io ()
  t.show.println

pub fun print-trees( ts : list<tree<k,v>>, ?show: (k) -> string ) : io ()
  ts.show-trees.println


// sequence of accesses
pub fun seq( t : tree<k,v>, access : (tree<k,v>,k) -> e tree<k,v>, accesses : list<k> ) : e list<tree<k,v>>
  match accesses
    Nil -> []
    Cons(i,is) -> val t1 = t.access(i) in Cons(t1,seq(t1,access,is))

// Show sequence of accesses
pub fun seqprint( t0 : tree<k,v>, access : (tree<k,v>,k) -> <io|e> tree<k,v>, accesses : list<k>, ?show: (k) -> string ) : <io|e> ()
  println("original:\n")
  t0.show.println
  zip(accesses,seq(t0,access,accesses)).foreach fn((i,t))
    println("\naccess " ++ i.show ++ ":\n")
    t.show.println


pub fun render( t : tree<k,v>, ?show: (k) -> string ) : render
  val minwidth = 1
  match t
    Leaf -> Render(0,[])
    Node(l,x,_,r) ->
      beside(l.render, "-" ++ x.show.pad-left(minwidth) ++ "-", r.render)


// --------------------------------------------------------------------------------------
// Levy and Tarjan's test cases Fig 6. from "A New Path from Splay to Dynamic Optimality"

fun node( l : tree<k,k>, i : k, r : tree<k,k> ) : tree<k,k>
  Node(l,i,i,r)

pub val tIV = node(Leaf,1,node(Leaf,2,node(Leaf,3,node(Leaf,4,Leaf))))
pub val tV  = node(node(Leaf,1,node(node(Leaf,2,Leaf),3,Leaf)),4,Leaf)
pub val tVI = node(Leaf,1,node(node(node(Leaf,2,Leaf),3,Leaf),4,Leaf))
pub val tXI = node(node(node(node(Leaf,1,Leaf),2,Leaf),3,Leaf),4,Leaf)
pub val tXII= node(Leaf,1,node(node(Leaf,2,node(Leaf,3,Leaf)),4,Leaf)) 

fun rotate-left( xs : list<a>, n : int ) : list<a>
  xs.drop(n) ++ xs.take(n)

fun rotate-right( xs : list<a>, n : int ) : list<a>
  xs.reverse.rotate-left(n).reverse

// Trees corresponding to Fig 6 in Levy & Tarjan
pub fun alltrees(access) 
  val ts = [tV] ++ tV.seq(access,[1,3,4,1,2,4]) ++ [tXII] ++ tXII.seq(access,[4,2,1,4,3,1])
  ts.rotate-right(4)

// Unlike bottom-up, we cannot transition to V,VI and XII,XII states 
pub fun test1(access) -> tIV.seqprint(access,[4,3,1])         // weird: IV -> II -> III -> IV
pub fun test2(access) -> tV.seqprint(access,[1,3,4,1,2,4])    // ok: V -> VI -> VII -> VIII -> IX -> X -> XI
pub fun test3(access) -> tXI.seqprint(access,[1,2,4])         // weird: XI -> IX -> X -> XI
pub fun test4(access) -> tXII.seqprint(access,[4,2,1,4,3,1])  // ok: XII -> XIII -> XIV -> I -> II -> III -> IV

pub fun test5(access) -> tIV.seqprint(access,[4,1,3,4,1,2,4]) // IV -> ... -> XI  (half a cycle)
pub fun test6(access) -> tXI.seqprint(access,[1,4,2,1,4,3,1]) // XI -> ... -> IV  (half a cycle)

pub fun tleft( n : int ) 
  list(1,n).reverse.foldl(Leaf, fn(t,i) node(Leaf,i,t))


// --------------------------------------------------------------------------------------
// Benchmarking

fun size-acc( t : tree<int,v>, acc : int ) : int
  match t
    Leaf -> acc
    Node(l,_,_,r) -> size-acc(r, size-acc(l,acc + 1))

fun size(t : tree<int,v>) : int
  size-acc( t, 0 )

fun sum-acc( t : tree<int,v>, acc : int ) : int
  match t
    Leaf -> acc
    Node(l,x,_,r) -> sum-acc(r, sum-acc(l,acc + x))

fun sum(t : tree<int,v>) : int
  sum-acc( t, 0 )

fun top( t : tree<int,v> ) : int
  match t 
    Leaf -> 0
    Node(_,x,_,_) -> x

fun max-height(t : tree<int,v> ) : int
  match t
    Leaf          -> 0
    Node(l,_,_,r) -> 1 + max(max-height(l),max-height(r))

fun min-height(t : tree<int,v> ) : int
  match t
    Leaf          -> 0
    Node(l,_,_,r) -> 1 + min(min-height(l),min-height(r))


pub alias rndstate = sfc
alias rndres = sfc-result

fun rnd-step( r : rndstate ) : rndres
  sfc-step(r)

fun rnd-init( s0 : int, s1 : int ) : rndstate
  (sfc-init32(s0.int32,s1.int32))

fun bench-iter( i : int, n : int, access : (tree<int,v>,int) -> tree<int,v>, rs : rndstate, tree : tree<int,v> ) : div (int,tree<int,v>)
  if (i > 0) then
    val step = rnd-step(rs)
    val t = tree.access(step.rnd.int % n)
    bench-iter( i - 1, n, access, step.rstate, t)
  else 
    (rnd-step(rs).rnd.int, tree)

pub fun bench( n : int, iter : int, access : (tree<int,v>,int) -> tree<int,v> ) : div (int,tree<int,v>)
  bench-iter( n*iter, n, access, rnd-init(42,43), Leaf)

pub inline fun benchmain( access : (tree<int,v>,int) -> tree<int,v>, scaledown : int = 1) : io ()
  val n = get-args().head("").parse-int.default(100000)
  //val n = 50000
  val (i,t) = bench(n / scaledown, 100 / scaledown, access)
  val tp = top(t)
  val maxh = max-height(t)
  val minh = min-height(t)
  println("sum: " ++ sum(t).show ++ ", height: " ++ maxh.show ++ "/" ++ minh.show ++ ", top: " ++ tp.show ++ ", final access: " ++ i.show) // ++ ", size: " ++ size(t).show)
    //t.print