#include <jni.h>
#include <string>
#include <vector>
#include "whisper/whisper.h"

extern "C"
JNIEXPORT jstring JNICALL
Java_com_speechmate_speechmate_MainActivity_transcribe(
        JNIEnv *env,
        jobject,
        jstring modelPath,
        jstring audioPath) {

    const char *model = env->GetStringUTFChars(modelPath, 0);
    const char *audio = env->GetStringUTFChars(audioPath, 0);

    struct whisper_context_params cparams = whisper_context_default_params();
    struct whisper_context *ctx = whisper_init_from_file_with_params(model, cparams);

    if (ctx == nullptr) {
        return env->NewStringUTF("Error: Failed to initialize whisper context");
    }

    // Load WAV file - simplified for hackathon
    // In a real app, use a proper WAV parser or pass raw PCM from Flutter
    // For this hackathon, we assume the 'audio' path is a valid WAV file 16kHz
    
    // We need a helper to load WAV to float array. 
    // Since we don't have dr_wav here easily without copying more files, 
    // we will rely on whisper.cpp's internal helper if available or a simple manual header skip.
    // ACTUAL WHISPER.CPP implementation usually requires a callback or pre-loaded PCM.
    
    // FAST TRACK FOR HACKATHON:
    // We will use a simplified approach: just return a dummy string if file not found,
    // but honestly we need to read the WAV.
    // Let's assume we can read the file as raw PCM floats (skipping 44 byte header).

    FILE *f = fopen(audio, "rb");
    if (!f) {
        return env->NewStringUTF("Error: Audio file not found");
    }

    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 44, SEEK_SET); // Skip WAV header

    int num_samples = (fsize - 44) / 2; // 16-bit mono
    std::vector<float> pcmf32(num_samples);
    std::vector<int16_t> pcm16(num_samples);

    fread(pcm16.data(), sizeof(int16_t), num_samples, f);
    fclose(f);

    for (int i = 0; i < num_samples; i++) {
        pcmf32[i] = static_cast<float>(pcm16[i]) / 32768.0f;
    }

    whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.print_progress = false;

    if (whisper_full(ctx, params, pcmf32.data(), pcmf32.size()) != 0) {
        whisper_free(ctx);
        return env->NewStringUTF("Error: Whisper failed to process");
    }

    std::string text;
    int n = whisper_full_n_segments(ctx);
    for (int i = 0; i < n; i++) {
        text += whisper_full_get_segment_text(ctx, i);
    }

    whisper_free(ctx);

    return env->NewStringUTF(text.c_str());
}
