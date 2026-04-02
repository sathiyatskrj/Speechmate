#include "whisper/whisper.h"
#include <string>
#include <vector>
#include <cstring>
#include <cstdlib>
#include <cmath>

extern "C" __attribute__((visibility("default"))) const char *
transcribe_ffi(const char *model, const char *audio) {

  struct whisper_context_params cparams = whisper_context_default_params();
  cparams.use_gpu = false;

  struct whisper_context *ctx = whisper_init_from_file_with_params(model, cparams);

  if (ctx == nullptr) {
    return strdup("Error: Failed to initialize whisper context");
  }

  FILE *f = fopen(audio, "rb");
  if (!f) {
    whisper_free(ctx);
    return strdup("Error: Audio file not found");
  }

  fseek(f, 0, SEEK_END);
  long fsize = ftell(f);
  fseek(f, 0, SEEK_SET);

  if (fsize < 44) {
    fclose(f);
    whisper_free(ctx);
    return strdup("Error: Invalid WAV file (too small)");
  }

  fseek(f, 44, SEEK_SET); // Skip WAV header

  int num_samples = (fsize - 44) / 2; // 16-bit mono -> 2 bytes per sample
  std::vector<float> pcmf32(num_samples);
  std::vector<int16_t> pcm16(num_samples);

  fread(pcm16.data(), sizeof(int16_t), num_samples, f);
  fclose(f);

  for (int i = 0; i < num_samples; i++) {
    pcmf32[i] = static_cast<float>(pcm16[i]) / 32768.0f;
  }

  float energy = 0.0f;
  for (int i = 0; i < pcmf32.size(); i++) {
    energy += std::fabs(pcmf32[i]);
  }
  if (pcmf32.size() > 0) {
    energy /= pcmf32.size();
  }

  if (energy < 0.002f) {
    whisper_free(ctx);
    return strdup("");
  }

  whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

  params.language = "en";
  params.translate = false;
  params.print_progress = false;
  params.print_realtime = false;
  params.print_special = false;
  params.no_context = true;
  params.single_segment = true;

  int ret = whisper_full(ctx, params, pcmf32.data(), pcmf32.size());
  if (ret != 0) {
    whisper_free(ctx);
    return strdup("Error: Whisper failed to process");
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

  return strdup(text.c_str());
}

extern "C" __attribute__((visibility("default"))) void free_ffi_string(char *str) {
  if (str) {
    free(str);
  }
}
