module std/data/random
import std/num/random

// Utilities for generating random data

pub fun retry-until(gen: () -> <random,exn,div|e> bool, max-tries: int = 1000): <random,exn,div|e> ()
  if max-tries <= 0 then
    throw("retry-until: Max tries exceeded")
  if gen() then
    ()
  else retry-until(gen, max-tries - 1)

pub fun int/between(start: int, end-inclusive: int): <random,exn> int
  val range = end-inclusive + 1 - start
  if (range <= 0) then
    throw("Invalid range (" ++ start.show ++ ", " ++ end-inclusive.show ++")")
  (random-int() % range) + start

pub fun char/between(start: char, end-inclusive: char): <random,exn> char
  char(between(start.int, end-inclusive.int))

pub fun list-of(n: int, action: () -> <random|e> a): <random|e> list<a>
  range/fold(1, n, []) fn(_, result)
    Cons(action(), result)

pub fun string-of(chars: () -> <random,exn|e> char, max-length: int, min-length: int = 0): <random,exn|e> string
  val length = between(min-length, max-length)
  list-of(length, chars).string

pub fun pair/choose(a: () -> <random|e> a, b: () -> <random|e> a): <random|e> a
  if random-bool() then a() else b()

pub fun list/choose(a: list<() -> <random,exn|e> a>): <random,exn|e> a
  match a[between(0, a.length - 1)]
    Just(f) -> f()
    Nothing -> throw("Impossible: out of range")

pub fun const/choose(a: list<a>): <random,exn|e> a
  match a[between(0, a.length - 1)]
    Just(x) -> x
    Nothing -> throw("Impossible: out of range")

pub fun char/alpha-upper(): <random,exn> char { between('A', 'Z') }

pub fun char/alpha-lower(): <random,exn> char { between('a', 'z') }

pub fun char/alpha(): <random,exn> char { choose(alpha-upper, alpha-lower) }

pub fun char/digit(): <random,exn> char { between('0', '9') }

pub fun char/alpha-num(): <random,exn> char { choose(alpha, digit) }

pub fun char/printable-ascii(): <random,exn> char { between(' ', '~') }

pub fun string/printable-ascii(max-length: int, min-length: int = 0): <random,exn> string
  string-of(printable-ascii, max-length, min-length)

pub fun string/alpha-num(max-length: int, min-length: int = 0): <random,exn> string
  string-of(alpha-num, max-length, min-length)

