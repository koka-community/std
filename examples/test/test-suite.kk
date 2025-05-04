import std/test

fun main()
  with run-tests()
  group("Basics")
    test("Successful")
      ()
    with group("A subgroup")
    test("Returns continue tests")
      val res = expect-result(1)
                  2
      hint("Continued!")
      expect(2)
        1 + res
      expect(2)
        1
  group("Other")
    test("Wrong expect")
      expect(1)
        2
    test("Additional info")
      expect(1, details="Really expected 1!")
        throw("Some error somewhere")
