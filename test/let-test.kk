import std/test
import std/let
import std/num/random

struct person
  name: string
  age: int

fun person/show(person: person)
  "Person " ++ person.name ++ " is " ++ person.age.show

fun person/(==)(a: person, b: person)
  (
    a.name == b.name &&
    a.age == b.age
  )

fun suite(): <test<<io,let>>,let,io> ()
  test("vars with default")
    val name = let { "adam" }
    val age = let { 1 }
    val person = let { Person(name.get, age.get) }
    expect(Person("adam", 1)) { person.get }

    with age.set { 2 }
    expect(Person("adam", 2)) { person.get }

    with name.set { "ben" }
    with age.set { 3 }
    expect(Person("ben", 3)) { person.get }

  test("undefined vars")
    val tag = let-undefined()
    val err = try { tag.get }
    expect(True) { err.is-error }

    with tag.set { "foo" }
    expect("foo") { tag.get }
  
  test("type of letvar")
    // TODO: it's currently not possible to write the correct type, which should be:
    // val v: letvar<<let>, int> = let { 1 }
    val v = let { 1 }
    expect(1) { v.get }
  
  group("nested scopes")
    val scope = let { "default" }
    test("test inherits from outer scope")
      expect("default") { scope.get }

    group("inner scope")
      with scope.set { "group" }
      test("test inherits from inner scope")
        expect("group") { scope.get }

      test("group scope can be overridden within test")
        with scope.set { "test" }
        expect("test") { scope.get }

  group("documentation example")
    // NOTE: keep in sync with example in let.kk
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

fun main() run-tests(suite)

// utilities to make documentation example work
struct book
  isbn: string
  author: string
  title: string

struct shelf(books: list<book>)

fun stack-shelves(books)
  val shelf = books.list/take(5)
  if books.length > 5 then
    Cons(shelf, stack-shelves(books.drop(5)))
  else
    [shelf]
