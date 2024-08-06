value struct stack<a>
  l: list<a>

fun push(s: stack<a>, a: a): stack<a>
  match s
    Stack(l) -> Stack(Cons(a, l))

fun pop(s: stack<a>): exn (a, stack<a>)
  match s
    Stack(Cons(a, l)) -> (a, Stack(l))
    Stack(Nil) -> throw("Empty Stack")

fun head(s: stack<a>): exn a
  match s
    Stack(Cons(a, _)) -> a
    Stack(Nil) -> throw("Empty Stack")

fun tail(s: stack<a>): exn stack<a>
  match s
    Stack(Cons(_, l)) -> Stack(l)
    Stack(Nil) -> throw("Empty Stack")

fun empty(): stack<a>
  Stack(Nil)

fun is-empty(s: stack<a>): bool
  match s
    Stack(Nil) -> True
    Stack(_) -> False

