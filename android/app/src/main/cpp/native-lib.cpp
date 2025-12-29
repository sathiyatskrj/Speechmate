#include "whisper/whisper.h"
#include <jni.h>
#include <string>
#include <vector>

// ... (imports)

extern "C" JNIEXPORT jstring JNICALL
Java_com_speechmate_speechmate_MainActivity_transcribe(JNIEnv *env, jobject,
                                                       jstring modelPath,
                                                       jstring audioPath) {

  const char *model = env->GetStringUTFChars(modelPath, 0);
  const char *audio = env->GetStringUTFChars(audioPath, 0);

  // FIX 5: Correct Whisper init
  struct whisper_context_params cparams = whisper_context_default_params();
  cparams.use_gpu = false;

  struct whisper_context *ctx =
      whisper_init_from_file_with_params(model, cparams);

  if (ctx == nullptr) {
    env->ReleaseStringUTFChars(modelPath, model);
    env->ReleaseStringUTFChars(audioPath, audio);
    return env->NewStringUTF("Error: Failed to initialize whisper context");
  }

  FILE *f = fopen(audio, "rb");
  if (!f) {
    whisper_free(ctx);
    env->ReleaseStringUTFChars(modelPath, model);
    env->ReleaseStringUTFChars(audioPath, audio);
    return env->NewStringUTF("Error: Audio file not found");
  }

  fseek(f, 0, SEEK_END);
  long fsize = ftell(f);
  fseek(f, 0, SEEK_SET);

  // Simple WAV header check can also check for 44 bytes typically
  if (fsize < 44) {
    fclose(f);
    whisper_free(ctx);
    env->ReleaseStringUTFChars(modelPath, model);
    env->ReleaseStringUTFChars(audioPath, audio);
    return env->NewStringUTF("Error: Invalid WAV file (too small)");
  }

  fseek(f, 44, SEEK_SET); // Skip WAV header

  int num_samples = (fsize - 44) / 2; // 16-bit mono -> 2 bytes per sample
  std::vector<float> pcmf32(num_samples);
  std::vector<int16_t> pcm16(num_samples);

  fread(pcm16.data(), sizeof(int16_t), num_samples, f);
  fclose(f);

  // FIX 3: C++ PCM -> FLOAT CONVERSION
  for (int i = 0; i < num_samples; i++) {
    pcmf32[i] = static_cast<float>(pcm16[i]) / 32768.0f;
  }

  // FIX 4: Silence detection
  float energy = 0.0f;
  for (int i = 0; i < pcmf32.size(); i++) {
    energy += fabs(pcmf32[i]);
  }
  if (pcmf32.size() > 0) {
    energy /= pcmf32.size();
  }

  if (energy < 0.002f) {
    whisper_free(ctx);
    env->ReleaseStringUTFChars(modelPath, model);
    env->ReleaseStringUTFChars(audioPath, audio);
    // Return specific tag to let Dart know logic should proceed but no speech
    // found Or just empty string? User said: "Silence detected – skipping"
    // User's fix 2 says "cleanText.isEmpty ? I heard silence"
    return env->NewStringUTF("");
  }

  // Release JNI strings immediately
  env->ReleaseStringUTFChars(modelPath, model);
  env->ReleaseStringUTFChars(audioPath, audio);

  // FIX 7: Proper params for tiny.en
  whisper_full_params params =
      whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

  params.language = "en";
  params.translate = false;
  params.print_progress = false;
  params.print_realtime = false;
  params.print_special = false;
  params.no_context = true;
  params.single_segment = true;

  // FIX 6: RUN WHISPER IN BACKGROUND THREAD?
  // Since we are calling this whole function via `compute` (background isolate)
  // in Dart, we can block here safely without freezing the UI thread. This
  // satisfies the user's intent to "Prevent hangs".

  int ret = whisper_full(ctx, params, pcmf32.data(), pcmf32.size());
  if (ret != 0) {
    whisper_free(ctx);
    return env->NewStringUTF("Error: Whisper failed to process");
  }

  std::string text = "";
  int n = whisper_full_n_segments(ctx);
  for (int i = 0; i < n; i++) {
    const char *segment = whisper_full_get_segment_text(ctx, i);
    if (segment) {
      text += segment;
    }
  }

  whisper_free(ctx);

  return env->NewStringUTF(text.c_str());
}
