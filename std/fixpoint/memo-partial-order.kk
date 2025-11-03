import std/data/rb-set
import std/data/rb-map

// k = key, r = result
effect cache<k,r>
  fun add-result(s: k, r: r): ()
  fun is-cached(s: k): bool
  ctl depend(s: k): r

// Non determinism
effect each
  ctl each(s: list<a>): a
  final ctl none(): b

fun nondet(f: () -> <div,each|e> a): <div|e> ()
  with handler
    ctl each(ss)
      ss.foreach(resume)
    final ctl none()
      ()
    return (x)
      ()
  f()

// r = result, c = change, e = effect
value struct cache-entry<r,e>
  cache: r
  deps: list<(r -> <pure|e> ())>

fun remove-deps(m: rbmap<k,cache-entry<r,e>>): rbmap<k,r>
  m.map(fn(k, v: cache-entry<_,_>) v.cache)

// A fixpoint cache handler
fun cache(comp: () -> <pure,cache<k,r>,each|e> b, ?order2: (k, k) -> pure order2<k>, 
                                                ?bottom: r,
                                                ?join: (r, r) -> (bool, r), 
                                                ?s/show: k -> string, ?r/show: r -> string): <pure|e> rbmap<k,r>
  var cache : some<k,r,e> rbmap<k,cache-entry<r,e>> := empty()
  with return(x) cache.remove-deps
  with handler
    fun add-result(key, change)
      // trace("Adding result for " ++ s.s/show ++ " " ++ r.r/show)
      match cache.lookup(key)
        Just(Cache-entry(result, deps)) ->
          val (changed, new) = join(result, change)
          if changed then 
            cache := cache.set(key, Cache-entry(new, deps))
            deps.foreach(fn(resumption) resumption(change))
          else ()
        Nothing -> 
          cache := cache.set(key, Cache-entry(change, []))
    fun is-cached(key)
      if cache.contains(key) then True
      else
        cache := cache.set(key, Cache-entry(bottom, []))
        False
    ctl depend(key)
      // trace("Adding dep for " ++ s.s/show)
      match cache.lookup(key)
        Just(Cache-entry(current, deps)) -> 
          cache := cache.set(key, Cache-entry(current, Cons(fn(change) resume(change), deps)))
          resume(current)
    return(x) ()
  with nondet
  comp()

// Inserts a memoization point at a recursive invocation
fun memo(key, func)
  match is-cached(key)
    True -> depend(key)
    False ->
      val result = func()
      add-result(key, result)
      result

fun fact(n: int)
  with memo(n) 
  trace("Calculating fact of " ++ n.show)
  if n == 0 then
    1
  else
    n * fact(n - 1)

val int/bottom = 0

fun example-fact()
  val res = 
    with cache
    fact(10)
  res.show.println

fun join(old: int, new: int): (bool, int)
  (False, new)