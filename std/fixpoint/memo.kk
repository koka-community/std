import std/data/linearset
import std/data/linearmap

effect cache<s,r>
  fun add-result(s: s, r: r): ()
  fun is-cached(s: s): bool
  ctl get-cached(s: s): r

// Non determinism
effect each
  ctl each(s: list<a>): a
  final ctl none(): b

fun nondet(f: () -> <div,each|e> a): <div|e> ()
  with handler
    ctl each(ss)
      ss.foreach(fn(s) resume(s))
    final ctl none()
      ()
    return (x)
      ()
  f()

fun cache(f: () -> <div,cache<s,r>,each|e> r, ?(==): (s, s) -> div bool): <div|e> linearMap<s,r>
  var m := LinearMap([])
  with handler
    fun add-result(s, r)
      m := m.set(s, r)
    fun is-cached(s)
      m.contains-key(s)
    ctl get-cached(s)
      match m.lookup(s)
        Just(r) -> resume(r)
        Nothing -> m
    return(x) m
  with nondet
  f()

fun memo(s, f)
  match is-cached(s)
    True -> get-cached(s)
    False ->
      val r = f()
      add-result(s, r)
      r

fun fact(n: int)
  with memo(n) 
  trace("Calculating fact of " ++ n.show)
  if n == 0 then
    1
  else
    n * fact(n - 1)

fun fib(n: int)
  with memo(n) 
  trace("Calculating fib of " ++ n.show)
  if n == 0 || n == 1 then
    n
  else
    int/(+)(fib(n - 1), fib(n - 2))

fun test-fact()
  val res = 
    with cache
    fact(10)
  res.show.println

fun test-fib()
  val res = 
    with cache
    fib(10)
  res.show.println
