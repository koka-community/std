import std/data/rb-map
import std/fixpoint/lattice

// k = key, c = change, r = result
effect cache<k,c>
  fun add-result(k: k, r: c): ()
  fun is-cached(k: k): bool
  ctl depend(k: k): c

// Non determinism
effect each
  ctl each(s: list<a>): a
  final ctl none(): b

fun nondet(f: () -> <div,each|e> a): <div|e> ()
  with handler
    ctl each(ss)
      ss.foreach(resume)
    final ctl none() ()
    return (x) ()
  f()

// r = result, c = change, e = effect
value struct cache-entry<r,c,e>
  cache: r
  deps: list<(c -> <pure|e> ())>

fun remove-deps(m: rbmap<k,cache-entry<r,c,e>>): rbmap<k,r>
  m.map(fn(k, v) v.cache)

// A fixpoint cache handler
fun cache(change-lattice: change-lattice<r,c>, comp: () -> <pure,cache<k,c>,each|e> b, ?order2: (k, k) -> pure order2<k>, 
                                                ?k/show: k -> pure string, ?r/show: r -> pure string, ?c/show: c -> pure string): <pure|e> rbmap<k,r>
  val Change-lattice(bottom, join, changes) = change-lattice
  var cache : some<k,r,c,e> rbmap<k,cache-entry<r,c,e>> := empty()
  with return(x) cache.remove-deps
  with handler
    fun add-result(key, change)
      // trace("Adding result for " ++ k.k/show ++ " " ++ c.c/show)
      match cache.lookup(key)
        Just(Cache-entry(current, deps)) ->
          val (changed, new) = join(current, change)
          if changed then 
            cache := cache.set(key, Cache-entry(new, deps))
            deps.foreach(fn(resumption) resumption(change))
          else ()
        Nothing -> 
          cache := cache.set(key, Cache-entry(join(bottom, change).snd, []))
    fun is-cached(k)
      if cache.contains(k) then True
      else
        cache := cache.set(k, Cache-entry(bottom, []))
        False
    ctl depend(key)
      // trace("Adding dep for " ++ k.k/show)
      match cache.lookup(key)
        Just(Cache-entry(current, deps)) -> 
          cache := cache.set(key, Cache-entry(current, Cons(fn(change) resume(change), deps)))
          changes(current).foreach(fn(change) resume(change))
    return(x) ()
  nondet(comp)

// Inserts a memoization point at a recursive invocation
fun memo(key: k, func: () -> <cache<k,r>|e> r): <cache<k,r>|e> r
  match is-cached(key)
    True -> depend(key)
    False ->
      val res = func()
      add-result(key, res)
      res

fun example-fact()
  fun fact(n: int)
    with memo(n) 
    trace("Calculating fact of " ++ n.show)
    if n == 0 then LValue(1)
    else
      match fact(n - 1)
        LValue(m) -> LValue(n * m)
  
  val res = 
    cache(simple/change-lattice(int/(==)))
      fact(10)
  res.show.println