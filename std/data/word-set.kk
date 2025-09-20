import std/data/trie
import std/data/intern
import std/core/unsafe
import std/core/undiv

alias word-set = trie

inline fun empty-word-set(): word-set
  empty()

inline fun contains(t: word-set, s: string): bool
  lookup(t, s).is-just

inline fun has-word(t: word-set, s: string): bool
  lookup(t, s).is-just

inline fun is-in(s: string, t: word-set): bool
  lookup(t, s).is-just

inline fun member(s: string, t: word-set): bool
  lookup(t, s).is-just

named effect string-intern
  fun intern-string(x: string): istring
  fun is-interned(x: string): bool

value struct istring
  str: string

val interned-strings : ev<string-intern> = string-pool()
val words = interned-strings

fun string-pool(): <> ev<string-intern>
  var trie := empty-word-set()
  with r <- named handler
    fun intern-string(a)
      match trie.lookup(a)
        Just(s) -> Istring(s)
        Nothing ->
          std/core/types/@byref(trie).update(fn(v) add(v, a))
          Istring(a)
    fun is-interned(a)
      trie.lookup(a).is-just
  r

inline fun add-all(s: ev<string-intern>, xs: list<string>): exn ev<string-intern>
  xs.foreach(fn(x) {s.intern-string(x); ()})
  s

inline fun intern(s: string): exn istring
  words.intern-string(s)

inline fun show(s: istring): string
  s.str.show

inline fun cmp(x: istring, y: istring): order
  x.str.cmp(y.str)

inline fun order2(x: istring, y: istring): order2<string>
  x.str.order2(y.str)

inline fun (<)(x: istring, y: istring): bool
  x.str < y.str

inline fun (<=)(x: istring, y: istring): bool
  x.str <= y.str

inline fun (>)(x: istring, y: istring): bool
  x.str > y.str

inline fun (>=)(x: istring, y: istring): bool
  x.str >= y.str

inline fun (==)(x: istring, y: istring): bool
  unsafe-ptr-eq(x.str, y.str)

fun example()
  val a = intern("A quick brown fox jumps over the lazy dog")
  val a2 = intern("A quick brown fox jumps over the lazy dog")
  println(a)
  println(a2)
  (a == a2).println

fun example-x()
  val pool = string-pool().add-all(["infix", "infixr", "infixl", "in"])
  pool.is-interned("infixr").println
