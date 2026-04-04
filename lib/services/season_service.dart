import 'package:flutter/material.dart';
import 'package:speechmate/services/database_manager.dart';

class SeasonService {
  static final SeasonService _instance = SeasonService._internal();
  factory SeasonService() => _instance;
  SeasonService._internal();

  Map<String, dynamic>? _currentSeason;

  Future<void> init() async {
    final db = await DatabaseManager.instance.database;
    final now = DateTime.now();
    final month = now.month;

    // Fetch all versions
    final List<Map<String, dynamic>> configs = await db.query('seasonal_config');
    
    for (var config in configs) {
      int start = config['start_month'];
      int end = config['end_month'];
      
      if (start <= end) {
        if (month >= start && month <= end) {
          _currentSeason = config;
          break;
        }
      } else {
        // Wraps around year end (e.g. Nov to April)
        if (month >= start || month <= end) {
          _currentSeason = config;
          break;
        }
      }
    }
  }

  String get seasonKey => _currentSeason?['season_key'] ?? 'unknown';
  String get seasonName => _currentSeason?['season_key'] == 'cho' ? 'Dry Season (Cho)' : 'Rainy Season (Hwa)';
  Color get themeColor => Color(int.parse(_currentSeason?['theme_color'] ?? '0xFF2196F3'));
  String get featuredWord => _currentSeason?['featured_word'] ?? 'Language';
}
