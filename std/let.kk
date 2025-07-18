/*----------------------------------------------------------------------------
   Copyright 2026, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

/*
This module is inspired by rspec's `let` utility. It allows you to define
lazy variables which can be overridden in a sub scope.

When the value is computed, all dependent variables take their bindings
from the current scope, rather than the scope where that value was defined.
That's fairly abstract, a common practical use case is in tests.

It's common for test cases to have a set of data which is shared between
many test cases, but allowing for individual test cases to override
individual parts.

If this data is just a few variables, you can get by with a little repetition:

```
val isbn = "978-1-56619-909-4"
val title = "The Best Book"
val author = "Eric Carle"

group("a long title")
  val title = "I can't believe this title is so long did nobody think of that?"
  test("it should fit in a single shelf")
    expect(1)
      stack-shelves([Book(isbn, author, title)]).length
```

With `let` you can setup reusable and related data in a way that
allows individual groups or tests to override precisely the details
they depend on.

This reduces repetition, leading to more terse and readable
test bodies. Here's an example:

```
val isbn = let { "978-1-56619-909-4" }
val title = let { "The Best Book" }
val author = let { "Eric Carle" }
val book = let { Book(isbn.get, author.get, title.get) }
val books = let { [book.get] }
fun shelves() stack-shelves(books.get)

group("a long title")
  with title.set { "I can't believe this title is so long did nobody think of that?" }

  test("it should fit on a single shelf")
    expect(1) { shelves().length }

group("ten books")
  with books.set
    val b = book.get
    [b, b, b, b, b, b, b, b, b, b]
      
  test("requires two shelves")
    expect(2) { shelves().length }
```

Note: Unlike in rspec, these variables are not currently memoized -
they are reevaluated on each call to `get`.
*/

module std/let

pub effect let
  fun unsafe-binding(name: letvar<e,a>): (() -> e a)
  fun unsafe-bindings(): list<(int, any)>

abstract struct letvar<e,a>
  uid: int
  default: () -> e a

pub fun empty-scope(f: () -> <let|e> a): e a
  handle<let>(f)
    fun unsafe-binding(name) (name.default)
    fun unsafe-bindings() []

pub fun @default-let(f: () -> <let|e> a): e a
  empty-scope(f)

pub fun let(default: () -> <let|e> a): ndet letvar<<let|e>,a>
  Letvar(unique(), default)

pub fun get(query: letvar<<let|e>,a>): <let|e> a
  unsafe-binding(query)()

pub fun let-undefined(?kk-module: string, ?kk-line: string): ndet letvar<<let,exn|e>,a>
  let { throw("`let` used without being defined (" ++ ?kk-module ++ ":" ++ ?kk-line ++")") }

// Override a binding - the new definition must have the same effect type.
// The effect type of the block can be unrelated to the binding's effect
// (but it will be a superset if you access the binding within the block)
pub fun set(name: letvar<<let|e>,a>, binding: () -> <let|e> a, f: () -> <let|e2> b): <let|e2> b
  with override<let>
    fun unsafe-binding(query)
      if query.uid == name.uid then unsafe-cast(binding) else unsafe-binding(query)
    fun unsafe-bindings()
      Cons((name.uid, unsafe-cast(binding)), unsafe-bindings())
  f()

extern unsafe-cast(x: a): b
  inline "#1"

// used by test suite to allow bindings defined in an outer group to
// take effect within test body
pub fun capture-bindings(): let ((() -> <let|e> a) -> <let|e> a)
  val bindings = unsafe-bindings()
  fun restore(f: () -> <let|e> a): <let|e> a
    with override<let>
      fun unsafe-bindings() bindings
      fun unsafe-binding(query)
        val binding = bindings.find(fn(b) b.fst == query.uid)
        match binding
          Just(b) -> unsafe-cast(b.snd)
          Nothing -> unsafe-binding(query)
    f()
  restore

