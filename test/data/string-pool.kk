import std/data/word-set

pub val reserved-names = 
      delay({
        string-pool().add-all(
        ["infix"])
    })

fun is-reserved(name: string)
  reserved-names.force.is-interned(name)

fun main()
  println("Here")
  ":=".is-reserved.println
  println("Done")