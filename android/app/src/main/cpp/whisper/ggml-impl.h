#pragma once

// GGML internal header

#include "ggml.h"

#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef __ARM_FEATURE_SVE
#include <arm_sve.h>
#endif

#if defined(__ARM_NEON) && !defined(__CUDACC__) && !defined(__MUSACC__)
#include <arm_neon.h>
#endif

#if defined(__F16C__)
#include <immintrin.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

void ggml_print_backtrace(void);

#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef MAX
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#endif

#define TENSOR_ALIGNMENT 32

#ifndef __cplusplus
#ifndef static_assert
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201100L)
#define static_assert(cond, msg) _Static_assert(cond, msg)
#else
#define static_assert(cond, msg) struct global_scope_noop_trick
#endif
#endif
#endif

static inline int ggml_up32(int n) { return (n + 31) & ~31; }

static inline int ggml_up(int n, int m) {
  GGML_ASSERT((m & (m - 1)) == 0);
  return (n + m - 1) & ~(m - 1);
}

static bool ggml_are_same_layout(const struct ggml_tensor *a,
                                 const struct ggml_tensor *b) {
  if (a->type != b->type) {
    return false;
  }
  for (int i = 0; i < GGML_MAX_DIMS; i++) {
    if (a->ne[i] != b->ne[i]) {
      return false;
    }
    if (a->nb[i] != b->nb[i]) {
      return false;
    }
  }
  return true;
}

static bool ggml_op_is_empty(enum ggml_op op) {
  switch (op) {
  case GGML_OP_NONE:
  case GGML_OP_RESHAPE:
  case GGML_OP_TRANSPOSE:
  case GGML_OP_VIEW:
  case GGML_OP_PERMUTE:
    return true;
  default:
    return false;
  }
}

static inline float ggml_compute_softplus_f32(float input) {
  return (input > 20.0f) ? input : logf(1 + expf(input));
}

GGML_ATTRIBUTE_FORMAT(2, 3)
GGML_API void ggml_log_internal(enum ggml_log_level level, const char *format,
                                ...);
GGML_API void ggml_log_callback_default(enum ggml_log_level level,
                                        const char *text, void *user_data);

#define GGML_LOG(...) ggml_log_internal(GGML_LOG_LEVEL_NONE, __VA_ARGS__)
#define GGML_LOG_INFO(...) ggml_log_internal(GGML_LOG_LEVEL_INFO, __VA_ARGS__)
#define GGML_LOG_WARN(...) ggml_log_internal(GGML_LOG_LEVEL_WARN, __VA_ARGS__)
#define GGML_LOG_ERROR(...) ggml_log_internal(GGML_LOG_LEVEL_ERROR, __VA_ARGS__)
#define GGML_LOG_DEBUG(...) ggml_log_internal(GGML_LOG_LEVEL_DEBUG, __VA_ARGS__)
#define GGML_LOG_CONT(...) ggml_log_internal(GGML_LOG_LEVEL_CONT, __VA_ARGS__)

#define GGML_DEBUG 0

#if (GGML_DEBUG >= 1)
#define GGML_PRINT_DEBUG(...) GGML_LOG_DEBUG(__VA_ARGS__)
#else
#define GGML_PRINT_DEBUG(...)
#endif

#if (GGML_DEBUG >= 5)
#define GGML_PRINT_DEBUG_5(...) GGML_LOG_DEBUG(__VA_ARGS__)
#else
#define GGML_PRINT_DEBUG_5(...)
#endif

#if (GGML_DEBUG >= 10)
#define GGML_PRINT_DEBUG_10(...) GGML_LOG_DEBUG(__VA_ARGS__)
#else
#define GGML_PRINT_DEBUG_10(...)
#endif

static void ggml_set_op_params(struct ggml_tensor *tensor, const void *params,
                               size_t params_size) {
  GGML_ASSERT(tensor != NULL);
  assert(params_size <= GGML_MAX_OP_PARAMS);
  memcpy(tensor->op_params, params, params_size);
}

static int32_t ggml_get_op_params_i32(const struct ggml_tensor *tensor,
                                      uint32_t i) {
  assert(i < GGML_MAX_OP_PARAMS / sizeof(int32_t));
  return ((const int32_t *)(tensor->op_params))[i];
}

static float ggml_get_op_params_f32(const struct ggml_tensor *tensor,
                                    uint32_t i) {
  assert(i < GGML_MAX_OP_PARAMS / sizeof(float));
  return ((const float *)(tensor->op_params))[i];
}

static void ggml_set_op_params_i32(struct ggml_tensor *tensor, uint32_t i,
                                   int32_t value) {
  assert(i < GGML_MAX_OP_PARAMS / sizeof(int32_t));
  ((int32_t *)(tensor->op_params))[i] = value;
}

