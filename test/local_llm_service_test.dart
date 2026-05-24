import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/services/local_llm_service.dart';

void main() {
  group('LocalLlmService', () {
    // Note: These tests verify the dictionary-powered fallback logic.
    // They do NOT test GGUF model inference (not yet integrated).

    group('translateSentence', () {
      test('returns null for empty sentence', () async {
        final service = LocalLlmService();
        final result = await service.translateSentence('');
        expect(result, isNull);
      });

      test('returns null for whitespace-only sentence', () async {
        final service = LocalLlmService();
        final result = await service.translateSentence('   ');
        expect(result, isNull);
      });
    });

    group('evaluateSentence', () {
      test('returns invalid for empty sentence', () async {
        final service = LocalLlmService();
        final result = await service.evaluateSentence('');
        expect(result['isValid'], isFalse);
        expect(result['feedback'], contains('enter a sentence'));
      });

      test('returns a map with required keys', () async {
        final service = LocalLlmService();
        final result = await service.evaluateSentence('hello world');
        expect(result.containsKey('isValid'), isTrue);
        expect(result.containsKey('feedback'), isTrue);
      });
    });

    group('generateAdaptivePath', () {
      test('returns 3 suggestions for empty scores', () async {
        final service = LocalLlmService();
        final result = await service.generateAdaptivePath({});
        expect(result.length, equals(3));
      });

      test('prioritizes lowest scores', () async {
        final service = LocalLlmService();
        final result = await service.generateAdaptivePath({
          'animals': 20,
          'nature': 90,
          'numbers': 10,
          'colors': 80,
        });
        expect(result.length, equals(3));
        // Numbers (10) should appear before Nature (90)
        final numbersIndex =
            result.indexWhere((s) => s.toLowerCase().contains('number'));
        final natureIndex =
            result.indexWhere((s) => s.toLowerCase().contains('nature'));
        if (numbersIndex >= 0 && natureIndex >= 0) {
          expect(numbersIndex, lessThan(natureIndex));
        }
      });

      test('includes score percentage for weak categories', () async {
        final service = LocalLlmService();
        final result = await service.generateAdaptivePath({
          'animals': 30,
          'nature': 10,
        });
        // Weak categories (<50%) should include percentage info
        final hasPercentage =
            result.any((s) => s.contains('%') || s.contains('needs work'));
        expect(hasPercentage, isTrue);
      });
    });
  });
}
