effect efind<b>
  final ctl not-found(): a
  final ctl found(b: b): b

effect err-empty
  final ctl err-empty(): a

type find<v>
  Found(v: v)
  NotFound