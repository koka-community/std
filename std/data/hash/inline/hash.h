/*----------------------------------------------------------------------------
   Copyright 2024, Koka-Community Authors

   Licensed under the MIT License ("The License"). You may not
   use this file except in compliance with the License. A copy of the License
   can be found in the LICENSE file at the root of this distribution.
----------------------------------------------------------------------------*/


kk_integer_t kk_integer_hash(kk_integer_t i, int64_t seed, kk_context_t* ctx);

kk_integer_t hash_small_integer(kk_integer_t i, int64_t seed, kk_context_t* ctx);

kk_integer_t hash_big_integer(kk_integer_t i, int64_t seed, kk_context_t* ctx);

uint64_t xxh64_read_u64(uint8_t* input, size_t cursor);

uint32_t xxh64_read_u32(uint8_t* input, size_t cursor);

uint64_t xxh64(uint8_t* input, size_t input_length, uint64_t seed);

uint64_t rotate_left_u64(uint64_t input, uint8_t amount);

uint64_t xxh64_round(uint64_t acc, uint64_t input);

uint64_t xxh64_merge_round(uint64_t acc, uint64_t value);

uint64_t xxh64_finalize(uint64_t input, uint8_t* data, size_t data_length, uint64_t cursor);

uint64_t xxh64_avalanche(uint64_t input);
