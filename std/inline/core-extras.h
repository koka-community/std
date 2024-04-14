/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/



// This is taken from here https://github.com/koka-lang/koka/blob/dev/lib/std/core/inline/vector.h
// Only the name is modified so that it doesn't collide into the original.
static inline kk_unit_t kk_vector_unsafe_assign_community( kk_vector_t v, kk_ssize_t i, kk_box_t x, kk_context_t* ctx  ) {
  kk_ssize_t len;
  kk_box_t* p = kk_vector_buf_borrow(v,&len,ctx);
  kk_assert(i < len);
  p[i] = x;
  kk_vector_drop(v,ctx); // TODO: use borrowing
  return kk_Unit;
}

// This is taken from here https://github.com/koka-lang/koka/blob/dev/kklib/include/kklib/vector.h
// Only the name is modified so that it doesn't collide into the original.
static inline kk_box_t kk_vector_at_borrow_community(const kk_vector_t v, kk_ssize_t i, kk_context_t* ctx) {
  kk_assert(i < kk_vector_len_borrow(v,ctx));
  kk_box_t res = kk_box_dup(kk_vector_buf_borrow(v, NULL, ctx)[i],ctx);
  return res;
}