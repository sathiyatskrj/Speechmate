import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/screens/student_dash_engines.dart';

void main() {
  group('StudentXPEngine', () {
    test('level 0 for 0 XP', () {
      final info = StudentXPEngine.getLevelInfo(0);
      expect(info['level'], equals(0));
      expect(info['name'], equals('Seedling'));
      expect(info['emoji'], equals('🌱'));
    });

    test('level 1 for 50 XP', () {
      final info = StudentXPEngine.getLevelInfo(50);
      expect(info['level'], equals(1));
      expect(info['name'], equals('Sprout'));
    });

    test('level 10 for 12000+ XP', () {
      final info = StudentXPEngine.getLevelInfo(15000);
      expect(info['level'], equals(10));
      expect(info['name'], equals('Elder'));
    });

    test('progress is between 0 and 1', () {
      final info = StudentXPEngine.getLevelInfo(100);
      expect(info['progress'], greaterThanOrEqualTo(0.0));
      expect(info['progress'], lessThanOrEqualTo(1.0));
    });

    test('xpForNext is positive', () {
      final info = StudentXPEngine.getLevelInfo(25);
      expect(info['xpForNext'], greaterThan(0));
    });
  });

  group('StudentXPEngine.calculateReward', () {
    test('translate_word gives 10 base XP', () {
      final xp = StudentXPEngine.calculateReward(action: 'translate_word');
      expect(xp, equals(10));
    });

    test('daily_mission gives 100 base XP', () {
      final xp = StudentXPEngine.calculateReward(action: 'daily_mission');
      expect(xp, equals(100));
    });

    test('streak multiplier increases reward', () {
      final base = StudentXPEngine.calculateReward(action: 'translate_word', streakDays: 0);
      final streaked = StudentXPEngine.calculateReward(action: 'translate_word', streakDays: 10);
      expect(streaked, greaterThan(base));
    });

    test('streak multiplier caps at 2x', () {
      final capped = StudentXPEngine.calculateReward(action: 'translate_word', streakDays: 100);
      // 10 base * 2.0 max multiplier = 20
      expect(capped, equals(20));
    });

    test('unknown action gives 5 base XP', () {
      final xp = StudentXPEngine.calculateReward(action: 'unknown_action');
      expect(xp, equals(5));
    });
  });

  group('SmartMissionEngine', () {
    test('getTodaysMission returns a valid mission', () {
      final mission = SmartMissionEngine.getTodaysMission();
      expect(mission.containsKey('target'), isTrue);
      expect(mission.containsKey('xp'), isTrue);
      expect(mission.containsKey('category'), isTrue);
      expect(mission['target'], isA<int>());
      expect(mission['xp'], isA<int>());
    });

    test('getTodaysMission is deterministic within same day', () {
      final mission1 = SmartMissionEngine.getTodaysMission();
      final mission2 = SmartMissionEngine.getTodaysMission();
      expect(mission1['category'], equals(mission2['category']));
      expect(mission1['target'], equals(mission2['target']));
    });

    test('getCategoryStaleness returns 10 categories', () {
      final staleness = SmartMissionEngine.getCategoryStaleness();
      expect(staleness.length, equals(10));
      for (final value in staleness.values) {
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      }
    });
  });
}
