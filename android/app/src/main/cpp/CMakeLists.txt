cmake_minimum_required(VERSION 3.18.1)

project(speechmate_whisper)


# Add include directories for new structure
include_directories(
    .
    whisper
    whisper/ggml-cpu
)

add_library(whisper-lib SHARED
    native-lib.cpp
    whisper/whisper.cpp
    whisper/ggml.c
    whisper/ggml-alloc.c
    whisper/ggml-backend.cpp
    whisper/ggml-quants.c
    whisper/ggml-cpu/ggml-cpu.c
    whisper/ggml-cpu/ggml-cpu.cpp
    whisper/ggml-cpu/ggml-cpu-aarch64.cpp
    whisper/ggml-cpu/ggml-cpu-hbm.cpp
)

find_library(log-lib log)

target_link_libraries(whisper-lib ${log-lib})

