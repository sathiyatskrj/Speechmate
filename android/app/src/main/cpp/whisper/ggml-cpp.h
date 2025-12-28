#pragma once

#include "ggml-backend.h"
#include "ggml.h"


#include <map>
#include <memory>
#include <string>
#include <vector>


// Smart pointers for GGML C types
using ggml_backend_ptr =
    std::unique_ptr<ggml_backend, void (*)(ggml_backend_t)>;
using ggml_backend_buffer_ptr =
    std::unique_ptr<ggml_backend_buffer, void (*)(ggml_backend_buffer_t)>;
using ggml_context_ptr =
    std::unique_ptr<ggml_context, void (*)(ggml_context *)>;
using ggml_threadpool_ptr =
    std::unique_ptr<ggml_threadpool, void (*)(ggml_threadpool *)>;
using ggml_gallocr_ptr =
    std::unique_ptr<ggml_gallocr, void (*)(ggml_gallocr_t)>;

// Define WHISPER_VERSION if not handled elsewhere (it was referenced in the
// error log)
#ifndef WHISPER_VERSION
#define WHISPER_VERSION "1.7.1"
#endif
