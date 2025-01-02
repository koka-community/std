/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/


static const uint64_t PRIME_1 = 0x9E3779B185EBCA87;
static const uint64_t PRIME_2 = 0xC2B2AE3D27D4EB4F;
static const uint64_t PRIME_3 = 0x165667B19E3779F9;
static const uint64_t PRIME_4 = 0x85EBCA77C2B2AE63;
static const uint64_t PRIME_5 = 0x27D4EB2F165667C5;
static const size_t CHUNK_SIZE = sizeof(uint64_t) * 4;

static int64_t kk_thread_seed(kk_context_t* ctx) {
    return ctx->thread_id;
}


static kk_integer_t kk_string_hash(kk_string_t s, int64_t seed, kk_context_t* ctx) {

    kk_ssize_t length;
    uint8_t* str = (uint8_t*)kk_string_buf_borrow(s, &length, ctx);
    int64_t result = xxh64(str, length, seed);
    kk_string_drop(s, ctx);
    return kk_integer_from_int64(result, ctx);
}

static kk_integer_t kk_hash_vector_int64(kk_vector_t v, int64_t seed, kk_context_t* ctx) {

    kk_ssize_t length;
    kk_box_t* buf = kk_vector_buf_borrow(v, &length, ctx);
    uint8_t* input_ptr = malloc(sizeof(uint64_t) * length);
    for (kk_ssize_t i = 0; i < length; i++) {
        ((int64_t*)input_ptr)[i] =  kk_int64_unbox(buf[i], KK_OWNED, ctx);
    }

    int64_t result = xxh64(input_ptr, sizeof(uint64_t) * length * 8, seed);
    free(input_ptr);
    input_ptr = NULL;
    return kk_integer_from_int64(result, ctx);
}

static kk_integer_t kk_integer_hash(kk_integer_t i, int64_t seed, kk_context_t* ctx) {
    if (kk_is_smallint(i)) {
        return hash_small_integer(i, seed, ctx);
    } else {
        return hash_big_integer(i, seed, ctx);
    }
}

static kk_integer_t hash_small_integer(kk_integer_t i, int64_t seed, kk_context_t* ctx) {

    int64_t input = 0 | kk_smallint_from_integer(i);
    uint8_t* input_ptr = ((uint8_t*)&input);
    int64_t result = xxh64(input_ptr, sizeof(input), seed);
    return kk_integer_from_int64(result, ctx);
}

static kk_integer_t hash_big_integer(kk_integer_t i, int64_t seed, kk_context_t* ctx) {

    kk_warning_message("Warning! Hashing big integers may be incorrect.\n");
    uint8_t* input_ptr = ((uint8_t*)&i);
    int64_t result = xxh64(input_ptr, sizeof(kk_integer_t), seed);
    return kk_integer_from_int64(result, ctx);
}

static uint64_t xxh64_read_u64(uint8_t* input, size_t cursor) {
    uint64_t output = 0 | input[0];
    output = output 
        | ((uint64_t)input[cursor + 1]) << 8
        | ((uint64_t)input[cursor + 2]) << 16
        | ((uint64_t)input[cursor + 3]) << 24
        | ((uint64_t)input[cursor + 4]) << 32
        | ((uint64_t)input[cursor + 5]) << 40
        | ((uint64_t)input[cursor + 6]) << 48
        | ((uint64_t)input[cursor + 7]) << 56;
    return output;
}

static uint32_t xxh64_read_u32(uint8_t* input, size_t cursor) {
    uint32_t output = 0 | input[0];
    output = output 
        | ((uint64_t)input[cursor + 1]) << 8
        | ((uint64_t)input[cursor + 2]) << 16
        | ((uint64_t)input[cursor + 3]) << 24;
    return output;
}

static uint64_t xxh64(uint8_t* input, size_t input_length, uint64_t seed) {
    size_t cursor = 0;
    uint64_t result = 0;

    if (input_length >= CHUNK_SIZE) {
        uint64_t v1 = seed + PRIME_1 + PRIME_2;
        uint64_t v2 = seed + PRIME_2;
        uint64_t v3 = seed;
        uint64_t v4 = seed - PRIME_1;

        do {
            v1 = xxh64_round(v1, xxh64_read_u64(input, cursor));
            cursor += sizeof(uint64_t);
            v2 = xxh64_round(v2, xxh64_read_u64(input, cursor));
            cursor += sizeof(uint64_t);
            v3 = xxh64_round(v3, xxh64_read_u64(input, cursor));
            cursor += sizeof(uint64_t);
            v4 = xxh64_round(v4, xxh64_read_u64(input, cursor));
            cursor += sizeof(uint64_t);

        } while (input_length - cursor >= CHUNK_SIZE);

        result = kk_bits_rotl64(v1, 1) + kk_bits_rotl64(v2, 7) + kk_bits_rotl64(v3, 12) + kk_bits_rotl64(v4, 18);
        
        result = xxh64_merge_round(result, v1);
        result = xxh64_merge_round(result, v2);
        result = xxh64_merge_round(result, v3);
        result = xxh64_merge_round(result, v4);
    } else {
        result = seed + PRIME_5;
    }

    result = result + input_length;

    return xxh64_finalize(result, input, input_length, cursor);
}

static uint64_t xxh64_round(uint64_t acc, uint64_t input) {
    return kk_bits_rotl64(acc + input * PRIME_2, 31) * PRIME_1;
}

static uint64_t xxh64_merge_round(uint64_t acc, uint64_t value) {
    acc ^= xxh64_round(0, value);
    return acc * PRIME_1 + PRIME_4;
}

static uint64_t xxh64_finalize(uint64_t input, uint8_t* data, size_t data_length, uint64_t cursor) {
    uint64_t len = data_length - cursor;

    while (len >= 8) {
        input ^= xxh64_round(0, xxh64_read_u64(data, cursor));
        cursor += sizeof(uint64_t);
        len -= sizeof(uint64_t);
        input = kk_bits_rotl64(input, 27) * PRIME_1 + PRIME_4;
    }

    if (len >= 4) {
        input ^= ((uint64_t) xxh64_read_u32) * PRIME_1;
        cursor += sizeof(uint32_t);
        len -= sizeof(uint32_t);
        input = kk_bits_rotl64(input, 23) * PRIME_2 + PRIME_3;
    }

    while (len > 0) {
        input ^= data[cursor] * PRIME_5;
        cursor += sizeof(uint8_t);
        len -= sizeof(uint8_t);
        input = kk_bits_rotl64(input, 11) * PRIME_1;
    }

    return xxh64_avalanche(input);
}

static uint64_t xxh64_avalanche(uint64_t input) {
    input ^= input >> 33;
    input = input * PRIME_2;
    input ^= input >> 29;
    input = input * PRIME_3;
    input ^= input >> 32;
    return input;
}