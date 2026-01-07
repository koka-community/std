// TODO: these operations can be upstreamed into std/core/types

extern import
  c file "inline/atomic.c"

// Update ref atomically, using locking if the reference is shared between threads. Returns the
// previous value of `ref`
pub extern get-and-update(^ref: ref<h, a>, modify: (a) -> div a): <div,st<h>> a
  c "kk_ref_get_and_update_borrow"

// Update ref atomically, lock-free. Returns whether the replacement occurred, i.e. `false`
// when the value stored in `ref` does not match `expected`.
// Note that equality here is at the byte level - only canonical value types and
// references to the same memory location will be considered equal.
// TODO: this could return (bool, maybe(a)), where you only get the previous value if it's a value type
pub extern compare-and-set(^ref: ref<h, a>, expected: a, replacement: b): <div,st<h>> bool
  c "kk_ref_compare_and_set_borrow"

