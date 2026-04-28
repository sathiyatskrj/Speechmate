import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:translator/translator.dart';

class RegionalTranslationService {
  OnDeviceTranslator? _translatorToEng;
  OnDeviceTranslator? _translatorFromEng;
  final _modelManager = OnDeviceTranslatorModelManager();
  TranslateLanguage? _currentSource;
  final _onlineTranslator = GoogleTranslator();

  /// Initializes the ML Kit Translator for bidirectional regional language translation
  Future<bool> initialize(TranslateLanguage? source) async {
    try {
      if (source == null) return true; // Online fallback mode only

      if (_currentSource == source && _translatorToEng != null) return true;

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

      _translatorToEng?.close();
      _translatorToEng = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: TranslateLanguage.english,
      );

      _translatorFromEng?.close();
      _translatorFromEng = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: source,
      );
      
      return true;
    } catch (e) {
      debugPrint("[Regional] Translator init failed: $e");
      return false;
    }
  }

  /// Translates regional text to English text offline or via online fallback
  Future<String> translateToEnglish(String text, {String? fallbackLangCode}) async {
    if (_translatorToEng != null) {
      try {
        return await _translatorToEng!.translateText(text);
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

  /// Translates English text to regional text offline or via online fallback
  Future<String> translateFromEnglish(String text, {String? fallbackLangCode}) async {
    if (_translatorFromEng != null) {
      try {
        return await _translatorFromEng!.translateText(text);
      } catch (e) {
        debugPrint("[Regional] Translation error: $e");
      }
    }

    if (fallbackLangCode != null) {
      try {
        debugPrint("[Regional] Using online fallback for English -> $fallbackLangCode...");
        final translation = await _onlineTranslator.translate(text, from: 'en', to: fallbackLangCode);
        return translation.text;
      } catch (e) {
        debugPrint("[Regional] Online translation error: $e");
      }
    }
    return text;
  }

  void dispose() {
    _translatorToEng?.close();
    _translatorFromEng?.close();
  }
}
