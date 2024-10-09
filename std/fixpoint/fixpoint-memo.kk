pub import std/data/rb-map
import std/fixpoint/lattice

effect cache<s,c>
  fun add-result(s: s, r: c): ()
  fun add-state(s: s): ()
  fun is-cached(s: s): bool
  ctl do-each(ss: list<a>): a
  final ctl none(): b
  ctl depend(s: s): c

fun cache(f: () -> <pure,cache<s,c>|e> b, ?order2: (s, s) -> pure order2<s>, .?change-lattice:change-lattice<r,c>, ?s/show: s -> string, ?c/show: c -> string): <pure|e> rbmap<s,r>
  var m : some<s,r> rbmap<s,r> := empty()
  var deps : some<s,c,e> rbmap<s, list<(c -> <pure|e> ())>> := empty()
  fun update(s, c)
    match deps.lookup(s)
      Just(resumes) -> 
        // trace("Updating " ++ resumes.length.show ++ " deps for " ++ s.show ++ " with " ++ c.c/show)
        resumes.list/foreach(fn(res) {res(c); ()})
      Nothing -> ()
  val do = 
    with handler
      fun add-state(s)
        m := m.set(s, bottom)
      fun add-result(s, c)
        // trace("Adding result for " ++ s.s/show ++ " " ++ c.c/show)
        match m.lookup(s)
          Just(r') ->
            val (changed, r'') = join(r', c)
            if changed then 
              m := m.set(s, r'')
              update(s, c)
            else ()
          Nothing -> 
            m := m.set(s, bottom.join(c).snd)
            update(s, c)
      fun is-cached(s)
        m.contains(s)
      ctl depend(s)
        // trace("Adding dep for " ++ s.s/show)
        match deps.lookup(s)
          Just(resumes) ->
            val ress = Cons(fn(r) resume(r), resumes)
            deps := deps.set(s, ress)
          Nothing -> 
            deps := deps.set(s, [fn(r) resume(r)])
        match m.lookup(s)
          Just(r) -> 
            r.changes.foreach(fn(c) update(s, c))
          Nothing -> ()
      ctl do-each(ss)
        ss.foreach(fn(s) resume(s))
      final ctl none()
        ()
      return(x) ()
    f()
  m

fun memo(s, f)
  match is-cached(s)
    True -> depend(s)
    False ->
      add-state(s)
      f(fn(ls) fix/each(s, ls))

fun fix/each(s: s, ls: list<(() -> <cache<s,c>|e> c)>): <cache<s,c>|e> c
  val f = do-each(ls)
  val r = f()
  add-result(s,r)
  r