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

fun unsafe1/not-reachable(): div a
  unsafe2/not-reachable()

fun unsafe2/not-reachable(): div a
  unsafe1/not-reachable()

fun unsafe/not-reachable(): a
  with pretend-no-div
  unsafe1/not-reachable()

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

inline fun bind-map(m: linearMap<char,trie>, full: bool, p: string, v: string, kn: sslice, ksfull: string, offset: int, pcount: int, kcount': int): div trie
  match kn.next
    Nothing -> Trie(offset, p, pcount, v, True, m)
    Just((char, k')) ->
      val sub = m.lookup(char)
      match sub
        Nothing -> Trie(offset, p, pcount, v, full, m.set(char, Trie(offset + pcount + 1, k'.string, kcount' - 1, ksfull, True, LinearMap([]))))
        Just(sub) -> Trie(offset, p, pcount, v, full, m.set(char, bind(sub.pretend-decreasing, k', ksfull, kcount' - 1)))

fun internal/bind(t: trie, k: sslice, original: string, kcount: int): div trie
  match t
    Root(m) ->
      bind-map(m, False, "", "", k, original, 0, 0, kcount)
    Trie(offset, p, pcount, v, full, m) ->
      val pslice = p.slice
      // We go over the strings multiple times, we should inline common-prefix here, which also removes the need for non-reachable
      if k.is-prefixed-by(pslice, kcount, pcount) then 
        bind-map(m, full, p, v, k.drop(pcount), original, offset, pcount, kcount - pcount)
      elif pslice.is-prefixed-by(k, pcount, kcount) then
        bind-map(m, full, k.string, original, pslice.drop(kcount), v, offset, kcount, pcount - kcount)
      else
        val common = k.common-prefix(pslice, pslice.truncate)
        val commoncount = common.count
        val newoffset = offset + commoncount
        val k' = k.drop(commoncount)
        val p' = pslice.drop(commoncount)
        val commonv = v.slice.truncate.extend(newoffset)
        match (k'.next, p'.next)
          (Just((chark, k'')), Just((charp, p''))) ->
            val m' = LinearMap([
              (chark, Trie(newoffset, k''.string, k''.count, original, True, LinearMap([]))),
              (charp, Trie(newoffset, p''.string, p''.count, v, full, m)) 
            ])
            Trie(offset, common.string, commoncount, commonv.string, False, m')
          _ -> 
            trace("trie unreachable case 2 " ++ p.show ++ " " ++ k.show ++ " " ++ v.show)
            unsafe/not-reachable()

fun common-prefix(a: sslice, b: sslice, acc: sslice): sslice
  match (a.next, b.next)
    (Just((chara, a')), Just((charb, b'))) | chara == charb -> 
        common-prefix(a'.pretend-decreasing, b', acc.extend(1))
    _ -> acc

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
      