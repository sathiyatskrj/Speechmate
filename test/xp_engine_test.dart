import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/screens/student_dash.dart';

void main() {
  group('StudentXPEngine Gamification Tests', () {
    test('Level calculations are correct at boundaries', () {
      final info1 = StudentXPEngine.getLevelInfo(0);
      expect(info1['level'], 0);
      expect(info1['name'], 'Seedling');
      expect(info1['progress'], 0.0);

      final info2 = StudentXPEngine.getLevelInfo(50);
      expect(info2['level'], 1);
      expect(info2['name'], 'Sprout');
      expect(info2['progress'], 0.0);
      
      final info3 = StudentXPEngine.getLevelInfo(100);
      expect(info3['level'], 1);
      expect(info3['name'], 'Sprout');
      expect(info3['progress'], 0.5); // 50 XP into level 1, which needs 100 XP more to reach 150
    });

    test('XP rewards scale with streak multiplier', () {
      final baseReward = StudentXPEngine.calculateReward(action: 'complete_game', streakDays: 0);
      expect(baseReward, 50);

      final streakReward = StudentXPEngine.calculateReward(action: 'complete_game', streakDays: 10);
      expect(streakReward, 75); // 50 * (1 + 10 * 0.05) = 50 * 1.5 = 75

      // Cap at 2x
      final maxStreakReward = StudentXPEngine.calculateReward(action: 'complete_game', streakDays: 30);
      expect(maxStreakReward, 100); // 50 * 2.0 = 100
    });
  });
}
