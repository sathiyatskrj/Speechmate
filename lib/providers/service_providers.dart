import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/local_llm_service.dart';

// Provides globally accessible, cached instances of core services

final databaseProvider = Provider<DatabaseManager>((ref) {
  return DatabaseManager.instance;
});

/// TtsService — init() is lightweight (synchronous handlers), safe to fire-and-forget
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});

/// NeuralEngineService — singleton, init() loads dictionary from DB.
/// Using the singleton factory constructor ensures only one instance.
final neuralEngineProvider = Provider<NeuralEngineService>((ref) {
  final service = NeuralEngineService();
  // init() is idempotent (checks _isInit internally), safe to fire
  service.init();
  return service;
});

/// LocalLlmService — mock for now, initialize is lightweight
final llmServiceProvider = Provider<LocalLlmService>((ref) {
  final service = LocalLlmService();
  service.initialize();
  return service;
});
