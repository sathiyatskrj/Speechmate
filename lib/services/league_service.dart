import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// LEAGUE SERVICE — Duolingo-style Weekly XP Tournaments
// Bronze → Silver → Gold → Diamond → Legendary
// ============================================================================

enum LeagueTier { bronze, silver, gold, diamond, legendary }

class LeagueService {
  static final LeagueService _instance = LeagueService._internal();
  factory LeagueService() => _instance;
  LeagueService._internal();

  static const String _keyLeagueTier = 'league_tier';
  static const String _keyLeagueWeekXP = 'league_week_xp';
  static const String _keyLeagueWeekStart = 'league_week_start';
  static const String _keyLeagueMembers = 'league_members';
  static const String _keyLeagueHistory = 'league_history';

  static const List<Map<String, dynamic>> tiers = [
    {'name': 'Bronze', 'emoji': '🥉', 'color': 0xFFCD7F32, 'minXP': 0},
    {'name': 'Silver', 'emoji': '🥈', 'color': 0xFFC0C0C0, 'minXP': 100},
    {'name': 'Gold', 'emoji': '🥇', 'color': 0xFFFFD700, 'minXP': 300},
    {'name': 'Diamond', 'emoji': '💎', 'color': 0xFF00BFFF, 'minXP': 600},
    {'name': 'Legendary', 'emoji': '👑', 'color': 0xFFFF4500, 'minXP': 1000},
  ];

  /// Get current league tier index
  Future<int> getCurrentTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLeagueTier) ?? 0; // Default: Bronze
  }

  /// Get XP earned this week
  Future<int> getWeekXP() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkWeekReset(prefs);
    return prefs.getInt(_keyLeagueWeekXP) ?? 0;
  }

  /// Add XP for this week
  Future<void> addWeekXP(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await _checkWeekReset(prefs);
    final current = prefs.getInt(_keyLeagueWeekXP) ?? 0;
    await prefs.setInt(_keyLeagueWeekXP, current + amount);
  }

  /// Get time remaining until weekly reset (next Monday midnight)
  Duration getTimeUntilReset() {
    final now = DateTime.now();
    // Find next Monday at midnight
    int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    if (daysUntilMonday == 0 && now.hour >= 0) daysUntilMonday = 7;
    final nextMonday = DateTime(now.year, now.month, now.day + daysUntilMonday);
    return nextMonday.difference(now);
  }

  /// Get league members (simulated competitors + self)
  Future<List<Map<String, dynamic>>> getLeagueMembers() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkWeekReset(prefs);

    final raw = prefs.getString(_keyLeagueMembers);
    if (raw != null) {
      try {
        final List<dynamic> parsed = jsonDecode(raw);
        return parsed.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    // Generate fresh simulated competitors
    final members = _generateSimulatedMembers();
    await prefs.setString(_keyLeagueMembers, jsonEncode(members));
    return members;
  }

  /// Check if the week has rolled over and process promotion/demotion
  Future<void> _checkWeekReset(SharedPreferences prefs) async {
    final weekStartStr = prefs.getString(_keyLeagueWeekStart);
    final now = DateTime.now();

    if (weekStartStr != null) {
      final weekStart = DateTime.parse(weekStartStr);
      if (now.difference(weekStart).inDays < 7) return; // Still in current week

      // Week is over — evaluate promotion/demotion
      await _evaluateWeekEnd(prefs);
    }

    // Start new week
    final mondayOfThisWeek = now.subtract(Duration(days: (now.weekday - 1) % 7));
    final weekStart = DateTime(mondayOfThisWeek.year, mondayOfThisWeek.month, mondayOfThisWeek.day);
    await prefs.setString(_keyLeagueWeekStart, weekStart.toIso8601String());
    await prefs.setInt(_keyLeagueWeekXP, 0);
    await prefs.remove(_keyLeagueMembers); // Fresh competitors next week
  }

  /// Evaluate end of week: promote top 3, demote bottom 3
  Future<void> _evaluateWeekEnd(SharedPreferences prefs) async {
    final members = await getLeagueMembers();
    final myXP = prefs.getInt(_keyLeagueWeekXP) ?? 0;

    // Update "You" entry with actual XP
    for (final m in members) {
      if (m['isPlayer'] == true) {
        m['weekXP'] = myXP;
      }
    }

    // Sort by XP descending
    members.sort((a, b) => (b['weekXP'] as int).compareTo(a['weekXP'] as int));

    // Find player rank
    int playerRank = members.indexWhere((m) => m['isPlayer'] == true);
    int currentTier = prefs.getInt(_keyLeagueTier) ?? 0;

    if (playerRank < 3 && currentTier < tiers.length - 1) {
      // Promoted!
      await prefs.setInt(_keyLeagueTier, currentTier + 1);
      debugPrint('[League] 🎉 Promoted to ${tiers[currentTier + 1]['name']}!');
    } else if (playerRank >= members.length - 3 && currentTier > 0) {
      // Demoted
      await prefs.setInt(_keyLeagueTier, currentTier - 1);
      debugPrint('[League] 📉 Demoted to ${tiers[currentTier - 1]['name']}.');
    }
  }

  /// Generate 8 simulated competitors with randomized XP
  List<Map<String, dynamic>> _generateSimulatedMembers() {
    final rng = Random();
    final names = [
      {'name': 'Asha K.', 'avatar': '🌺'},
      {'name': 'Ravi M.', 'avatar': '🐬'},
      {'name': 'Priya S.', 'avatar': '🦋'},
      {'name': 'Ajay T.', 'avatar': '🐢'},
      {'name': 'Meena R.', 'avatar': '🌴'},
      {'name': 'Kiran D.', 'avatar': '🐠'},
      {'name': 'Lakshmi V.', 'avatar': '🌸'},
      {'name': 'Suresh N.', 'avatar': '🦜'},
    ];

    final members = names.map((n) {
      return {
        'name': n['name'],
        'avatar': n['avatar'],
        'weekXP': rng.nextInt(200) + 20,
        'isPlayer': false,
      };
    }).toList();

    // Add the real player
    members.add({
      'name': 'You',
      'avatar': '⭐',
      'weekXP': 0, // Will be updated with real XP
      'isPlayer': true,
    });

    return members;
  }

  /// Get tier info by index
  static Map<String, dynamic> getTierInfo(int index) {
    return tiers[index.clamp(0, tiers.length - 1)];
  }
}
