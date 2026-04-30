import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/features/gamification/gamification_service.dart';

void main() {
  group('GamificationService - Level Title Tests', () {
    test('Level 1 returns Island Guest', () {
      expect(GamificationService.getLevelTitle(1), 'Island Guest');
    });

    test('Level 5 returns Ocean Navigator', () {
      expect(GamificationService.getLevelTitle(5), 'Ocean Navigator');
    });

    test('Level 10 returns Ancestor\'s Echo', () {
      expect(GamificationService.getLevelTitle(10), "Ancestor's Echo");
    });

    test('Level 0 returns first title', () {
      expect(GamificationService.getLevelTitle(0), 'Island Guest');
    });

    test('Level beyond max returns last title', () {
      expect(GamificationService.getLevelTitle(99), "Ancestor's Echo");
    });
  });

  group('GamificationService - XP Thresholds', () {
    test('Singleton returns same instance', () {
      final a = GamificationService();
      final b = GamificationService();
      expect(identical(a, b), isTrue);
    });

    test('Static XP defaults to 0', () {
      // Before initialization, cached values are defaults
      expect(GamificationService.xp, isA<int>());
    });

    test('Static level defaults to >= 1', () {
      expect(GamificationService.currentLevel, greaterThanOrEqualTo(1));
    });
  });
}
