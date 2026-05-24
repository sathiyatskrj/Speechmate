import 'package:flutter_test/flutter_test.dart';
import 'package:speechmate/screens/student_dash_engines.dart';

void main() {
  group('SmartMissionEngine Tests', () {
    test('Missions are deterministic per day', () {
      final mission1 = SmartMissionEngine.getTodaysMission();
      final mission2 = SmartMissionEngine.getTodaysMission();
      
      expect(mission1['text'], mission2['text']);
      expect(mission1['target'], mission2['target']);
    });
    
    test('Missions contain required keys', () {
      final mission = SmartMissionEngine.getTodaysMission();
      
      expect(mission.containsKey('text'), true);
      expect(mission.containsKey('target'), true);
      expect(mission.containsKey('xp'), true);
      expect(mission.containsKey('category'), true);
      expect(mission.containsKey('emoji'), true);
    });
  });
}
