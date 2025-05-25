// Copied and derived from https://github.com/koka-lang/koka/tree/artifact-pldi24/test/artifact/pldi24

import std/data/rbtree
import std/data/tree-common
import std/os/env

import bu = std/data/rbtree-bu
import td = std/data/rbtree-td

import std/num/random
import std/num/int32
import std/test

// --------------------------------------------------------
// Show latex for a tree

pub fun print-tex( t : rbtree<k,v>, ?show: (k) -> string ) : io ()
  t.show-tex.println

pub fun show-tex( t : rbtree<k,v>, ?show: (k) -> string ) : div string
  "~ begin snippet\n\\begin{tikzpicture}[bintree,branchone]\n\\begin{scope}\\draw\n" ++
   tex-node(t).indent(2).unlines ++
    ";\n\\end{scope}\n\\end{tikzpicture}\n~ end snippet\n"

fun tex-node( t : rbtree<k,v>, ?show: (k) -> string ) : div list<string>
  match t
    Leaf -> []
    Node(c,l,x,_,r) ->
      val node = ["node[color=" ++ (if is-red(c) then "red" else "black") ++ "]{" ++ x.show ++ "}"]
      val children = match (l,r)
                       (Leaf,Leaf) -> []
                       _           -> tex-child(l) ++ tex-child(r)
      node ++ children

fun tex-child( t : rbtree<k,v>, ?show: (k) -> string ) : div list<string>
  match t
    Leaf -> ["child[missing]"]
    _    -> ["child{"] ++ tex-node(t).indent(2) ++ ["}"]

fun indent( lines : list<string>, i : int ) : list<string>
  val sp = spaces(i)
  lines.map(fn(l) sp ++ l)


// --------------------------------------------------------------------------------------
// Benchmarking

fun top( t : rbtree<int,v> ) : int
  match t
    Leaf -> 0
    Node(_,_,x,_,_) -> x

fun max-height(t : rbtree<k,v> ) : int
  match t
    Leaf          -> 0
    Node(_,l,_,_,r) -> 1 + max(max-height(l),max-height(r))

fun min-height(t : rbtree<k,v> ) : int
  match t
    Leaf          -> 0
    Node(_,l,_,_,r) -> 1 + min(min-height(l),min-height(r))

fun sum-acc( t : rbtree<int,v>, acc : int ) : int
  match t
    Leaf -> acc
    Node(_,l,x,_,r) -> sum-acc(r, sum-acc(l,acc + x))

fun sum(t : rbtree<int,v>) : int
  sum-acc( t, 0 )


pub alias rndstate = sfc
alias rndres = sfc-result

fun rnd-step( r : rndstate ) : rndres
  sfc-step(r)

fun rnd-init( s0 : int, s1 : int ) : rndstate
  (sfc-init32(s0.int32,s1.int32))

fun bench-iter( i : int, n : int, access : (rbtree<int,int>,int) -> div rbtree<int,int>, rs : rndstate, tree : rbtree<int,int> ) : div (int,rbtree<int,int>)
  if (i > 0) then
    val step = rnd-step(rs)
    val t = tree.access((step.rnd.int % n))
    bench-iter( i - 1, n, access, step.rstate, t)
  else
    (rnd-step(rs).rnd.int, tree)


pub fun bench( n : int, iter : int, access : (rbtree<int,int>,int) -> div rbtree<int,int> ) : div (int,rbtree<int,int>)
  bench-iter( n*iter, n, access, rnd-init(42,43), Leaf)

pub inline fun benchmain( access : (rbtree<int,int>,int) -> div rbtree<int,int>, scaledown : int = 1) : io ()
  val n = get-args().head("").parse-int.default(100000)
  //val n = 50000
  val (i,t) = bench(n / scaledown, 100 / scaledown, access)
  val tp = top(t)
  val maxh = max-height(t)
  val minh = min-height(t)
  println("sum: " ++ sum(t).show ++ ", height: " ++ maxh.show ++ "/" ++ minh.show ++ ", top: " ++ tp.show ++ ", final access: " ++ i.show) // ++ ", size: " ++ size(t).show)

pub fun bu/access(t : rbtree<int,int>, k : int) : rbtree<int,int>
  t.bu/set(k, k) // .set-black

pub fun td/access(t : rbtree<int,int>, k : int) : div rbtree<int,int>
  t.td/set(k, k)

fun make-tree-aux(n : int, t : rbtree<int,bool>) : div rbtree<int,bool>
  if n <= 0 then t else
    val n1 = n.dec
    make-tree-aux(n1, t.td/set(n1, n1 % 10 == 0))

pub fun make-tree(n : int) : div rbtree<int,bool>
  make-tree-aux(n, Leaf)

pub fun test-main()
  val n = get-args().head("").parse-int.default(4200000)
  val t = make-tree(n)
  time
    val v1 = t.fold(0) fn(l:int, r, k, v){ if v then r + l.inc else l + r }
    v1.show.println
  time 
    val v2 = t.buacc/fold(0) fn(l, k, v){ if v then l.inc else l }
    v2.show.println
  time
    val v3 = t.td/fold(0) fn(l, k, v){ if v then l.inc else l }
    v3.show.println
  time 
    // Zip is much slower in debug mode, but catches up if optimized (though it is still the slowest)
    // Apparently it has nothing to do with being the last one to use the tree and requiring deallocation (tried keeping a reference to the tree)
    // Probably has something to do with the administrative tail calls, does Koka not unroll tail calls?
    val v4 = t.fold(0, Done) fn(l, k, v){ if v then l.inc else l }
    v4.show.println

pub fun example-benchtd()  
  benchmain(td/access)

pub fun example-benchbu()  
  benchmain(bu/access)

pub fun check-valid(t1: rbtree<int,v>) : exn ()
  fun check(t: rbtree<int,v>, p: color, min: int, max: int) : exn int
    match t
      Node(b, l, k, _, r) ->
        if k < min || k > max then
          throw("Error key is invalid position")
        elif p.is-red && b.is-red then 
          throw("Error red-red")
        else 
          val leftb = check(l, b, min, k)
          val rightb = check(r, b, k, max)
          if leftb != rightb then
            throw("Error black height")
          else
            leftb + (if b.is-black then 1 else 0)
      Leaf -> 1
  check(t1, Red, -1000000, 100000)
  ()

pub fun bu/random-tree(n: int, r: int) : <exn,random> rbtree<int,int>
  if n == 0 then Leaf
  else 
    val t = bu/random-tree((n - 1).pretend-decreasing, r)
    t.check-valid()
    t.bu/set(random-int() % r, 0)

pub fun td/random-tree(n: int, r: int) : random rbtree<int,int>
  if n == 0 then Leaf
  else 
    val t = td/random-tree((n - 1).pretend-decreasing, r)
    t.td/set(random-int() % r, 0)

fun main()
  val r = 100
  val t = bu/random-tree(100, r)
  println(t)
  check-valid(t)