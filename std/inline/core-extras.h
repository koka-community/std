
kk_unit_t kk_vector_clear(kk_vector_t v, kk_ssize_t stop, kk_context_t* ctx);

kk_unit_t kk_vector_clear_at(kk_vector_t v, kk_ssize_t pos, kk_context_t* ctx);


static inline kk_unit_t kk_vector_unsafe_assign_borrow( kk_vector_t v, kk_ssize_t i, kk_box_t x, kk_context_t* ctx  ) {
  kk_ssize_t len;
  kk_box_t* p = kk_vector_buf_borrow(v,&len,ctx);
  kk_assert(i < len);
  p[i] = x;
  return kk_Unit;
}

kk_vector_t kk_vector_realloc_borrow(kk_vector_t vec, kk_ssize_t newlen, kk_box_t def, kk_context_t* ctx);

kk_vector_t kk_vector_copy_borrow(kk_vector_t vec, kk_context_t* ctx);