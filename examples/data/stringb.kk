import std/data/stringb
import std/num/float64

fun sb(l: list<int>)
  match l
    Nil -> build()
    Cons(x, Nil) ->
      x.build()
    Cons(x, xs) ->
      x |-| sb(xs)

fun tupled(l: list<a>, ?show: a -> string)
  "(" |.| tuprec(l) |.| ")".build()

fun tuprec(l : list<a>, ?show: a -> string)
  match l
    Nil -> build()
    Cons(x, Nil) ->
      x.build()
    Cons(x, xs) ->
      x |.| "," |-| tuprec(xs)

fun main()
  [1, 2, 3].sb.println
  "".println

  val b = "Hello" |-| "world!" |.|
            indented([1, 2, 3].sb \ [1, 2, 3].build()) |.|
            2 \ (4.5).build()
  b.println
  "".println

  val b1 = "Hello" |-| "world!" 
              \- [1, 2, 3].sb 
                \- [1, 2, 3].tupled
                  \- 2 
                  \ (4.5).build()
  b1.println