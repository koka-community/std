module std/cextern

import std/num/int32
import std/core/types

extern import
  c file "inline/cextern.h"

// A managed koka pointer to C memory
// Owned values can be freely passed around, captured in lambdas, escape their scope, etc.
pub value struct owned-c<t>
  owned: forall<a> a

// A borrowed koka pointer to C memory during a scope s
// Borrowed values are only guaranteed valid during their scope, should not escape the scope
// For example an `owned-c<array<t>>` should only allow borrowed references to the middle of an array during a scope where the owned pointer will not be dropped
pub value struct borrowed-c<s::S,t>
  borrowed: forall<a> a

// A raw pointer to C memory
pub value struct c-pointer<t>
  ptr: intptr_t

// An opaque type to designate c-array types in Koka
pub type c-array<t>

// A type alias for a null pointer of type `t`
pub alias c-null<t> = c-pointer<t>

// The null pointer in C
pub inline fun cnull(): c-null<t>
  C-pointer(0.intptr_t)

// Allocate `n*size-of` bytes of memory using kk_malloc and return a pointer to the allocated memory
extern int/malloc<t>(n: int32, size-of: int32): intptr_t
  c inline "(kk_addr_t)kk_malloc(#1*#2, kk_context())"

// Allocate `n*size-of` bytes of memory using C's malloc and return a pointer to the allocated memory
extern int/malloc-c<t>(n: int32, size-of: int32): intptr_t
  c inline "(kk_addr_t)malloc(#1*#2)"

// Allocate a single element of type `t` using `kk_malloc` and return a managed pointer
// Type `t` should:
// - Be an opaque type in Koka corresponding to a C type (e.g. `pub type cstruct` with no members)
// - Have a `size-of` function that returns the size of the structure in bytes
pub fun single/malloc<t>(?size-of: (c-null<t>) -> int32): owned-c<t>
  Owned-c(int/malloc(1.int32, size-of(cnull())).c-own-extern)

// Allocate `n` elements of type `t` using `kk_malloc` and return a managed pointer to the array
// Type `t` should:
// - Be an opaque type in Koka corresponding to a C type (e.g. `pub type cstruct` with no members)
// - Have a `size-of` function that returns the size of the structure in bytes
pub fun array/malloc<t>(n: int32, ?size-of: (c-null<t>) -> int32): owned-c<c-array<t>>
  Owned-c(int/malloc(n, size-of(cnull())).c-own-extern)

// Allocate a single element of type `t` using C's `malloc` and return a managed pointer
// Type `t` should:
// - Be an opaque type in Koka corresponding to a C type (e.g. `pub type cstruct` with no members)
// - Have a `size-of` function that returns the size of the structure in bytes
pub fun single/malloc-c<t>(?size-of: (c-null<t>) -> int32): owned-c<t>
  Owned-c(int/malloc-c(1.int32, size-of(cnull())).c-own-free-calloc-extern)

// Allocate `n` elements of type `t` using C's `malloc` and return a managed pointer to the array
// Type `t` should:
// - Be an opaque type in Koka corresponding to a C type (e.g. `pub type cstruct` with no members)
// - Have a `size-of` function that returns the size of the structure in bytes
pub fun array/malloc-c<t>(n: int32, ?size-of: (c-null<t>) -> int32): owned-c<c-array<t>>
  Owned-c(int/malloc-c(n, size-of(cnull())).c-own-free-calloc-extern)

// !!!WARNING!!! UNSAFE API
// Allocate `n` elements of type `t` using `kk_malloc` and return a managed pointer to the array
// Type `t` should:
// - Be an opaque type in Koka corresponding to a C type (e.g. `pub type cstruct` with no members)
// - Have a `size-of` function that returns the size of the structure in bytes
//
// NOTES:
// Prefer using `array/malloc` or `single/malloc` instead of this function which return a managed pointer.
// Raw `c-pointer<t>` should be used in low-level generated koka ffi functions since the pointer is unknown to be managed or not.
// Conversion routines for `owned-c<t>` and `borrowed-c<s,t>` then should be used to get the raw pointers to be used in the ffi functions
// Higher level apis to c libraries should then provide an interface using `owned-c<t>` and `borrowed-c<s,t>` instead of `c-pointer<t>`
pub fun ptr/unsafe-malloc<t>(n: int32, ?size-of: (c-null<t>) -> int32): c-pointer<t>
  C-pointer(int/malloc(n, size-of(cnull())))

