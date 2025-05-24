import std/core/undiv

effect nondet<s>
  final ctl fail(): a
  final ctl fails(msg: string): a
  ctl choose(fs: list<v>): v
  fun set-local(s: s): ()
  fun get-local(): s

// Try several paths nondeterministically represented by unit computations 
fun list/try(funcs: list<() -> <nondet<s>|e> a>): <nondet<s>|e> a
  choose(funcs)()

// Try alternatives nondeterministically
fun two/try(f: () -> <nondet<s>|e> a, g: () -> <nondet<s>|e> a): <nondet<s>|e> a
  choose([f, g])()

fun dfs/collect<s>(init : s, action: () -> nondet<s> a): div list<(a,s)>
  var local := init
  with handler
    final ctl fail()
      []
    final ctl fails(msg)
      trace(msg)
      []
    fun get-local()
      local
    fun set-local(l)  
      local := l
    ctl choose(fs)
      val l = local
      fs.map(fn(x) 
        local := l
        resume(x)
      ).concat
    return(x)
      [(x, local)]
  action()

fun bfs/collect<s>(init : s, action: () -> nondet<s> a): div list<(a,s)>
  var local := init
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
    fun get-local()
      local
    fun set-local(l)  
      local := l
    ctl choose(fs)
      val l = local
      fun process()
        val res = fs.map(fn(x) 
          local := l
          resume(x)
        ).concat
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
      [(x, local)]
  action()

fun example()
  bfs/collect(())
    try([{fail()}, {1}]) + try([{fail()}, {2}, {3}])
    
