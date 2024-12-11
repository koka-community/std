import std/data/hashmap
import std/data/hash

fun main()
  val h = random/hash-map()
  val h1 = h.insert("xyz", "abc")
  h1.get("xyz").unjust