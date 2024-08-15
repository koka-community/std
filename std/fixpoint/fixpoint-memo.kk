import std/data/linearset
import std/data/linearmap

effect cache<s,c>
  fun add-result(s: s, r: c): ()
  fun add-state(s: s): ()
  fun is-cached(s: s): bool
  ctl do-each(ss: list<a>): a
  final ctl none(): b
  ctl depend(s: s): c

fun cache(f: () -> <pure,cache<s,c>|e> b, ?(==): (s, s) -> div bool, ?bottom: r, ?join: (r, c) -> (bool, r), ?changes: (r) -> list<c>, ?s/show: s -> string, ?c/show: c -> string): <pure|e> linearMap<s,r>
  var m : some<s,r> linearMap<s,r> := LinearMap([])
  var deps : some<s,c,e> linearMap<s, list<(c -> <pure|e> ())>> := LinearMap([])
  fun update(s, c)
    match deps.lookup(s)
      Just(resumes) -> 
        trace("Updating " ++ resumes.length.show ++ " deps for " ++ s.show ++ " with " ++ c.c/show)
        resumes.list/foreach(fn(res) {res(c); ()})
      Nothing -> ()
  val do = 
    with handler
      fun add-state(s)
        m := m.set(s, bottom)
      fun add-result(s, c)
        trace("Adding result for " ++ s.s/show ++ " " ++ c.c/show)
        match m.lookup(s)
          Just(r') ->
            val (changed, r'') = join(r', c)
            if changed then 
              m := m.set(s, r'')
              update(s, c)
            else ()
          Nothing -> 
            m := m.set(s, ?bottom.join(c).snd)
            update(s, c)
      fun is-cached(s)
        m.contains-key(s)
      ctl depend(s)
        trace("Adding dep for " ++ s.s/show)
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

fun swap(a: int, b: int)
  with each <- memo((a,b))
  trace("Calculating fact of " ++ a.show ++ " " ++ b.show)
  each([{(b,a)}, {swap(b,a)}])

fun test-swap()
  val res = 
    with cache
    swap(0, 1)
  res.show.println

fun join(old: list<(int, int)>, new: (int, int)): (bool, list<(int,int)>)
  if old.any(fn(x) x == new) then (False, old) else (True, Cons(new, old))

val bottom = []

fun changes(x: list<(int, int)>): list<(int, int)>
  x
