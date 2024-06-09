import std/data/rbtree
import std/data/tree-common
import std/os/env

import bu = std/data/rbtree-bu

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

fun bench-iter( i : int, n : int, access : (rbtree<int,v>,int) -> div rbtree<int,v>, rs : rndstate, tree : rbtree<int,v> ) : div (int,rbtree<int,v>)
  if (i > 0) then
    val step = rnd-step(rs)
    tree.show.println
    val t = tree.access((step.rnd.int % n))
    bench-iter( i - 1, n, access, step.rstate, t)
  else
    (rnd-step(rs).rnd.int, tree)


pub fun bench( n : int, iter : int, access : (rbtree<int,v>,int) -> div rbtree<int,v> ) : div (int,rbtree<int,v>)
  bench-iter( n*iter, n, access, rnd-init(42,43), Leaf)

pub inline fun benchmain( access : (rbtree<int,v>,int) -> div rbtree<int,v>, scaledown : int = 1) : io ()
  val n = get-args().head("").parse-int.default(100000)
  //val n = 50000
  val (i,t) = bench(n / scaledown, 100 / scaledown, access)
  val tp = top(t)
  val maxh = max-height(t)
  val minh = min-height(t)
  println("sum: " ++ sum(t).show ++ ", height: " ++ maxh.show ++ "/" ++ minh.show ++ ", top: " ++ tp.show ++ ", final access: " ++ i.show) // ++ ", size: " ++ size(t).show)

fun main()  
  benchmain(access)

pub fun access(t : rbtree<int,v>, k : int) : rbtree<int,v>
  rbtree-bu/find(t, k, k, Done) // .set-black
