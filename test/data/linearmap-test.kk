import std/data/linearmap
import std/test


fun suite()
  group("add")
    test("add already present")
      expect(LinearMap([(1, "a"), (2, "b")]))
        LinearMap([(1, "a"), (2, "b")]).add(1, "x") 
    test("add not present")
      expect(LinearMap([(2, "b"), (1, "x")]))
        LinearMap([(2, "b")]).add(1, "x")
  group("set")
    test("set already present")
      expect(LinearMap([(1, "x"), (2, "b")]))
        LinearMap([(1, "a"), (2, "b")]).set(1, "x") 
    test("set not present")
      expect(LinearMap([(2, "b"), (1, "x")]))
        LinearMap([(2, "b")]).set(1, "x")