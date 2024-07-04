import std/data/rbtree
import std/data/tree-common
import std/os/env

import bu = std/data/rbtree-bu
import td = std/data/rbtree-td

import std/num/random
import std/num/int32

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

// pub fun test-main()
//   val n = get-args().head("").parse-int.default(4200000)
//   val t = make-tree(n)
//   val v = t.fold(0) fn(l, r, k, v){ if (v) then r.inc else r }
//   v.show.println

pub fun bench-main()  
  benchmain(td/access)


pub fun check-valid(t1: rbtree<int,v>) : exn ()
  fun check(t: rbtree<int,v>, p: color, min: int, max: int) : exn ()
    match t
      Node(b, l, k, _, r) ->
        if k < min || k > max then
          throw("Error key is invalid position")
        elif p.is-red && b.is-red then throw("Error red-red")
        else 
          check(l, b, min, k)
          check(r, b, k, max)
      Leaf -> ()
  check(t1, Red, -1000000, 100000)

pub fun bu/random-tree(n: int, r: int) : random rbtree<int,int>
  if n == 0 then Leaf
  else 
    val t = bu/random-tree((n - 1).pretend-decreasing, r)
    t.bu/set(random-int() % r, 0)

pub fun td/random-tree(n: int, r: int) : random rbtree<int,int>
  if n == 0 then Leaf
  else 
    val t = td/random-tree((n - 1).pretend-decreasing, r)
    t.td/set(random-int() % r, 0)

// fun main()
//   val r = 10000
//   val t = bu/random-tree(10000, r)
//   // println(t)
//   check-valid(t)
//   fun delete-check(t0)
//     val k = random-int() % r
//     val t1 = t0.bu/remove(k)
//     check-valid(t1)
//     if t1.is-leaf then ()
//     else delete-check(t1)
//   delete-check(t)
//   println("All tests passed")
fun main()
  val r = 10
  val t = td/random-tree(10, r)
  println(t)
  fun delete-check(t0: rbtree<int,int>)
    val k = random-int() % r
    println(k)
    val t1 = t0.td/remove(k)
    println(t1)
    check-valid(t1)
    if t1.is-leaf then ()
    else delete-check(t1)
  delete-check(t)
  println("All tests passed")