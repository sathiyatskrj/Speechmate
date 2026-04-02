import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/services/dictionary_service.dart';

void main() {
  group('DictionaryService Tests', () {
    late DictionaryService service;

    setUp(() {
      service = DictionaryService();
    });

    test('searchWord should handle empty query', () async {
      final result = await service.searchWord('');
      // Without DB, this returns null or empty depending on loadDictionary
      expect(result, null);
    });

    test('translateSentence should return null for empty input', () async {
      final result = await service.translateSentence('   ');
      expect(result, isNull);
    });
  });
}
