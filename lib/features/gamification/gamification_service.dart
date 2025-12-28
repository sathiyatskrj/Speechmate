class GamificationService {
  // Mock data for hackathon demo
  // In a real app, this would be computed from user usage history
  
  static int get currentLevel => 6; // "Word Hunter"
  static int get currentStreak => 12;
  static int get xp => 840;
  static int get nextLevelXp => 1000;
  
  static List<Map<String, dynamic>> get badges => [
    {
      'icon': '🔥',
      'name': 'Streak Fire',
      'desc': '7 Day Streak',
      'obtained': true,
    },
    {
      'icon': '🦁',
      'name': 'Jungle King',
      'desc': 'Mastered Animals',
      'obtained': true,
    },
    {
      'icon': '🧙‍♂️',
      'name': 'Wizard',
      'desc': 'Learned Magic Words',
      'obtained': true,
    },
    {
      'icon': '📢',
      'name': 'Voice Hero',
      'desc': 'Contributed 50 Recordings',
      'obtained': false,
    },
  ];
  
  static String getLevelTitle(int level) {
    const titles = [
      "Novice Explorer",
      "Seed Planter",
      "Word Gatherer",
      "Story Teller",
      "Village Voice",
      "Word Hunter",
      "Culture Keeper",
      "Master Linguist",
      "Legend",
      "Ancestor's Echo"
    ];
    if (level <= 0) return titles[0];
    if (level > titles.length) return titles.last;
    return titles[level - 1];
  }
}