// !!!WARNING!!! UNSAFE API
// Allocate `n` elements of type `t` using C's `malloc` and return a managed pointer to the array
// Type `t` should:
// - Be an opaque type in Koka corresponding to a C type (e.g. `pub type cstruct` with no members)
// - Have a `size-of` function that returns the size of the structure in bytes
//
// NOTES:
// Prefer using `array/malloc-c` or `single/malloc-c` instead of this function which return a managed pointer.
// Raw `c-pointer<t>` should be used in low-level generated koka ffi functions since the pointer is unknown to be managed or not.
// Conversion routines for `owned-c<t>` and `borrowed-c<s,t>` then should be used to get the raw pointers to be used in the ffi functions
// Higher level apis to c libraries should then provide an interface using `owned-c<t>` and `borrowed-c<s,t>` instead of `c-pointer<t>`
pub fun ptr/unsafe-malloc-c<t>(n: int32, ?size-of: (c-null<t>) -> int32): c-pointer<t>
  C-pointer(int/malloc-c(n, size-of(cnull())))

// Transform a C ptr into a managed koka value, which will be freed by `kk_free` when koka's reference count reaches 0
extern c-own-extern(c: intptr_t): a
  c inline "kk_cptr_raw_box(&kk_free_fun, (void *)#1, kk_context())"

// Transform a C ptr into a managed koka value, which will be freed by C's `free` when koka's reference count reaches 0
extern c-own-free-calloc-extern(c: intptr_t): a
  c inline "kk_cptr_raw_box(&kk_free_calloc, (void *)#1, kk_context())"

// Transform a C ptr `c` into a koka value that holds the c reference without freeing it
// The pointer should be valid for the duration of the callback `f`.
extern c-borrow-extern(c: intptr_t, f: b -> e a): e a
  c "kk_borrow_ptr"

// !!!WARNING!!!: Extremely unsafe API (needed for `c-borrow`), get approval to use anywhere else.
extern unsafe-cast(b: b): a
  c inline "#1"

// Transform an unmanaged C ptr into a managed koka reference to C memory
// Ensure the pointer is not going to be freed by C code, otherwise use `c-borrow` instead
// Also ensure the memory was allocated using `kk_malloc`
pub fun c-own<t>(t: c-pointer<t>): owned-c<t>
  Owned-c(t.ptr.c-own-extern)

// Transform an unmanaged C ptr into a managed koka reference to C memory
// Ensure the pointer is not going to be freed by C code, otherwise use `c-borrow` instead
// Also ensure the memory was allocated using C's `malloc`
pub fun c-own-free-calloc<t>(t: c-pointer<t>): owned-c<t>
  Owned-c(t.ptr.c-own-free-calloc-extern)

// Transform an unmanaged C ptr into a borrowed koka reference to C memory
// The pointer must be guaranteed to be valid for the duration of the callback `f`
pub fun c-borrow<t>(c: c-pointer<t>, f: forall<s> borrowed-c<s,t> -> e a): e a
  c-borrow-extern(c.ptr, fn(p) f(Borrowed-c(p.unsafe-cast())))

// Transform a koka `owned-c` managed pointer into a C ptr 
// Keeps the koka reference alive during the scope of the callback `f`
extern owned/with-ptr-extern(^t: b, f: intptr_t -> e a): e a
  c inline "kk_owned_with_ptr(kk_std_cextern__owned_c_unbox(#1, KK_BORROWED, kk_context()).owned, #2, kk_context())"

// Transform a koka `owned-c` managed pointer into a C ptr 
// Keeps the koka reference alive during the scope of the callback `f`
pub fun owned/with-ptr(t: owned-c<t>, f: c-pointer<t> -> e a): e a
  owned/with-ptr-extern(t, fn(p) f(C-pointer(p)))

// Transform a koka `borrowed-c` managed pointer into a C ptr
// Keeps the koka reference alive during the scope of the callback `f`
extern borrowed/with-ptr-extern(^t: b, f: intptr_t -> e a): e a
  c inline "kk_borrowed_with_ptr(kk_std_cextern__borrowed_c_unbox(#1, KK_BORROWED, kk_context()).borrowed, #2, kk_context())"

