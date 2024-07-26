import std/core/undiv

struct queue<q,a>
  q-empty: q<a>
  q-is-empty: (q<a>) -> bool
  q-snoc: (q<a>, a) -> q<a>
  q-head: (q<a>) -> emptyqueue a
  q-tail: (q<a>) -> emptyqueue q<a>;

effect emptyqueue
  final ctl err-empty(): a;

fun snoc(q: q<a>, x: a, ?this/queue: queue<q,a>): q<a>
  (this/queue.q-snoc)(q,x)

fun head(q: q<a>, ?this/queue:queue<q,a>): emptyqueue a
  (this/queue.q-head)(q)

fun tail(q: q<a>, ?this/queue:queue<q,a>): emptyqueue q<a>
  (this/queue.q-tail)(q)

fun queue/empty(?q:queue<q,a>): q<a>
  q.q-empty

fun queue/is-empty(q: q<a>, ?this/queue:queue<q,a>): bool
  (this/queue.q-is-empty)(q)

fun queue/list(q:q<a>, ?this/queue:queue<q,a>): list<a>
  with final ctl err-empty() Nil
  Cons(q.head, queue/list(q.tail.pretend-decreasing))
