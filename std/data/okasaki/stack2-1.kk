import errors

value struct stack<a>
  l: list<a>

fun push(s: stack<a>, a: a): stack<a>
  match s
    Stack(l) -> Stack(Cons(a, l))

fun pop(s: stack<a>): err-empty (a, stack<a>)
  match s
    Stack(Cons(a, l)) -> (a, Stack(l))
    Stack(Nil) -> err-empty()

fun head(s: stack<a>): err-empty a
  match s
    Stack(Cons(a, _)) -> a
    Stack(Nil) -> err-empty()

fun tail(s: stack<a>): err-empty stack<a>
  match s
    Stack(Cons(_, l)) -> Stack(l)
    Stack(Nil) -> err-empty()

fun empty(): stack<a>
  Stack(Nil)

fun is-empty(s: stack<a>): bool
  match s
    Stack(Nil) -> True
    Stack(_) -> False

