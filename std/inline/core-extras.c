


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