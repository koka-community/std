


kk_unit_t kk_vector_clear(kk_vector_t v, kk_ssize_t stop, kk_context_t* ctx) {
    kk_ssize_t length;
    kk_box_t* vec = kk_vector_buf_borrow(v, &length, ctx);
    const kk_ssize_t true_stop = (stop > length ? length : stop);
    for (kk_ssize_t i = 0; i < true_stop; i++) {
        kk_box_drop(vec[i], ctx);
        vec[i] = kk_box_null();
    }
    return kk_Unit;
}

kk_unit_t kk_vector_clear_at(kk_vector_t v, kk_ssize_t pos, kk_context_t* ctx) {
    kk_ssize_t length;
    kk_box_t* vec = kk_vector_buf_borrow(v, &length, ctx);
    kk_box_drop(vec[pos], ctx);
    vec[pos] = kk_box_null();
    return kk_Unit;
}

kk_vector_t kk_vector_realloc_borrow(kk_vector_t vec, kk_ssize_t newlen, kk_box_t def, kk_context_t* ctx) {
  kk_ssize_t len;
  kk_box_t* src = kk_vector_buf_borrow(vec, &len, ctx);
  kk_box_t* dest;
  kk_vector_t vdest = kk_vector_alloc_uninit(newlen, &dest, ctx);
  const kk_ssize_t n = (len > newlen ? newlen : len);
  for (kk_ssize_t i = 0; i < n; i++) {
    dest[i] = kk_box_dup(src[i], ctx);
  }
  kk_vector_init_borrow(vdest, n, def, ctx); // set extra entries to default value
  return vdest;
}

kk_vector_t kk_vector_copy_borrow(kk_vector_t vec, kk_context_t* ctx) {
  kk_ssize_t len = kk_vector_len_borrow(vec, ctx);
  return kk_vector_realloc_borrow(vec, len, kk_box_null(), ctx);
}