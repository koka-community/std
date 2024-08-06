import std/test
pub fbip fun list/update(l: list<a>, i: int, x: a): list<a>
  match l
    Nil -> Nil
    Cons(h, t) -> if i == 0 then Cons(x, t) else Cons(h, t.update(i - 1, x))

pub fun list/suffixes(l: list<a>): list<list<a>>
  fun loop(l': list<a>, acc: ctx<list<list<a>>>): list<list<a>>
    match l'
      Nil -> acc ++. Cons(Nil, Nil)
      Cons(_, t) -> loop(t, acc ++ ctx Cons(l', _))
  loop(l, ctx _)

fun test-suffixes()
  basic/test("suffixes")
    expect([[1,2,3,4], [2,3,4], [3,4], [4], []])
      suffixes([1,2,3,4])