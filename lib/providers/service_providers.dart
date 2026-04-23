import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speechmate/services/neural_engine_service.dart';
import 'package:speechmate/services/tts_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/local_llm_service.dart';

// Provides globally accessible, cached instances of core services

final databaseProvider = Provider<DatabaseManager>((ref) {
  return DatabaseManager.instance;
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  service.init();
  return service;
});

final neuralEngineProvider = Provider<NeuralEngineService>((ref) {
  final service = NeuralEngineService();
  service.init();
  return service;
});

final llmServiceProvider = Provider<LocalLlmService>((ref) {
  final service = LocalLlmService();
  service.initialize();
  return service;
});
