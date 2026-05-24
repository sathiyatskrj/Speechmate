import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    test('singleton instance returns same object', () {
      final a = AnalyticsService.instance;
      final b = AnalyticsService.instance;
      expect(identical(a, b), isTrue);
    });

    test('trackEvent does not throw without init', () async {
      // Before init, trackEvent should silently no-op
      expect(
        () async => await AnalyticsService.instance.trackEvent('test_event'),
        returnsNormally,
      );
    });

    test('getSessionCount returns 0 without init', () async {
      final count = await AnalyticsService.instance.getSessionCount();
      expect(count, equals(0));
    });

    test('getAverageSessionDuration returns 0 without init', () async {
      final avg = await AnalyticsService.instance.getAverageSessionDuration();
      expect(avg, equals(0.0));
    });

    test('getMostUsedFeatures returns empty list without init', () async {
      final features = await AnalyticsService.instance.getMostUsedFeatures();
      expect(features, isEmpty);
    });

    test('exportAnalyticsJson returns valid JSON', () async {
      final jsonStr = await AnalyticsService.instance.exportAnalyticsJson();
      expect(jsonStr, contains('SpeechMate'));
      expect(jsonStr, contains('total_sessions'));
      expect(jsonStr, contains('data_note'));
    });
  });
}
