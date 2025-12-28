#include "../ggml-cpu.h"
#include "ggml-cpu-impl.h"


// Minimal implementation of GGML CPU backend for Android build fix

void ggml_cpu_init(void) {
  // No-op
}

int ggml_cpu_has_sse3(void) { return 0; }
int ggml_cpu_has_ssse3(void) { return 0; }
int ggml_cpu_has_avx(void) { return 0; }
int ggml_cpu_has_avx_vnni(void) { return 0; }
int ggml_cpu_has_avx2(void) { return 0; }
int ggml_cpu_has_bmi2(void) { return 0; }
int ggml_cpu_has_f16c(void) { return 0; }
int ggml_cpu_has_fma(void) { return 0; }
int ggml_cpu_has_avx512(void) { return 0; }
int ggml_cpu_has_avx512_vbmi(void) { return 0; }
int ggml_cpu_has_avx512_vnni(void) { return 0; }
int ggml_cpu_has_avx512_bf16(void) { return 0; }
int ggml_cpu_has_amx_int8(void) { return 0; }

int ggml_cpu_has_neon(void) { return 1; } // Assuming ARM64 for Android
int ggml_cpu_has_arm_fma(void) { return 1; }
int ggml_cpu_has_fp16_va(void) { return 1; }
int ggml_cpu_has_dotprod(void) { return 1; }
int ggml_cpu_has_matmul_int8(void) { return 1; }
int ggml_cpu_has_sve(void) { return 0; }
int ggml_cpu_get_sve_cnt(void) { return 0; }
int ggml_cpu_has_sme(void) { return 0; }
int ggml_cpu_has_riscv_v(void) { return 0; }
int ggml_cpu_get_rvv_vlen(void) { return 0; }
int ggml_cpu_has_vsx(void) { return 0; }
int ggml_cpu_has_vxe(void) { return 0; }
int ggml_cpu_has_wasm_simd(void) { return 0; }
int ggml_cpu_has_llamafile(void) { return 0; }

void ggml_numa_init(enum ggml_numa_strategy numa) { (void)numa; }
bool ggml_is_numa(void) { return false; }

struct ggml_tensor *ggml_new_i32(struct ggml_context *ctx, int32_t value) {
  return ggml_new_tensor_1d(ctx, GGML_TYPE_I32, 1);
}

struct ggml_tensor *ggml_new_f32(struct ggml_context *ctx, float value) {
  return ggml_new_tensor_1d(ctx, GGML_TYPE_F32, 1);
}

struct ggml_tensor *ggml_set_i32(struct ggml_tensor *tensor, int32_t value) {
  *(int32_t *)tensor->data = value;
  return tensor;
}

struct ggml_tensor *ggml_set_f32(struct ggml_tensor *tensor, float value) {
  *(float *)tensor->data = value;
  return tensor;
}

int32_t ggml_get_i32_1d(const struct ggml_tensor *tensor, int i) {
  return ((int32_t *)tensor->data)[i];
}

void ggml_set_i32_1d(const struct ggml_tensor *tensor, int i, int32_t value) {
  ((int32_t *)tensor->data)[i] = value;
}

int32_t ggml_get_i32_nd(const struct ggml_tensor *tensor, int i0, int i1,
                        int i2, int i3) {
  // Simplify for stub
  return 0;
}

void ggml_set_i32_nd(const struct ggml_tensor *tensor, int i0, int i1, int i2,
                     int i3, int32_t value) {}

float ggml_get_f32_1d(const struct ggml_tensor *tensor, int i) {
  return ((float *)tensor->data)[i];
}

void ggml_set_f32_1d(const struct ggml_tensor *tensor, int i, float value) {
  ((float *)tensor->data)[i] = value;
}

float ggml_get_f32_nd(const struct ggml_tensor *tensor, int i0, int i1, int i2,
                      int i3) {
  return 0.0f;
}

void ggml_set_f32_nd(const struct ggml_tensor *tensor, int i0, int i1, int i2,
                     int i3, float value) {}

struct ggml_threadpool *
ggml_threadpool_new(struct ggml_threadpool_params *params) {
  return NULL;
}
void ggml_threadpool_free(struct ggml_threadpool *threadpool) {}
int ggml_threadpool_get_n_threads(struct ggml_threadpool *threadpool) {
  return 1;
}
void ggml_threadpool_pause(struct ggml_threadpool *threadpool) {}
void ggml_threadpool_resume(struct ggml_threadpool *threadpool) {}

struct ggml_cplan ggml_graph_plan(const struct ggml_cgraph *cgraph,
                                  int n_threads,
                                  struct ggml_threadpool *threadpool) {
  struct ggml_cplan plan;
  memset(&plan, 0, sizeof(plan));
  plan.work_size = 1024; // Dummy size
  return plan;
}

enum ggml_status ggml_graph_compute(struct ggml_cgraph *cgraph,
                                    struct ggml_cplan *cplan) {
  return GGML_STATUS_SUCCESS;
}

enum ggml_status ggml_graph_compute_with_ctx(struct ggml_context *ctx,
                                             struct ggml_cgraph *cgraph,
                                             int n_threads) {
  return GGML_STATUS_SUCCESS;
}

const struct ggml_type_traits_cpu *
ggml_get_type_traits_cpu(enum ggml_type type) {
  return NULL;
}
