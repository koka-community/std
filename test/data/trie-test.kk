import std/data/trie
import std/test

fun suite()
  val t = trie/empty().add("Hello")
  val t1 = t.add("World").add("Worship")
  group("trie")
    test("lookup")
      expect(Just("Hello"))
        t1.lookup("Hello")
      expect(Just("Worship"))
        t1.lookup("Worship")
      expect(Nothing)
        t1.lookup("Wor")
      expect(Nothing)
        t1.lookup("Unknown")
    
    test("prefixes")
      val t2 = trie/empty().add("a").add("ab").add("abc")
      expect(Just("a")) { t2.lookup("a") }
      expect(Just("ab")) { t2.lookup("ab") }
      expect(Just("abc")) { t2.lookup("abc") }
      expect(Nothing) { t2.lookup("ac") }
    
    test("branching")
      val t3 = trie/empty().add("test").add("team").add("toast")
      expect(Just("test")) { t3.lookup("test") }
      expect(Just("team")) { t3.lookup("team") }
      expect(Just("toast")) { t3.lookup("toast") }
      expect(Nothing) { t3.lookup("tea") }
      expect(Nothing) { t3.lookup("toas") }

    test("unicode")
      val t4 = trie/empty().add("αβγ").add("αβδ")
      expect(Just("αβγ")) { t4.lookup("αβγ") }
      expect(Just("αβδ")) { t4.lookup("αβδ") }
      expect(Nothing) { t4.lookup("αβ") }

    test("empty string")
      val t5 = trie/empty().add("")
      expect(Just("")) { t5.lookup("") }
      expect(Nothing) { t5.lookup("a") }

fun main()
  run-tests(suite)