static void ggml_set_op_params_f32(struct ggml_tensor *tensor, uint32_t i,
                                   float value) {
  assert(i < GGML_MAX_OP_PARAMS / sizeof(float));
  ((float *)(tensor->op_params))[i] = value;
}

typedef uint32_t ggml_bitset_t;

static_assert(sizeof(ggml_bitset_t) == 4, "bitset_t constants must be updated");
#define BITSET_SHR 5
#define BITSET_MASK (sizeof(ggml_bitset_t) * 8 - 1)

static size_t ggml_bitset_size(size_t n) {
  return (n + BITSET_MASK) >> BITSET_SHR;
}

static inline bool ggml_bitset_get(const ggml_bitset_t *bitset, size_t i) {
  return !!(bitset[i >> BITSET_SHR] & (1u << (i & BITSET_MASK)));
}

static inline void ggml_bitset_set(ggml_bitset_t *bitset, size_t i) {
  bitset[i >> BITSET_SHR] |= (1u << (i & BITSET_MASK));
}

static inline void ggml_bitset_clear(ggml_bitset_t *bitset, size_t i) {
  bitset[i >> BITSET_SHR] &= ~(1u << (i & BITSET_MASK));
}

#define GGML_HASHSET_FULL ((size_t)-1)
#define GGML_HASHSET_ALREADY_EXISTS ((size_t)-2)

struct ggml_hash_set {
  size_t size;
  ggml_bitset_t *used;
  struct ggml_tensor **keys;
};

struct ggml_hash_set ggml_hash_set_new(size_t size);
void ggml_hash_set_free(struct ggml_hash_set *hash_set);
size_t ggml_hash_size(size_t min_sz);
void ggml_hash_set_reset(struct ggml_hash_set *hash_set);
static bool ggml_hash_contains(const struct ggml_hash_set *hash_set,
                               struct ggml_tensor *key);
static size_t ggml_hash_find(const struct ggml_hash_set *hash_set,
                             const struct ggml_tensor *key);
static size_t ggml_hash_insert(struct ggml_hash_set *hash_set,
                               struct ggml_tensor *key);
static size_t ggml_hash_find_or_insert(struct ggml_hash_set *hash_set,
                                       struct ggml_tensor *key);

static inline size_t ggml_hash(const struct ggml_tensor *p) {
  return (size_t)(uintptr_t)p >> 4;
}

static size_t ggml_hash_find(const struct ggml_hash_set *hash_set,
                             const struct ggml_tensor *key) {
  size_t h = ggml_hash(key) % hash_set->size;
  size_t i = h;
  while (ggml_bitset_get(hash_set->used, i) && hash_set->keys[i] != key) {
    i = (i + 1) % hash_set->size;
    if (i == h) {
      return GGML_HASHSET_FULL;
    }
  }
  return i;
}

static bool ggml_hash_contains(const struct ggml_hash_set *hash_set,
                               struct ggml_tensor *key) {
  size_t i = ggml_hash_find(hash_set, key);
  return i != GGML_HASHSET_FULL && ggml_bitset_get(hash_set->used, i);
}

static size_t ggml_hash_insert(struct ggml_hash_set *hash_set,
                               struct ggml_tensor *key) {
  size_t h = ggml_hash(key) % hash_set->size;
  size_t i = h;
  do {
    if (!ggml_bitset_get(hash_set->used, i)) {
      ggml_bitset_set(hash_set->used, i);
      hash_set->keys[i] = key;
      return i;
    }
    if (hash_set->keys[i] == key) {
      return GGML_HASHSET_ALREADY_EXISTS;
    }
    i = (i + 1) % hash_set->size;
  } while (i != h);
  GGML_ABORT("fatal error");
}

static size_t ggml_hash_find_or_insert(struct ggml_hash_set *hash_set,
                                       struct ggml_tensor *key) {
  size_t h = ggml_hash(key) % hash_set->size;
  size_t i = h;
  do {
    if (!ggml_bitset_get(hash_set->used, i)) {
      ggml_bitset_set(hash_set->used, i);
      hash_set->keys[i] = key;
      return i;
    }
    if (hash_set->keys[i] == key) {
      return i;
    }
    i = (i + 1) % hash_set->size;
  } while (i != h);
  GGML_ABORT("fatal error");
}

enum ggml_cgraph_eval_order {
  GGML_CGRAPH_EVAL_ORDER_LEFT_TO_RIGHT = 0,
  GGML_CGRAPH_EVAL_ORDER_RIGHT_TO_LEFT,
  GGML_CGRAPH_EVAL_ORDER_COUNT
};

struct ggml_cgraph {
  int size;
  int n_nodes;
  int n_leafs;
  struct ggml_tensor **nodes;
  struct ggml_tensor **grads;
  struct ggml_tensor **grad_accs;
  struct ggml_tensor **leafs;
  int32_t *use_counts;
  struct ggml_hash_set visited_hash_set;
  enum ggml_cgraph_eval_order order;
};

#ifdef __cplusplus
}
#endif
