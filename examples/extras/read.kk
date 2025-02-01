import std/core-extras

fun show(i: int8)
  i.int.show-hex(width=2)

fun main()
  read-byte-file("README.md").list.map(show).join("\n").println