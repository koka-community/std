import std/core/undiv

effect nondet
  final ctl fail(): a
  final ctl fails(msg: string): a
  ctl choose(fs: list<v>): v

// Try several paths nondeterministically represented by unit computations 
fun list/try(funcs: list<() -> <nondet|e> a>): <nondet|e> a
  choose(funcs)()

// Try alternatives nondeterministically
fun two/try(f: () -> <nondet|e> a, g: () -> <nondet|e> a): <nondet|e> a
  choose([f, g])()

fun dfs/collect(action: () -> nondet a): list<a>
  with handler
    final ctl fail()
      []
    final ctl fails(msg)
      trace(msg)
      []
    ctl choose(fs)
      fs.map(resume).concat
    return(x)
      [x]
  action()

fun dfs/find(action: () -> nondet a): maybe<a>
  with handler
    final ctl fail()
      Nothing
    final ctl fails(msg)
      trace(msg)
      Nothing
    ctl choose(fs)
      fs.find-maybe(resume)
    return(x)
      Just(x)
  action()

fun get-best(l: list<a>, ?best: (a, a) -> e a): e maybe<a>
  match l
    Cons(a, rst) -> Just(rst.get-best-x(a))
    Nil -> Nothing

fun get-best-x(l: list<a>, best-so-far: a, ?best: (a, a) -> e a): e a
  match l
    Cons(a, rst) -> rst.get-best-x(best(a, best-so-far))
    Nil -> best-so-far

fun flatmap(l: list<f>, f: (f) -> e maybe<a>): e list<a>
  match l
    Nil -> []
    Cons(a, rst) ->
      match f(a)
        Nothing -> rst.flatmap(f)
        Just(x) -> Cons(x, rst.flatmap(f))

fun dfs/find-best(action: () -> nondet a, ?best: (a, a) -> e a): e maybe<a>
  with handler
    final ctl fail()
      Nothing
    final ctl fails(msg)
      trace(msg)
      Nothing
    ctl choose(fs)
      fs.flatmap(resume).get-best()
    return(x)
      Just(x)
  action()

fun bfs/collect(action: () -> nondet a): div list<a>
  // List of functions at the next depth level
  var queued := []
  // Cause further choices to be queued, instead of explored immediately
  var wait := False
  with handler
    final ctl fail()
      []
    final ctl fails(msg)
      trace(msg)
      []
    ctl choose(fs)
      fun process()
        val res = fs.map(resume).concat
        wait := False
        match queued
          [] -> res
          Cons(f, next) ->
            queued := next
            res ++ f()
      if !wait then 
        wait := True
        process()
      else
        queued := Cons(fn() process(), queued)
        []
    return(x)
      [x]
  action()


fun bfs/find(action: () -> nondet a): div maybe<a>
  // List of functions at the next depth level
  var queued := []
  // Cause further choices to be queued, instead of explored immediately
  var wait := False
  with handler
    final ctl fail()
      Nothing
    final ctl fails(msg)
      trace(msg)
      Nothing
    ctl choose(fs)
      fun process()
        val res = fs.find-maybe(resume)
        if res.is-just then res
        else 
          wait := False
          match queued
            [] -> res
            Cons(f, next) ->
              queued := next
              f()
      if !wait then 
        wait := True
        process()
      else
        queued := Cons(fn() process(), queued)
        Nothing
    return(x)
      Just(x)
  action()

fun bfs/find-best(action: () -> nondet a, ?best: (a, a) -> a): div maybe<a>
  // List of functions at the next depth level
  var queued := []
  // Cause further choices to be queued, instead of explored immediately
  var wait := False
  with handler
    final ctl fail()
      Nothing
    final ctl fails(msg)
      trace(msg)
      Nothing
    ctl choose(fs)
      fun process()
        val res = fs.flatmap(resume).get-best
        wait := False
        match queued
          [] -> res
          Cons(f, next) ->
            queued := next
            match res
              Nothing -> f()
              Just(x) -> 
                match f()
                  Just(y) -> Just(best(x, y))
                  Nothing -> Nothing
      if !wait then 
        wait := True
        process()
      else
        queued := Cons(fn() process(), queued)
        Nothing
    return(x)
      Just(x)
  action()