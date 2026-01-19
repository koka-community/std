/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/
module test/data/string-map-test

import std/data/string-map
import std/test

fun test-string-map()
  test("Basic Lookup")
    val t = string-map/empty().set("hello", 1)
    expect(Just(1), { t.lookup("hello") })
    expect(Nothing, { t.lookup("hell") })
    expect(Nothing, { t.lookup("hello world") })
    expect(Nothing, { t.lookup("h") })

  test("Update Value")
    val t = string-map/empty().set("hello", 1).set("hello", 2)
    expect(Just(2), { t.lookup("hello") })

  test("Prefixes")
    val t = string-map/empty().set("hello", 1).set("hell", 2)
    expect(Just(1), { t.lookup("hello") })
    expect(Just(2), { t.lookup("hell") })
    expect(Nothing, { t.lookup("hel") })

  test("Branching")
    val t = string-map/empty().set("hello", 1).set("help", 2)
    expect(Just(1), { t.lookup("hello") })
    expect(Just(2), { t.lookup("help") })
    expect(Nothing, { t.lookup("hel") })
    expect(Nothing, { t.lookup("hell") })

  test("Unicode")
    val t = string-map/empty().set("héllo", 1).set("hélp", 2)
    expect(Just(1), { t.lookup("héllo") })
    expect(Just(2), { t.lookup("hélp") })
    expect(Nothing, { t.lookup("hé") })

  test("Empty String")
    val t = string-map/empty().set("", 1)
    expect(Just(1), { t.lookup("") })
    expect(Nothing, { t.lookup("a") })
    
    val t2 = t.set("a", 2)
    expect(Just(1), { t2.lookup("") })
    expect(Just(2), { t2.lookup("a") })

  test("Complex Insertions")
    val words = ["apple", "app", "apply", "banana", "band", "bandana"]
    var t := string-map/empty()
    words.foreach fn(w)
      t := t.set(w, w.count)
    
    words.foreach fn(w)
      expect(Just(w.count), { t.lookup(w) })
    
    expect(Nothing, { t.lookup("ap") })
    expect(Nothing, { t.lookup("ban") })
    expect(Nothing, { t.lookup("banda") })
  test("Update Function")
    val t = string-map/empty().set("hello", 1).set("hello", 2)
    expect(Just(2), { t.lookup("hello") })
    
    val t2 = t.update("hello", fn(old) old.map(fn(x) x + 10).default(0))
    expect(Just(12), { t2.lookup("hello") })
    
    val t3 = t.update("world", fn(old) old.map(fn(x) x + 10).default(0))
    expect(Just(0), { t3.lookup("world") })

  test("Update with Multiple Keys")
    var t := string-map/empty()
    t := t.set("apple", 1)
    t := t.set("banana", 2)
    
    t := t.update("apple", fn(old) old.map(fn(x) x * 2).default(0))
    expect(Just(2), { t.lookup("apple") })
    expect(Just(2), { t.lookup("banana") })
    
    t := t.update("cherry", fn(old) old.map(fn(x) x * 3).default(5))
    expect(Just(2), { t.lookup("apple") })
    expect(Just(2), { t.lookup("banana") })
    expect(Just(5), { t.lookup("cherry") })
pub fun suite()
  test-string-map()

pub fun main()
  run-tests(suite)