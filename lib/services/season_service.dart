import 'package:flutter/material.dart';

class SeasonService {
  Color _themeColor = Colors.cyan; // Default theme color

  Color get themeColor => _themeColor;

  Future<void> init() async {
    // Basic initialization for now
    _themeColor = Colors.cyan;
  }
}
