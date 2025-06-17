pub import std/data/rb-map
import std/fixpoint/lattice

// k = key, r = result
effect cache<k,r>
  fun add-result(key: k, result: r): ()
  fun is-cached(key: k): bool
  ctl do-each(ss: list<a>): a
  final ctl none(): b
  ctl depend(key: k): r

// A fixpoint cache handler
fun cache(comp: () -> <pure,cache<k,r>|e> d, ?order2: (k, k) -> pure order2<k>, 
          .?change-lattice:change-lattice<b,r>, ?k/show: k -> string, ?r/show: r -> string): <pure|e> rbmap<k,b>
  var cache : some<k,r> rbmap<k,r> := empty()
  var deps : some<k,c,e> rbmap<k, list<(c -> <pure|e> ())>> := empty()
  fun update(key, change)
    match deps.lookup(key)
      Just(resumes) -> 
        // trace("Updating " ++ resumes.length.show ++ " deps for " ++ s.show ++ " with " ++ c.c/show)
        resumes.list/foreach(fn(resumption) {resumption(change); ()})
      Nothing -> ()
  handle(comp)
    fun add-result(key, change)
      // trace("Adding result for " ++ s.s/show ++ " " ++ c.c/show)
      match cache.lookup(key)
        Just(r') ->
          val (changed, r'') = join(r', change)
          if changed then 
            cache := cache.set(key, r'')
            update(key, change)
          else ()
        Nothing -> 
          cache := cache.set(key, bottom.join(change).snd)
          update(key, change)
    fun is-cached(key)
      if cache.contains(key) || deps.contains(key) then True
      else
        cache := cache.set(key, bottom)
        deps := deps.set(key, Nil)
        False
    ctl depend(key)
      // trace("Adding dep for " ++ s.s/show)
      match deps.lookup(key)
        Just(resumes) ->
          val ress = Cons(fn(r) resume(r), resumes)
          deps := deps.set(key, ress)
      match cache.lookup(key)
        Just(r) -> r.changes.foreach(fn(change) resume(change))
    ctl do-each(ss)
      ss.foreach(fn(s) resume(s))
    final ctl none()
      ()
    return(x) ()
  cache

// Inserts a memoization point at a recursive invocation
fun memo(key : k, func : ((list<() -> <cache<k,r>|e> r>) -> <cache<k,r>|e> r) -> <cache<k,r>|e> r): <cache<k,r>|e> r
  match is-cached(key)
    True -> depend(key)
    False -> func(fn(ls) fix/each(key, ls))

fun fix/each(key: k, ls: list<(() -> <cache<k,r>|e> r)>): <cache<k,r>|e> r
  val func = do-each(ls)
  val result = func()
  add-result(key, result)
  result