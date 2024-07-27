import std/data/linearmap
import std/core/unsafe
import std/core/undiv
import std/test

type trie
  Root(children: linearMap<char,trie>)
  // We cache the count of the partial string to avoid recomputing it, we also keep track if this node represents a complete string
  Trie(offset: int, part: string, pcount: int, value: string, full: bool, children: linearMap<char,trie>)

fun empty()
  Root(LinearMap([]))

// Looking up a string from the trie
pub fun str/lookup(t: trie, k: string): maybe<string>
  with pretend-no-div
  t.lookup(k.slice, k.count)

inline fun lookup-child(m: linearMap<char,trie>, full: bool, v: string, kn: sslice, kncount: int): div maybe<string>
  match kn.next
    Nothing -> if full then Just(v) else Nothing
    Just((char, k')) ->
      val sub = m.lookup(char)
      match sub 
        Nothing -> Nothing
        Just(s) -> lookup(s, k', kncount - 1)

fun slice/lookup(t: trie, k: sslice, kcount: int): div maybe<string>
  match t
    Root(m) -> lookup-child(m, False, "", k, kcount)
    Trie(_, p, pcount, v, full, m) -> 
      if k.is-prefixed-by(p.slice, kcount, pcount) then
        lookup-child(m, full, v, k.drop(pcount), kcount - pcount)
      else Nothing

// Adding a string to the trie
pub fun add(t: trie, s: string): trie
  with pretend-no-div
  bind(t, s.slice, s, s.slice.count)

fun unsafe1/not-reachable(): div a
  unsafe2/not-reachable()

fun unsafe2/not-reachable(): div a
  unsafe1/not-reachable()

fun unsafe/not-reachable(): a
  with pretend-no-div
  unsafe1/not-reachable()

inline fun bind-map(m: linearMap<char,trie>, full: bool, p: string, v: string, kchar: char, kn: sslice, ksfull: string, offset: int, pcount: int, kcount': int): div trie
    val sub = m.lookup(kchar)
    match sub
      Nothing -> Trie(offset, p, pcount, v, full, m.set(kchar, Trie(offset + pcount + 1, kn.string, kcount' - 1, ksfull, True, LinearMap([]))))
      Just(sub) -> Trie(offset, p, pcount, v, full, m.set(kchar, bind(sub.pretend-decreasing, kn, ksfull, kcount' - 1)))

fun internal/bind(t: trie, k: sslice, original: string, kcount: int): div trie
  match t
    Root(m) ->
      Trie(0, original, kcount, original, True, m)
    Trie(offset, p, pcount, v, full, m) ->
      fun common-prefix(k': sslice, p': sslice, acc: sslice, acccount: int)
        match (k'.next, p'.next)
          (Just((chark, k'')), Just((charp, p''))) -> 
            if chark == charp then
              common-prefix(k''.pretend-decreasing, p'', acc.extend(1), acccount + 1)
            else
              val accoffset = offset + acccount
              val childoffset = accoffset + 1
              val m' = LinearMap([
                (chark, Trie(childoffset, k''.string, k''.count, original, True, LinearMap([]))),
                (charp, Trie(childoffset, p''.string, p''.count, v, full, m)) 
              ])
              Trie(offset, acc.string, acccount, v.slice.truncate.extend(accoffset).string, False, m')
          (Just((chark, k'')), Nothing) ->
            bind-map(m, full, p, v, chark, k'', original, offset, pcount, kcount - pcount)
          (Nothing, Just((charp, p''))) ->
            bind-map(m, full, k.string, original, charp, p'', v, offset, kcount, pcount - kcount)
          (Nothing, Nothing) -> Trie(offset, p, pcount, v, True, m)
          _ -> unsafe/not-reachable()
      common-prefix(k, p.slice, k.truncate, 0)

fun is-prefixed-by(a: sslice, b: sslice, acount: int, bcount: int): bool
  bcount <= acount &&
    a.take(bcount) == b

fun trie/show(t: trie): div string
  match t
    Root(m) -> "Root(" ++ m.show ++ ")"
    Trie(offset, p, pcount, v, full, m) -> "Trie(" ++ offset.show ++ ", " ++ p.show ++ ", " ++ pcount.show ++ ", " ++ v.show ++ ", " ++ full.show ++ " " ++ m.show ++ ")"

fun test-trie()
  val t = trie/empty().add("Hello")
  val t1 = t.add("World").add("Worship")
  trace(t1.show)
  basic/test("trie lookup")
    expect(Just("Hello"))
      t1.lookup("Hello")
    expect(Just("Worship"))
      t1.lookup("Worship")
    expect(Nothing)
      t1.lookup("Wor")
      