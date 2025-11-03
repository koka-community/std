// Copied and derived from https://github.com/koka-lang/koka/tree/artifact-pldi24/test/artifact/pldi24

import std/data/rbtree
import std/data/tree-common
import std/os/env

import std/data/rbtree-bu
import std/data/rbtree-td

import std/num/random
import std/num/int32
import std/test
import std/core/unsafe

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
  lines.map(sp ++ _)


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
  val n = get-args().head("").parse-int.default(1000000)
  //val n = 50000
  val (i,t) = bench(n / scaledown, 10 / scaledown, access)
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
  check(t1, Red, -100000000, 100000000)
  ()

pub fun bu/random-tree(n: int, r: int, acc: rbtree<int,int>) : <exn,random> rbtree<int,int>
  if n == 0 then acc
  else 
    val rnd = random-int() % r
    bu/random-tree((n - 1).pretend-decreasing, r, acc.bu/set(rnd, 0))    

pub fun td/random-tree(n: int, r: int) : random rbtree<int,int>
  if n == 0 then Leaf
  else 
    val t = td/random-tree((n - 1).pretend-decreasing, r)
    t.td/set(random-int() % r, 0)

fun test-delete-many()
  for(100) fn(i)
    // val i = 95
    trace(i.show)
    with pseudo-random(i)
    val r = 10000
    val t = bu/random-tree(10000, r, Leaf)
    trace("Built tree")
    check-valid(t)
    // println(t)
    fun delete-check(t0:rbtree<int,int>)
      if t0.is-leaf then ()
      else
        val k = random-int() % r
        if t0.contains(k) then 
          val t1 = t0.bu/remove(k)
          // println("\n\n\n")
          // println(t1)
          check-valid(t1)
          if t1.is-leaf then ()
          else delete-check(t1)
        else 
          delete-check(t0)    
          
    trace("Start delete")
    delete-check(t)
  println("All tests passed")


val t1 : rbtree<int,int> = Node(Black, 
    Node(Black, Leaf, 0, 0, Leaf), 
    4,
    4,
    Node(Black, 
      Node(Red, Leaf, 5, 5, Leaf),
      6,
      6,
      Node(Red, Leaf, 9, 9, Leaf)
    )
  )

val t1' : rbtree<int,int> = Node(Black, 
    Node(Black, Leaf, 0, 0, Leaf), 
    5,
    5,
    Node(Black, 
      Leaf,
      6,
      6,
      Node(Red, Leaf, 9, 9, Leaf)
    )
  )

val t1'' : rbtree<int,int> = Node(Black, 
    Node(Black, Leaf, 0, 0, Leaf), 
    6,
    6,
    Node(Black, Leaf, 9, 9, Leaf)
  )


fun test-delete1()
  val res = t1.bu/remove(4) 
  (res == t1').show.println
  res.check-valid()

  val res' = t1'.bu/remove(5)
  (res' == t1'').show.println
  res'.println
  res'.check-valid()

val t2 = Node(Black, 
    Node(Black,
      Node(Red, Leaf, 1, 1, Leaf),
      4, 4,
      Node(Red, Leaf,5, 5, Leaf)),
    6, 6,
    Node(Black, 
      Node(Red, Leaf, 7, 7, Leaf),
      9, 9,
      Leaf
    )
  )



fun test-remove2x()
  val t2' = t2.bu/remove(6)
  println(t2')
  val res = t2'.bu/remove(7)
  println(res)
  res.check-valid()

val t3 = Node(Black, 
    Node(Red,
      Node(Black, Leaf, 0, 0, Node(Red, Leaf, 1, 1, Leaf)),
      2, 2,
      Node(Black, Leaf,3, 3, Leaf)),
    4, 4,
    Node(Black, 
      Leaf,
      6, 6,
      Node(Red, Leaf, 8, 8, Leaf)
    )
  )


fun test-remove3x()
  println(t3)
  val res = t3.bu/remove(2)
  println(res)
  res.check-valid()


val t4 = Node(Black, 
    Node(Black,
      Node(Black, Leaf, 1, 1, Leaf),
      2, 2,
      Node(Black, Leaf, 4, 4, Leaf)),
    9, 9,
    Node(Black, 
      Node(Black, Leaf, 10, 10, Node(Red, Leaf, 11, 11, Leaf)),
      12, 12,
      Node(Black, Leaf, 13, 13, Leaf)
    )
  )

fun test-remove4x()
  println(t4)
  val res = t4.bu/remove(4)
  println(res)
  res.check-valid()

val t5 = Node(Black, 
    Node(Black,
      Node(Black, Leaf, 0, 0, Leaf),
      2, 2,
      Node(Black, Leaf, 7, 7, Leaf)),
    9, 9,
    Node(Black, 
      Node(Black, Leaf, 11, 11, Leaf),
      12, 12,
      Node(Black, Leaf, 13, 13, Leaf)
    )
  )

fun test-remove5x()
  println(t5)
  val res = t5.bu/remove(2)
  println(res)
  res.check-valid()


val t6 = Node(Black, 
    Node(Black, Leaf, 0, 0, Node(Red, Leaf, 2, 2, Leaf)),
    6, 6,
    Node(Red, 
      Node(Black, Leaf, 8, 8, Leaf),
      9, 9,
      Node(Black, Leaf, 12, 12, Leaf)
    )
  )

fun test-remove6x()
  println(t6)
  val res = t6.bu/remove(6)
  println(res)
  res.check-valid()
// fun main()
//   val r = 10
//   val t = td/random-tree(10, r)
//   println(t)
//   fun delete-check(t0: rbtree<int,int>)
//     val k = random-int() % r
//     println(k)
//     val t1 = t0.td/remove(k)
//     println(t1)
//     check-valid(t1)
//     if t1.is-leaf then ()
//     else delete-check(t1)
//   delete-check(t)
//   println("All tests passed")

fun test-cases()
  val t1 = Node(Black, Node(Black, Leaf, 2, 2, Leaf), 3, 3, Node(Red, Node(Black, Leaf, 4, 4, Leaf), 5, 5, Node(Black, Leaf, 9, 9, Leaf)))
  t1.show.trace
  trace("  ")
  val t2 = t1.bu/remove(3)
  t2.show.trace
  t2.check-valid()
  ()

fun test()
  test-cases()
  test-delete1()
  test-remove2x()
  test-remove3x()
  test-remove4x()
  test-remove5x()
  test-remove6x()
  test-delete-many()