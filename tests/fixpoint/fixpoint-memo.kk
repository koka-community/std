import std/fixpoint/fixpoint-memo
import std/fixpoint/lattice

fun swap(a: int, b: int)
  with each <- memo((a,b))
  trace("Calculating fact of " ++ a.show ++ " " ++ b.show)
  each([{(b,a)}, {swap(b,a)}])

fun test-swap()
  val res: linearMap<(int, int), list<(int, int)>> = 
    with cache
    swap(0, 1)
  res.show.println
