import std/data/linear-set
import std/test


fun suite()
  group("linear-set")
    test("Basics")
      val s = linear-set([1, 2, 3])
      val s2 = linear-set([2, 3, 4])
      val s3 = s + s2
      s3.set/show.println