// Transform a koka `borrowed-c` managed pointer into a C ptr
// Keeps the koka reference alive during the scope of the callback `f`
pub fun borrowed/with-ptr(t: borrowed-c<s,t>, f: c-pointer<t> -> e a): e a
  borrowed/with-ptr-extern(t, fn(i) f(C-pointer(i)))

// !!!WARNING!!! Extremely UNSAFE API
// Get the raw C pointer from a `borrowed-c` managed pointer to use immediately in an ffi function
// This doesn't return a typed pointer, and accepts any boxed type as input, so it is very dangerous
//   Use `borrowed/with-ptr` most of the time and
//       `borrow/use-ffi-ptr` if directly passing to an safe ffi call
pub extern unsafe-borrowed-ffi-ptr-extern<t>(c: b): intptr_t
  c inline "(kk_addr_t)kk_cptr_unbox_borrowed(kk_std_cextern__borrowed_c_unbox(#1, KK_BORROWED, kk_context()).borrowed, kk_context())"

// !!!WARNING!!! UNSAFE API
// Get the raw C pointer from an `borrowed-c` managed pointer to use immediately in an ffi function
// Not safe to pass around Koka code
// However, since an immediate use is still within the scope of the `borrowed-c` it is safe
//   This is due borrowed pointers being guaranteed to be valid during their whole scope (the lambda enclosing the call to this method) 
//   A similar api for `owned-c` is not possible since converting an owned pointer to a raw pointer could allow the owned pointer to be freed if this was its last use
//   For owned pointers use `owned/with-ptr` instead
pub fun borrow/use-ffi-ptr<t>(c: borrowed-c<s,t>): c-pointer<t>
  C-pointer(c.unsafe-borrowed-ffi-ptr-extern)

// Transform a koka `owned-c` managed pointer to an array into a C ptr pointing to the element at index `idx` of type `t` and size `size-of(cnull())`
// Keeps the koka reference alive during the scope of the callback `f`
// This is guaranteed due to be this being an external function (`f` is not inlineable), and `t` being borrowed
extern offset/with-ptr(^t: b, idx: ssize_t, f: intptr_t -> e a, size-of: int32): e a
  c inline "kk_owned_with_ptr_idx(kk_std_cextern__owned_c_unbox(#1, KK_BORROWED, kk_context()).owned, #2, #3, #4, kk_context())"

// Transform a koka `owned-c` managed pointer to an array into a C ptr pointing to the element at index `idx` of type `t` and size `size-of(cnull())`
// Keeps the koka reference alive during the scope of the callback `f`
pub fun c-array/with-ptr(t: owned-c<c-array<t>>, idx: ssize_t, f: forall<s> borrowed-c<s,t> -> e a, ?size-of: (c-null<t>) -> int32): e a
  offset/with-ptr(t, idx, fn(p) c-borrow(C-pointer(p), f), size-of(cnull()))

// Transform an assumed pointer to a C string into a Koka string
// Copies the memory
extern ptr/to-string(ptr: intptr_t): string
  c inline "kk_string_alloc_raw((const char *)#1, false, kk_context())"

// Transform an unmanaged `c-pointer<int8>` into a Koka string
// Copies the memory
pub fun cptr/to-string(c: c-pointer<int8>): string
  ptr/to-string(c.ptr)

// Transform an assumed pointer to a C string of length len into a Koka string
// Copies the memory
// Assume the array is non-null terminated and adds the terminating character
extern strlen-ptr/to-string(ptr: intptr_t, len: int64): string
  c inline "kk_string_alloc_raw_buff(#2, (const char *)#1, false, kk_context())"

// Transform an unmanaged `c-pointer<int8>` into a Koka string of length len
// Copies the memory
// Assume the array is non-null terminated and adds the terminating character
pub fun cptr-len/to-string(c: c-pointer<int8>, len: int64): string
  strlen-ptr/to-string(c.ptr, len)

// Borrows the c pointer to a koka managed string for the duration of the callback `f`
extern ptr/with-c-string(^s: string, f: intptr_t -> e a): e a
  c "kk_with_c_string"

// Borrows the c pointer to a koka managed string for the duration of the callback `f`
pub fun cptr/with-c-string(^s: string, f: forall<s> borrowed-c<s,int8> -> e a): e a
  with-c-string(s, fn(p) c-borrow(C-pointer(p), f))