/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/

module std/core-extras
import std/core/undiv

extern import 
  c file "inline/core-extras"

// List Utilities
pub fun eql/(==)(l1: list<a>, l2: list<a>, ?(==): (a, a) -> e bool): e bool
  match (l1, l2)
    (Nil, Nil) -> True
    (Cons(s1, l1'), Cons(s2, l2')) -> s1 == s2 && eql/(==)(l1'.pretend-decreasing, l2')
    _ -> False

pub fun list/and(l: list<bool>): bool
  match l
    Nil -> True
    Cons(True, l') -> l'.and
    Cons(False) -> False

pub fun list/is-prefix-of(l1: list<a>, l2: list<a>, ?(==): (a, a) -> e bool): e bool
  match (l1, l2)
    (Nil, _) -> True
    (_, Nil) -> False
    (Cons(h1, t1), Cons(h2, t2)) -> h1 == h2 && t1.pretend-decreasing.is-prefix-of(t2)

pub fun list/maximum-by(l0: list<a>, cmp0: (a, a) -> e order): e maybe<a>
  fun loop(l: list<a>, acc: maybe<a>, cmp: (a, a) -> e order): e maybe<a>
    match l
      Nil -> acc
      Cons(h, t) ->
        match acc
          Nothing -> loop(t, Just(h), cmp)
          Just(max) ->
            match cmp(h, max)
              Gt -> loop(t, Just(h), cmp)
              _ -> loop(t, acc, cmp)
  loop(l0, Nothing, cmp0)

// String and char utilities
pub fun string/is-prefix-of(s1: string, s2: string): bool
  s2.starts-with(s1).bool

pub fun to-upper(c: char): char
  c.string.to-upper.head-char.default(c)
  
pub fun to-lower(c: char): char
  c.string.to-lower.head-char.default(c)

pub fun split-by(s: string, pred: (char) -> bool): list<string>
  fun loop(sl: sslice, numchars: int, acc: ctx<list<string>>): list<string>
    match sl.next
      Nothing -> acc ++. Nil
      Just((c, sl')) -> 
        if pred(c)
          then loop(sl'.pretend-decreasing, 0, acc ++ ctx Cons(sl'.advance(0 - numchars).truncate.extend(numchars).string, _))
          else loop(sl'.pretend-decreasing, numchars + 1, acc)
  loop(s.slice, 0, ctx _)

pub effect find<a>
  final ctl found(a: a): b

pub fun find(f: () -> <find<a>|e> a): e a
  with final ctl found(a) a
  f()

// Maybe utilities
pub inline fun flatten( item : maybe<maybe<a>> ) : maybe<a>
  match item
    Just(x) -> x
    Nothing -> Nothing

pub fun maybe/(==)(m1: maybe<a>, m2: maybe<a>, ?(==): (a, a) -> e bool): e bool
  match (m1, m2)
    (Just(m1'), Just(m2')) -> m1' == m2'
    (Nothing, Nothing) -> True
    _ -> False

pub fun expect-unjust( m : maybe<a>, msg: string ) : exn a
  match m
    Just(a) -> a
    Nothing -> throw("expect-unjust: " ++ msg)

// Vector utilities
pub fun vector-init-list( ^n: int, xs: list<(int, a)>): vector<a>
  val v = unsafe-vector(n.ssize_t) 
  fun assigns(xs': some<a> list<(int,a)>) : total ()
    match xs'
      Cons((i,x), xss) -> 
        unsafe-assign(v, i.ssize_t, x)
        assigns(xss)
      Nil -> ()
  assigns(xs)
  v

// Copies a vector
pub inline extern copy( v : vector<a> ) : vector<a>
  c "kk_vector_copy"
  js inline "[...(#1)]"

pub inline extern realloc( v : vector<a>, new_capacity : ssize_t ) : vector<a>
  c inline "kk_vector_realloc(#1, #2, kk_box_null(), kk_context())"
  js inline "[...(#1)]"

// This function takes a vector `v` and a position to stop at `stop`
// If you supply a `stop` larger than the length, then the length of the vector is used instead.
// This function shouldn't be called directly unless you know exactly what you are doing.
pub extern unsafe-vector-clear( v : vector<a>, stop : ssize_t ) : ()
  c "kk_vector_clear"

// This function takes a vector `v` and a `position` to clear at.
// This is all done without a bounds check, so make sure to get it right.
// This function shouldn't be called directly unless you know exactly what you are doing.
pub extern unsafe-vector-clear-at( v : vector<a>, position : ssize_t ) : ()
  c "kk_vector_clear_at"

// Apply a total function `f` to each element in a vector `v`
// Since the vector consists of boxed values we can ignore type incompatibilities
// However, we also cannot allow exception effects in f, because then the vector would be left in an inconsistent state which would be observable and unreversable
// We could allow div, but then this is always div even when f is not div
pub fun unique/map( v : vector<a>, f : a -> b ) : vector<b>
  if v.is-vec-unique then
    // trace("unique/map: vector is unique")
    v.foreach-indexedz(fn(i,x) v.unsafe-assign(i, f(x).unsafe-ignore-type)) 
    v.unsafe-ignore-type
  else
    // trace("unique/map: vector is not unique")
    val w = unsafe-vector(v.length.ssize_t)
    v.foreach-indexedz fn(i,x)
      unsafe-assign(w,i,f(x))
    w

// Set the element at position `index` in vector `v` without bounds check!
pub fun unsafe-set( v : vector<a>, ^index : int, value : a ) : vector<a>
  if v.is-vec-unique then
    // trace("unsafe-set: vector is unique")
    v.unsafe-assign(index.ssize_t, value)
    v
  else 
    // trace("unsafe-set: vector is not unique")
    val v' = v.copy
    v'.unsafe-assign(index.ssize_t, value)
    v'

pub fun a/unsafe-swap( v : vector<a>, ^idx1 : int, ^idx2 : int ) : vector<a>
  if v.is-vec-unique then
    val item1 = v.unsafe-idx( idx1.ssize_t )
    v.unsafe-assign( idx1.ssize_t, v.unsafe-idx( idx2.ssize_t ))
    v.unsafe-assign( idx2.ssize_t, item1 )
    v
  else 
    val v' = v.copy
    val item1 = v'.unsafe-idx( idx1.ssize_t )
    v'.unsafe-assign( idx1.ssize_t, v'.unsafe-idx( idx2.ssize_t ))
    v'.unsafe-assign( idx2.ssize_t, item1 )
    v'

// This variant mutates inplace
pub fun unit/unsafe-swap( v : vector<a>, ^idx1 : int, ^idx2 : int ) : ()
  val item1 = v.unsafe-idx( idx1.ssize_t )
  v.unsafe-assign( idx1.ssize_t, v.unsafe-idx( idx2.ssize_t ))
  v.unsafe-assign( idx2.ssize_t, item1 )

pub inline extern is-ref-unique(^x: a): bool
  c inline "!kk_box_is_ptr(#1, kk_context()) || kk_block_is_unique(kk_box_to_ptr(#1, kk_context()))"

pub inline extern is-vec-unique(^v: vector<a>): bool
  c inline "kk_datatype_is_unique(#1, kk_context())"

pub inline extern unsafe-box-drop(^x: a): total ()
  c inline "kk_box_drop(#1, kk_context())"

pub inline extern drop-at( ^v : vector<a>, index : ssize_t ) : ()
  c inline "kk_vector_dup(#1, kk_context()); kk_box_drop(kk_vector_at_borrow(#1, #2, kk_context()), kk_context()); kk_vector_unsafe_assign(#1, #2, kk_box_null(), kk_context())"

// Valid only for boxed values
pub inline extern unsafe-ignore-type(x: a): b
  inline "#1"

// Make the following preexisting functions public, or make them public in an unsafe module
pub inline extern unsafe-vector : forall<a> ( n : ssize_t ) -> total vector<a>
  c  inline "kk_vector_alloc(#1,kk_box_null(),kk_context())"
  cs inline "(new ##1[#1])"
  js inline "Array(#1)"

// This function should never be called directly unless you know exactly what you are doing
pub inline extern unsafe-assign : forall<a> ( v : vector<a>, i : ssize_t, x : a ) -> total ()
  c "kk_vector_unsafe_assign"
  cs inline "(#1)[#2] = #3"
  js inline "(#1)[#2] = #3"

// Return the element at position `index` in vector `v` without bounds check!
// This function should never be called directly unless you know exactly what you are doing
pub inline extern unsafe-idx( ^v : vector<a>, index : ssize_t ) : total a
  c  "kk_vector_at_borrow"
  cs inline "(#1)[#2]"
  js inline "(#1)[#2]"

// Length of a vector.
pub inline extern lengthz( ^v : vector<a> ) : ssize_t
  c  "kk_vector_len_borrow"
  cs inline "((#1).Length)"
  js inline "((#1).length)"

pub fun foreach-indexedz( v : vector<a>, f : (ssize_t,a) -> e () ) : e ()
  forz( v.lengthz ) fn(i)
    f(i,v.unsafe-idx(i))

// Executes `action` `n` times for each integer between [`0`,`n`)  (excluding `n` ).
// If `n <= 0`  the function returns without any call to `action` .
pub fun forz( n : ssize_t, action : (ssize_t) -> e () ) : e ()
  fun rep( i : ssize_t )
    if i < n then
      action(i)
      rep(pretend-decreasing(i.incr))
  rep(0.ssize_t)

pub fip extern ssize_t/incr(i : ssize_t ) : ssize_t
  inline "(#1 + 1)"

pub inline fip extern ssize_t/(<) : (ssize_t,ssize_t) -> bool
  inline "(#1 < #2)"
