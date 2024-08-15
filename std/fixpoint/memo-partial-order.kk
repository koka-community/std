import std/data/linearset
import std/data/linearmap

effect cache<s,r>
  fun add-result(s: s, r: r): ()
  fun is-cached(s: s): bool
  ctl depend(s: s): r

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

fun cache(f: () -> <pure,cache<s,r>,each|e> b, ?(==): (s, s) -> div bool, ?join: (r, r) -> (bool, r), ?s/show: s -> string, ?r/show: r -> string): <pure|e> linearMap<s,r>
  var m : some<s,r> linearMap<s,r> := LinearMap([])
  var deps : some<s,r,e> linearMap<s, list<(r -> <pure|e> ())>> := LinearMap([])
  fun update(s, r)
    match deps.lookup(s)
      Just(resumes) -> 
        trace("Updating " ++ resumes.length.show ++ " deps for " ++ s.show ++ " with " ++ r.r/show)
        resumes.list/foreach(fn(res) {res(r); ()})
      Nothing -> ()
  val do = 
    with handler
      fun add-result(s, r)
        trace("Adding result for " ++ s.s/show ++ " " ++ r.r/show)
        match m.lookup(s)
          Just(r') ->
            val (changed, r'') = join(r', r)
            if changed then 
              m := m.set(s, r'')
              update(s, r'')
            else ()
          Nothing -> 
            m := m.set(s, r)
            update(s, r)
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
            update(s, r)
          Nothing -> ()
      return(x) ()
    with nondet
    f()
  m

fun memo(s, f)
  match is-cached(s)
    True -> depend(s)
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

fun test-fact()
  val res = 
    with cache
    fact(10)
  res.show.println

fun join(old: int, new: int): (bool, int)
  (False, new)