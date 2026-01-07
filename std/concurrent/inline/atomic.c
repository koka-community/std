static kk_box_t kk_ref_get_and_update_borrow(kk_ref_t _r, kk_function_t update, kk_context_t* ctx) {
  struct kk_ref_s* r = kk_datatype_as_assert(struct kk_ref_s*, _r, KK_TAG_REF, ctx);
  if kk_likely(!kk_block_is_thread_shared(&r->_block)) {
    // single-threaded, we can use borrowed and guarantee it won't be dropped
    kk_box_t borrowed; borrowed.box = kk_atomic_load_relaxed(&r->value);
    kk_box_t prev = kk_box_dup(borrowed, ctx);
    kk_box_t replacement = kk_function_call(kk_box_t,(kk_function_t,kk_box_t,kk_context_t*), update, (update, prev, ctx), ctx);

    kk_atomic_store_relaxed(&r->value, replacement.box);
    // we've replaced the ref's value, so `borrowed` is now owned
    return borrowed;
  } else {
    // thread shared
    kk_box_t borrowed;
    borrowed.box = kk_atomic_load_relaxed(&r->value);

    // Like `get`, we replace with a sentinel 0 to effectively lock the ref until we can store the new value.
    // This logic must be kept in sync with `kk_ref_get_thread_shared`
    do {
      if (borrowed.box == 0) { borrowed.box = 1; }     // expect any value but 0
    } while (!kk_atomic_cas_weak_relaxed(&r->value, &borrowed.box, 0));

    // we got it, and hold the "locked" reference (`r->value == 0`)
    kk_box_t prev = kk_box_dup(borrowed,ctx);
    kk_box_t replacement = kk_function_call(kk_box_t,(kk_function_t,kk_box_t,kk_context_t*), update, (update, kk_box_dup(prev, ctx), ctx), ctx);

    // replace guard with new value
    kk_intb_t guard = 0;
    if (!kk_atomic_cas_strong_relaxed(&r->value, &guard, replacement.box)) {
      // should never happen!
      assert(false);
      kk_fatal_error(ENOTRECOVERABLE, "ref sentinel has been replaced");
    }
    return prev;
  }
}

kk_decl_export bool kk_ref_compare_and_set_borrow(kk_ref_t _r, kk_box_t expected, kk_box_t replacement, kk_context_t* ctx) {
  struct kk_ref_s* r = kk_datatype_as_assert(struct kk_ref_s*, _r, KK_TAG_REF, ctx);
  bool result;
  if (kk_block_is_thread_shared(&r->_block)) {
    // `tmp` is not a `dup`, we just need a fresh kk_box_t for CAS to write to
    kk_box_t tmp;
retry:
    tmp.box = expected.box;
    result = kk_atomic_cas_weak_relaxed(&r->value, &tmp.box, replacement.box);
    if (!result) {
      // we need to retry when:
      // - the values _were_ equal but the CAS didn't proceed (due to use of `weak`), or
      // - the ref was temporarily locked, i.e. set to 0 (see `kk_ref_get_thread_shared`)
      if (tmp.box == 0 || tmp.box == expected.box) {
        goto retry;
      }
    }
  } else {
    // single-threaded, we can just operate serially and don't need to consider the `0` case
    kk_box_t borrowed; borrowed.box = kk_atomic_load_relaxed(&r->value);
    result = borrowed.box == expected.box;
    if (result) {
      kk_atomic_store_relaxed(&r->value, replacement.box);
    }
  }

  if (result) {
    kk_box_drop(expected,ctx); // we took the expected value out of `ref`, drop it
  } else {
    kk_box_drop(replacement,ctx);
  }

  kk_box_drop(expected,ctx); // our copy
  return result;
}
