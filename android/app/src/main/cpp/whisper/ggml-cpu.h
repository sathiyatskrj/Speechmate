#pragma once

#include "ggml.h"

#ifdef __cplusplus
extern "C" {
#endif

GGML_API ggml_backend_t ggml_backend_cpu_init(void);

GGML_API bool ggml_backend_is_cpu(ggml_backend_t backend);
GGML_API void ggml_backend_cpu_set_n_threads(ggml_backend_t backend_cpu,
                                             int n_threads);
GGML_API void
ggml_backend_cpu_set_abort_callback(ggml_backend_t backend_cpu,
                                    ggml_abort_callback abort_callback,
                                    void *abort_callback_data);

GGML_API ggml_backend_buffer_type_t ggml_backend_cpu_buffer_type(void);

#ifdef GGML_USE_CPU_HBM
GGML_API ggml_backend_buffer_type_t ggml_backend_cpu_hbm_buffer_type(void);
#endif

GGML_API ggml_backend_reg_t ggml_backend_cpu_reg(void);

#ifdef __cplusplus
}
#endif
