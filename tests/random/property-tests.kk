import std/test
import std/data/random
import std/num/random

fun main()
  with run-tests()
  prop-test("sample")
    val n = random-int()
    expect((n % 3) >= 0, details = n.show ++ " % 3 = " ++ (n%3).show) { True }
    
  group("int/between")
    test("returns the lowest number in the range")
      with arbitrary
      retry-until { between(1, 5) == 1 }

    test("returns the highest number in the range")
      with arbitrary
      retry-until { between(1, 5) == 5 }
    
    prop-test("never returns a number outside the range")
      val n = between(1, 5)
      expect(n < 1) { False }
      expect(n > 5) { False }
      
  group("chars")
    prop-test("generates a char with the given character set")
      expect(alpha-num().is-alpha-num) { True }
      expect(alpha().is-alpha) { True }
      expect(digit().is-digit) { True }

  group("strings")
    prop-test("generates a string from the given charset")
      val chars = alpha-num(10, 5).vector
      expect(chars.length > 10) { False }
      expect(chars.length < 5) { False }
      expect(chars.list.all(is-alpha-num)) { True }
