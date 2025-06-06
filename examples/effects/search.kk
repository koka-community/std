import std/effects/search
import std/core/undiv

type tree
  Leaf
  Node(left: tree, v: int, right: tree)

effect etree
  fun fresh(): int

fun build(i: int): etree tree
  if i > 0 then
    val level = (i - 1)
    Node(build(level.pretend-decreasing), fresh(), build(level.pretend-decreasing))
  else Leaf

fun make-tree(action: () -> etree tree): tree
  var unique := 0
  with handler
    fun fresh()
      val u = unique
      unique := u + 1
      u
  action()

fun show(t: tree)
  match t
    Node(l, v, r) -> "Node(" ++ l.show ++ "," ++ v.show ++ "," ++ r.show ++ ")"
    Leaf -> "_"

fun add-chain(t: tree)
  match t 
    Node(l, v, r) ->
      trace(v.show)
      v + try([{add-chain(l)}, {add-chain(r)}])
    Leaf -> 0

fun example()
  val t = make-tree({build(3)})
  t.println
  val program = fn() add-chain(t)
  bfs/collect(program).println
  dfs/collect(program).println
  bfs/find(program).println
  dfs/find(program).println
  bfs/find-best(program, ?best = min).println
  dfs/find-best(program, ?best = min).println
  bfs/find-best(program, ?best = max).println
  dfs/find-best(program, ?best = max).println


    