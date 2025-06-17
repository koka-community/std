
kk_unit_t kk_vector_clear(kk_vector_t v, kk_ssize_t stop, kk_context_t* ctx);

kk_unit_t kk_vector_clear_at(kk_vector_t v, kk_ssize_t pos, kk_context_t* ctx);

kk_vector_t kk_vector_from_cint32array(int32_t* array, kk_ssize_t len, kk_context_t* ctx); 
kk_vector_t kk_vector_from_cint64array(int64_t* array, kk_ssize_t len, kk_context_t* ctx); 
kk_vector_t kk_vector_from_cintarray(kk_intx_t* carray, kk_ssize_t len, kk_context_t* ctx);
