import std/pretty/pprint
import std/pretty/printer
import std/test

pub fun test-pretty()
  with run-tests
  group("Pretty Printing")
    test("Basic Combinators")
      expect("test hello") fn()
        ("test".text |+| "hello".text).show
      expect(r#"test
hello"#) fn()
        ["test".text, "hello".text].vcat.show
      expect("testhello") fn()
        ["test".text, "hello".text].hcat.show
      expect("\x1B[91m0\x1B[39m")
        with ansi-string-printer
        color("0".text, Red).write-pretty
