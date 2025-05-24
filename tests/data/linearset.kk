import std/data/linearset
import std/test

pub fun test()
  with run-tests
  group("linearset")
    test("Basics")
      val s = linear-set([1, 2, 3])
      val s2 = linear-set([2, 3, 4])
      val s3 = s + s2
      s3.set/show.println