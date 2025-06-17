#if defined(WIN32)
#define _UNICODE
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <io.h>
#include <direct.h>
#else
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <fcntl.h>
#endif

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

kk_vector_t kk_vector_from_cint32array(int32_t* carray, kk_ssize_t len, kk_context_t* ctx) {
    kk_box_t* array;
    kk_vector_t vec = kk_vector_alloc_uninit(len, &array, ctx);
    for (kk_ssize_t i = 0; i < len; i++){
        array[i] = kk_integer_box(kk_integer_from_int32(carray[i], ctx), ctx);
    }
    return vec;
}

kk_vector_t kk_vector_from_cint64array(int64_t* carray, kk_ssize_t len, kk_context_t* ctx) {
    kk_box_t* array;
    kk_vector_t vec = kk_vector_alloc_uninit(len, &array, ctx);
    for (kk_ssize_t i = 0; i < len; i++){
        array[i] = kk_integer_box(kk_integer_from_int64(carray[i], ctx), ctx);
    }
    return vec;
}

kk_vector_t kk_vector_from_cintarray(kk_intx_t* carray, kk_ssize_t len, kk_context_t* ctx) {
    kk_box_t* array;
    kk_vector_t vec = kk_vector_alloc_uninit(len, &array, ctx);
    for (kk_ssize_t i = 0; i < len; i++){
        array[i] = kk_integer_box(kk_integer_from_int(carray[i], ctx), ctx);
    }
    return vec;
}

kk_vector_t kk_int8_vector_from_uint8array(unsigned char* carray, kk_ssize_t len, kk_context_t* ctx) {
    kk_box_t* array;
    kk_vector_t vec = kk_vector_alloc_uninit(len, &array, ctx);
    for (kk_ssize_t i = 0; i < len; i++){
        array[i] = kk_int8_box(carray[i], ctx);
    }
    return vec;
}

// Below is shamelessly copied from the Koka runtime (since it is not exposed publicly)
// with minor modifications to the read file to read to a vector of int8s
typedef int kk_file_t;

#ifdef WIN32
typedef struct _stat64  kk_stat_t;
#else
typedef struct stat     kk_stat_t;
#endif

static int kk_posix_close(kk_file_t f) {
#ifdef WIN32
  return (_close(f) < 0 ? errno : 0);
#else
  return (close(f) < 0 ? errno : 0);
#endif
}

static int kk_posix_fstat(kk_file_t f, kk_stat_t* st) {
#ifdef WIN32
  return (_fstat64(f, st) < 0 ? errno : 0);
#else
  return (fstat(f, st) < 0 ? errno : 0);
#endif
}

static int kk_posix_fsize(kk_file_t f, kk_ssize_t* fsize) {
  *fsize = 0;
  kk_stat_t st;
  int err = kk_posix_fstat(f, &st);
  if (err != 0) return err;
  *fsize = (kk_ssize_t)st.st_size;
  return 0;
}

// Read at most `buflen` bytes from `inp` into `buf`. Return `0` on success (or an error code).
static int kk_posix_read_retry(const kk_file_t inp, uint8_t* buf, const kk_ssize_t buflen, kk_ssize_t* read_count) {
  int err = 0;
  kk_ssize_t ofs = 0;
  do {
    kk_ssize_t todo = buflen - ofs;
    if (todo < 0) todo = 0;
    #ifdef WIN32
    if (todo > INT32_MAX) todo = INT32_MAX;  // on windows read in chunks of at most 2GiB
    kk_ssize_t n = _read(inp, buf + ofs, (unsigned)(todo));
    #else
    if (todo > KK_SSIZE_MAX) todo = KK_SSIZE_MAX;
    kk_ssize_t n = read(inp, buf + ofs, todo);
    #endif
    if (n < 0) {
      if (errno != EAGAIN && errno != EINTR) {
        err = errno;
        break;
      }
      // otherwise try again
    }
    else if (n == 0) { // eof
      break;
    }
    else {
      ofs += n;
    }
  } while (ofs < buflen);
  if (read_count != NULL) {
    *read_count = ofs;
  }
  return err;
}

static int kk_posix_open(kk_string_t path, int flags, int create_perm, kk_file_t* f, kk_context_t* ctx) {
  *f = 0;
#ifdef WIN32
  kk_with_string_as_qutf16w_borrow(path, wpath, ctx) {
    *f = _wopen(wpath, flags, create_perm);
  }
#else
  kk_with_string_as_qutf8_borrow(path, bpath, ctx) {
    *f = open(bpath, flags, create_perm);
  }
#endif
  kk_string_drop(path,ctx);
  return (*f < 0 ? errno : 0);
}

kk_vector_t kk_os_read_byte_file(kk_string_t path, kk_context_t* ctx)
{
  kk_file_t f;
  int err = kk_posix_open(path, O_RDONLY, 0, &f, ctx);
  if (err != 0) exit(-1);

  kk_ssize_t len;
  err = kk_posix_fsize(f, &len);
  if (err != 0) {
    kk_posix_close(f);
    exit(-1);
  }
  uint8_t* cbuf = (uint8_t*)kk_malloc(len, ctx);

  kk_ssize_t nread;
  err = kk_posix_read_retry(f, cbuf, len, &nread);
  kk_posix_close(f);
  if (err < 0) {
    kk_free(cbuf, ctx);
    exit(-1);
  }
  if (nread < len) {
    cbuf = (uint8_t*)kk_realloc((void*)cbuf, nread, ctx);
  }
  return kk_int8_vector_from_uint8array(cbuf, nread, ctx);
}
