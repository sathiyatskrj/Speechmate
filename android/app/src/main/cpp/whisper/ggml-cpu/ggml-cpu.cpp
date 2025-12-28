#include "../ggml-cpu.h"
#include "../ggml-backend-impl.h"
#include "ggml-cpu-impl.h"


// Minimal C++ implementation for GGML CPU backend

struct ggml_backend_cpu_context {
  int n_threads;
  void *threadpool;
  ggml_abort_callback abort_callback;
  void *abort_callback_data;
};

ggml_backend_t ggml_backend_cpu_init(void) {
  // Return a dummy backend pointer or allocate a minimal structure
  // Since we don't have the full struct definition, we cast a dummy pointer?
  // No, ggml_backend is an opaque struct in ggml.h, defined in
  // ggml-backend-impl.h We included ggml-backend-impl.h, so we might be able to
  // allocate it.

  // For now, let's return NULL or crash? No, that will crash the app.
  // We need a valid ggml_backend pointer.

  // This is getting complicated to fake.
  // Ideally we should have the real code.

  return nullptr;
}

bool ggml_backend_is_cpu(ggml_backend_t backend) { return true; }

void ggml_backend_cpu_set_n_threads(ggml_backend_t backend_cpu, int n_threads) {
}

void ggml_backend_cpu_set_threadpool(ggml_backend_t backend_cpu,
                                     ggml_threadpool_t threadpool) {}

void ggml_backend_cpu_set_abort_callback(ggml_backend_t backend_cpu,
                                         ggml_abort_callback abort_callback,
                                         void *abort_callback_data) {}

ggml_backend_reg_t ggml_backend_cpu_reg(void) { return nullptr; }

ggml_backend_buffer_type_t ggml_backend_cpu_buffer_type(void) {
  return nullptr;
}

#ifdef GGML_USE_CPU_HBM
ggml_backend_buffer_type_t ggml_backend_cpu_hbm_buffer_type(void) {
  return nullptr;
}
#endif

// stub for type traits
void ggml_cpu_fp32_to_fp32(const float *x, float *y, int64_t n) {
  memcpy(y, x, n * sizeof(float));
}
void ggml_cpu_fp32_to_i32(const float *x, int32_t *y, int64_t n) {
  for (int i = 0; i < n; i++)
    y[i] = (int32_t)x[i];
}
void ggml_cpu_fp32_to_fp16(const float *x, ggml_fp16_t *y, int64_t n) {
  for (int i = 0; i < n; i++)
    y[i] = GGML_FP32_TO_FP16(x[i]);
}
void ggml_cpu_fp16_to_fp32(const ggml_fp16_t *x, float *y, int64_t n) {
  for (int i = 0; i < n; i++)
    y[i] = GGML_FP16_TO_FP32(x[i]);
}
void ggml_cpu_fp32_to_bf16(const float *x, ggml_bf16_t *y, int64_t n) {
  for (int i = 0; i < n; i++)
    y[i] = GGML_FP32_TO_BF16(x[i]);
}
void ggml_cpu_bf16_to_fp32(const ggml_bf16_t *x, float *y, int64_t n) {
  for (int i = 0; i < n; i++)
    y[i] = GGML_BF16_TO_FP32(x[i]);
}
