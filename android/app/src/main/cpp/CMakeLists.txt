cmake_minimum_required(VERSION 3.18.1)

project(speechmate_whisper)

add_library(whisper-lib SHARED
    native-lib.cpp
    whisper/whisper.cpp
    whisper/ggml.c
    whisper/ggml-alloc.c
    whisper/ggml-backend.c
    whisper/ggml-quants.c
)

find_library(log-lib log)

target_link_libraries(whisper-lib ${log-lib})
