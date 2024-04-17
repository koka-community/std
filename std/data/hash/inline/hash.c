/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/


const uint64_t PRIME_1 = 0x9E3779B185EBCA87;
const uint64_t PRIME_2 = 0xC2B2AE3D27D4EB4F;
const uint64_t PRIME_3 = 0x165667B19E3779F9;
const uint64_t PRIME_4 = 0x85EBCA77C2B2AE63;
const uint64_t PRIME_5 = 0x27D4EB2F165667C5;
const size_t CHUNK_SIZE = sizeof(uint64_t) * 4;

kk_integer_t kk_integer_hash(kk_integer_t i, int64_t seed, kk_context_t* ctx) {
    if (kk_is_smallint(i)) {
        return hash_small_integer(i, seed, ctx);
    } else {
        return hash_big_integer(i, seed, ctx);
    }
}



kk_integer_t hash_small_integer(kk_integer_t i, int64_t seed, kk_context_t* ctx) {

    int64_t input = 0 | ((i.ibox -1) / 4);
    uint8_t* input_ptr = ((uint8_t*)&input);
    int64_t result = xxh64(input_ptr, sizeof(input), seed);
    return kk_integer_from_int64(result, ctx);
}

kk_integer_t hash_big_integer(kk_integer_t i, int64_t seed, kk_context_t* ctx) {

    fprintf(stderr, "Warning! Hashing big integers may be incorrect.\n");
    uint8_t* input_ptr = ((uint8_t*)&i);
    int64_t result = xxh64(input_ptr, sizeof(kk_integer_t), seed);
    return kk_integer_from_int64(result, ctx);
}


uint64_t xxh64_read_u64(uint8_t* input, size_t cursor) {
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

uint32_t xxh64_read_u32(uint8_t* input, size_t cursor) {
    uint32_t output = 0 | input[0];
    output = output 
        | ((uint64_t)input[cursor + 1]) << 8
        | ((uint64_t)input[cursor + 2]) << 16
        | ((uint64_t)input[cursor + 3]) << 24;
    return output;
}

uint64_t xxh64(uint8_t* input, size_t input_length, uint64_t seed) {
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

        result = rotate_left_u64(v1, 1) + rotate_left_u64(v2, 7) + rotate_left_u64(v3, 12) + rotate_left_u64(v4, 18);
        
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

uint64_t rotate_left_u64(uint64_t input, uint8_t amount) {
    if (amount == 0) {
        return input;
    }
    return (input << amount) | (input >> (sizeof(uint64_t) * 8 - amount));
}  

uint64_t xxh64_round(uint64_t acc, uint64_t input) {
    return rotate_left_u64(acc + input * PRIME_2, 31) * PRIME_1;
}

uint64_t xxh64_merge_round(uint64_t acc, uint64_t value) {
    acc ^= xxh64_round(0, value);
    return acc * PRIME_1 + PRIME_4;
}

uint64_t xxh64_finalize(uint64_t input, uint8_t* data, size_t data_length, uint64_t cursor) {
    uint64_t len = data_length - cursor;

    while (len >= 8) {
        input ^= xxh64_round(0, xxh64_read_u64(data, cursor));
        cursor += sizeof(uint64_t);
        len -= sizeof(uint64_t);
        input = rotate_left_u64(input, 27) * PRIME_1 + PRIME_4;
    }

    if (len >= 4) {
        input ^= ((uint64_t) xxh64_read_u32) * PRIME_1;
        cursor += sizeof(uint32_t);
        len -= sizeof(uint32_t);
        input = rotate_left_u64(input, 23) * PRIME_2 + PRIME_3;
    }

    while (len > 0) {
        input ^= data[cursor] * PRIME_5;
        cursor += sizeof(uint8_t);
        len -= sizeof(uint8_t);
        input = rotate_left_u64(input, 11) * PRIME_1;
    }

    return xxh64_avalanche(input);
}

uint64_t xxh64_avalanche(uint64_t input) {
    input ^= input >> 33;
    input = input * PRIME_2;
    input ^= input >> 29;
    input = input * PRIME_3;
    input ^= input >> 32;
    return input;
}