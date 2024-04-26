module std/cextern

import std/num/int32
import std/core/types

extern import
  c file "inline/cextern.h"

pub value struct owned-c<t>
  owned: forall<a> a
pub value struct borrowed-c<s::S,t>
  borrowed: forall<a> a
pub type c-array<t>
pub alias c-null<t> = intptr_t

pub inline extern cnull(): c-null<t>
  c inline "(kk_addr_t)NULL"

pub fun array/malloc<t>(n: int32, ?size-of: (c-null<t>) -> int32): owned-c<c-array<t>>
  int/malloc(n, size-of(cnull())).c-own

pub fun single/malloc<t>(?size-of: (c-null<t>) -> int32): owned-c<t>
  int/malloc(1.int32, size-of(cnull())).c-own

pub fun array/malloc-c<t>(n: int32, ?size-of: (c-null<t>) -> int32): owned-c<c-array<t>>
  int/malloc-c(n, size-of(cnull())).c-own-free-calloc

pub fun single/malloc-c<t>(?size-of: (c-null<t>) -> int32): owned-c<t>
  int/malloc-c(1.int32, size-of(cnull())).c-own-free-calloc

extern int/malloc<t>(n: int32, size-of: int32): intptr_t
  c inline "(kk_addr_t)kk_malloc(#1*#2, kk_context())"

extern int/malloc-c<t>(n: int32, size-of: int32): intptr_t
  c inline "(kk_addr_t)malloc(#1*#2)"

// Transform a c ptr into a managed koka value, which will be freed when koka's reference count reaches 0
extern c-own-extern(c: intptr_t): a
  c inline "kk_cptr_raw_box(&kk_free_fun, (void *)#1, kk_context())"

// Transform a c ptr into a managed koka value, which will be freed when koka's reference count reaches 0
extern c-own-free-calloc-extern(c: intptr_t): a
  c inline "kk_cptr_raw_box(&kk_free_calloc, (void *)#1, kk_context())"

pub fun c-own<t>(t: intptr_t): owned-c<t>
  Owned-c(t.c-own-extern)

pub fun c-own-free-calloc<t>(t: intptr_t): owned-c<t>
  Owned-c(t.c-own-free-calloc-extern)

// Transform a c ptr into a koka value that holds the c reference without freeing it
// The pointer should be valid
extern c-borrow-extern(c: intptr_t, f: b -> e a): e a
  c "kk_borrow_ptr"

extern unsafe-cast(b: b): a
  c inline "#1"

pub fun c-borrow<t>(c: intptr_t, f: forall<s> borrowed-c<s,t> -> e a): e a
  c-borrow-extern(c, fn(p) f(Borrowed-c(p.unsafe-cast())))

// Transform a koka owned c value into a c ptr (keeping the koka reference alive during the scope of the function)
extern owned/with-ptr-extern(^t: b, f: intptr_t -> e a): e a
  c inline "kk_owned_with_ptr(kk_std_cextern__owned_c_unbox(#1, KK_BORROWED, kk_context()).owned, #2, kk_context())"

pub fun owned/with-ptr(t: owned-c<t>, f: intptr_t -> e a): e a
  owned/with-ptr-extern(t, f)

// Transform a koka owned value into a c ptr (keeping the koka reference alive during the scope of the function)
extern borrowed/with-ptr-extern(^t: b, f: intptr_t -> e a): e a
  c inline "kk_borrowed_with_ptr(kk_std_cextern__borrowed_c_unbox(#1, KK_BORROWED, kk_context()).borrowed, #2, kk_context())"

pub fun borrowed/with-ptr(t: borrowed-c<s,t>, f: intptr_t -> e a): e a
  borrowed/with-ptr-extern(t, f)

pub fun c-array/with-ptr(^t: owned-c<c-array<t>>, idx: ssize_t, f: forall<s> borrowed-c<s,t> -> e a, ?size-of: (c-null<t>) -> int32): e a
  offset/with-ptr(t, idx, fn(p) c-borrow(p, f), size-of(cnull()))

extern offset/with-ptr(^t: b, idx: ssize_t, f: intptr_t -> e a, size-of: int32): e a
  c inline "kk_owned_with_ptr_idx(kk_std_cextern__owned_c_unbox(#1, KK_BORROWED, kk_context()).owned, #2, #3, #4, kk_context())"

pub extern ptr/to-string(c: intptr_t): string
  c inline "kk_string_alloc_raw((const char *)#1, false, kk_context())"

pub extern strlen-ptr/to-string(c: intptr_t, i: int64): string
  c inline "kk_string_alloc_raw_buff(#2, (const char *)#1, false, kk_context())"

pub extern ptr/c-string(s: string): intptr_t
  c inline "(intptr_t)kk_string_cbuf_borrow(#1, NULL, kk_context())"