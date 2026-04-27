import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:translator/translator.dart';

class RegionalTranslationService {
  OnDeviceTranslator? _translator;
  final _modelManager = OnDeviceTranslatorModelManager();
  TranslateLanguage? _currentSource;
  final _onlineTranslator = GoogleTranslator();

  /// Initializes the ML Kit Translator for a specific regional language
  Future<bool> initialize(TranslateLanguage? source) async {
    try {
      if (source == null) return true; // Online fallback mode only

      if (_currentSource == source && _translator != null) return true;

      _currentSource = source;
      
      // Ensure English target is available
      final bool isEnDownloaded = await _modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode);
      if (!isEnDownloaded) {
        debugPrint("[Regional] Downloading English model...");
        await _modelManager.downloadModel(TranslateLanguage.english.bcpCode);
      }

      // Ensure source is available
      final bool isSourceDownloaded = await _modelManager.isModelDownloaded(source.bcpCode);
      if (!isSourceDownloaded) {
        debugPrint("[Regional] Downloading ${source.name} model...");
        await _modelManager.downloadModel(source.bcpCode);
      }

      _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: TranslateLanguage.english,
      );
      
      return true;
    } catch (e) {
      debugPrint("[Regional] Translator init failed: $e");
      return false;
    }
  }

  /// Translates regional text to English text offline or via online fallback
  Future<String> translateToEnglish(String text, {String? fallbackLangCode}) async {
    if (_translator != null) {
      try {
        return await _translator!.translateText(text);
      } catch (e) {
        debugPrint("[Regional] Translation error: $e");
      }
    }

    if (fallbackLangCode != null) {
      try {
        debugPrint("[Regional] Using online fallback for $fallbackLangCode...");
        final translation = await _onlineTranslator.translate(text, from: fallbackLangCode, to: 'en');
        return translation.text;
      } catch (e) {
        debugPrint("[Regional] Online translation error: $e");
      }
    }

    return text; // Return original text on complete failure
  }

  void dispose() {
    _translator?.close();
  }
}
