import queues
import lazy-list

// Bankers Queue (-- not really we would need to have some lazy lists)
value struct banker-queue<a>
  lenf: int
  f: lazy-list<a,<>>
  lenr: int
  r: lazy-list<a,<>>

inline fun check(lenf: int, f: lazy-list<a,<>>, lenr: int, r: lazy-list<a,<>>): banker-queue<a>
  if lenr <= lenf
  then Banker-queue(lenf, f, lenr, r)
  else Banker-queue(lenf + lenr, f ++ r.reverse, 0, LNil)

val bankers/queue = Queue(
  empty,
  is-empty,
  snoc,
  head,
  tail
)

val bankers/empty = Banker-queue(0, LNil, 0, LNil)

fun is-empty(Banker-queue(lenf,_,_,_)) 
  lenf == 0

fun snoc(Banker-queue(lenf,f,lenr,r), x) 
  check(lenf, f, lenr + 1, LCons(x,delay{r}))

fun head(bq)
  match bq
    Banker-queue(_, LNil, _, _) -> err-empty()
    Banker-queue(_, LCons(x,_), _, _) -> x

fun tail(bq)
  match bq
    Banker-queue(_, LNil, _, _) -> err-empty()
    Banker-queue(lenf, LCons(_,f), lenr, r) -> 
      check(lenf - 1, mask<emptyqueue>{f.force}, lenr, r)

fun test()
  val q = queue/empty(queue)
  with final ctl err-empty() ()
  q.snoc(1).snoc(2).snoc(3).tail.list.println