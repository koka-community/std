import std/data/vector-list
import std/core-extras

scoped effect interner<s::S>
  ctl interner<a>(eq: (a,a) -> pure bool): ev<intern<s,a>>

fun make-interner<s>(?(==): (a,a) -> pure bool): <interner<s>> ev<intern<s,a>>
  interner(?(==))

named effect intern<s::S,a::V> in interner<s>
  fun intern(x: a): intern-ref<a>

value type intern-ref<a>
  Interned(idx: int, a: a)

fun intern-creator(action: forall<s> () -> <interner<s>,pure|e> a) : <pure|e> a
  with ctl interner(eq) with-new-pool(eq, resume)
  action()

fun with-new-pool(eq: (a,a) -> <find<intern-ref<a>>,div|e> bool, action: (ev<intern<s,a>>) -> <div|e> b): <div|e> b
  var vec: some<a> vlist<a> := vlist()
  with r <- named handler
    fun intern(a: some<a> a)
      with find
      val v = vec
      mask<local>
        v.foreach-indexed fn(i,x)
          if eq(a,x) then found(Interned(i,x))
          else ()
      vec := v.push(a)
      // Weak map, when the interned values are dropped, the concrete value will also be dropped, but unfortunately not the vector memory
      a.unsafe-box-drop 
      Interned(vec.size - 1, a)
  mask<local>{action(r)}

fun (==)(x: intern-ref<a>, y: intern-ref<a>): bool
  x.idx == y.idx

val strs : some<s> delayed<<pure,interner<s>>,ev<intern<s,string>>> = delay({interner(string/(==))})

fun s-intern(s: string): <pure,interner<s>> intern-ref<string>
  strs.force.intern(s)

fun test()
  with intern-creator
  
  val a = s-intern("a")
  val b = s-intern("b")
  val anothera = s-intern("a")
  println(a == b)
  println(a == anothera)
