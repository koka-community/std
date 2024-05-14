module tree-common

// --------------------------------------------------------
// Render nice trees

pub value struct render
  root  : int
  lines : list<string>

pub fun height(r : render ) -> r.lines.length
pub fun width(r : render )  -> max(1,r.lines.map(count).maximum)

pub fun pad-render( r : render, n : int ) : render
  Render(r.root, r.lines ++ replicate("",n - r.height))

pub fun pad-height( l : render, r : render ) : (render,render)
  val h = max(l.height,r.height)
  (pad-render(l,h),pad-render(r,h))

pub fun fill( n : int, c : char )
  pad-right("",n,c)

pub fun spaces(n : int)
  fill(n,' ')

pub fun half(i : int)
  if i.is-odd then i/2 + 1 else i/2

pub fun beside(l : render, head : string, r : render, ?show: (k) -> string ) : render
  val (l1,r1) = pad-height(l,r)
  val wl  = l1.width
  val wr  = r1.width
  val lheader = spaces(l.root - 1) ++ "+" ++ fill(wl - l.root - 1,'-')
  val rheader = fill(r.root - 1,'-') ++ "+"
  val header  = lheader ++ head ++ rheader
  val sep = spaces(head.count)
  val under = zipwith(l1.lines,r1.lines,fn(ls,rs) ls.pad-right(wl) ++ sep ++ rs)
  val newroot = lheader.count + head.count - 1
  Render(newroot, Cons(header, under))
