named effect let<a>
  fun get(): a
  fun set-internal(a: a): ()

fun let(a: a, f: (ev<let<a>> -> e b)): e b
  var v := a
  named handle(f) 
    fun get() v 
    fun set-internal(new) v := new

fun (!)(e : ev<let<maybe<a>>>, ?kk-file-line: string): pure a 
  match e.get
    Just(x) -> x
    Nothing -> throw("let variable is undefined at " ++ kk-file-line) 
  
fun basic/set(e: ev<let<a>>, a: a, f: () -> <pure|e> ()): <pure|e> ()
  val orig = e.get
  with finally { e.set-internal(orig) }
  e.set-internal(a)

fun maybe/set(e: ev<let<maybe<a>>>, a: a, f: () -> <pure|e> ()): <pure|e> ()
  e.set(Just(a), f)