import queues

// Batched Queue
value struct batched-queue<a>
  front: list<a>
  back: list<a>

inline fun check(f: list<a>, r: list<a>): batched-queue<a>
  match f
    Nil -> Batched-queue(r.reverse, [])
    _ -> Batched-queue(f, r)

val batched/queue = Queue(
  Batched-queue([], []),
  is-empty, // O(1)
  snoc, // O(1) amortized with tail
  head, // O(1)
  tail // O(1) amortized with snoc
)

val batched/empty = Batched-queue([], [])

fun is-empty(Batched-queue(f,_)) 
  f.list/is-empty

fun snoc(Batched-queue(f,r), x) 
  check(f, Cons(x,r))

fun head(bq) 
  match bq
    Batched-queue([], _) -> err-empty()
    Batched-queue(Cons(x,_), _) -> x

fun tail(bq) 
  match bq
    Batched-queue([], _) -> err-empty()
    Batched-queue(Cons(_,f), r) -> check(f,r)
