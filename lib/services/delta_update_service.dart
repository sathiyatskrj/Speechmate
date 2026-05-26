import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:speechmate/services/database_manager.dart';

// ============================================================================
// DELTA UPDATE SERVICE — Ship new words without a new APK
// Scans for delta JSON files, validates, merges into SQLite
// ============================================================================

class DeltaUpdateService {
  static const String _keyLocalVersion = 'delta_data_version';
  static const String _keyLastDeltaCheck = 'last_delta_check';
  static const String _deltaFolderName = 'speechmate_updates';

  /// Schema validation columns
  static const Set<String> _allowedWordColumns = {
    'id', 'category_id', 'english', 'nicobarese', 'emoji', 'image', 'audio'
  };
  static const Set<String> _allowedGAColumns = {
    'id', 'english', 'great_andamanese', 'pos', 'audio'
  };

  /// Check for and apply any pending delta updates.
  /// Called from main.dart on app launch.
  static Future<DeltaResult> checkAndApplyUpdates() async {
    try {
      final dir = await _getDeltaDirectory();
      if (dir == null || !await dir.exists()) {
        return DeltaResult(applied: 0, message: 'No update directory found.');
      }

      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        return DeltaResult(applied: 0, message: 'No delta files found.');
      }

      int totalApplied = 0;
      int totalSkipped = 0;

      for (final file in files) {
        final result = await _applyDeltaFile(file);
        totalApplied += result.applied;
        totalSkipped += result.skipped;

        // Move processed file to avoid re-processing
        final processedPath = '${file.path}.applied';
        await file.rename(processedPath);
      }

      // Update last check timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastDeltaCheck, DateTime.now().toIso8601String());

      debugPrint('[DeltaUpdate] Applied $totalApplied entries, skipped $totalSkipped.');
      return DeltaResult(
        applied: totalApplied,
        skipped: totalSkipped,
        message: 'Applied $totalApplied new entries.',
      );
    } catch (e) {
      debugPrint('[DeltaUpdate] Error: $e');
      return DeltaResult(applied: 0, message: 'Error: $e');
    }
  }

  /// Apply a single delta JSON file
  static Future<DeltaResult> _applyDeltaFile(File file) async {
    final jsonString = await file.readAsString();
    final Map<String, dynamic> delta = jsonDecode(jsonString);

    // Validate delta format
    final version = delta['version'] as String?;
    if (version == null) {
      return DeltaResult(applied: 0, message: 'Invalid delta: missing version.');
    }

    final db = await DatabaseManager.instance.database;
    final batch = db.batch();
    int applied = 0;
    int skipped = 0;

    // Process added words
    if (delta.containsKey('added')) {
      final List<dynamic> added = delta['added'];
      for (final item in added) {
        if (item is! Map<String, dynamic>) { skipped++; continue; }
        final validated = _validateRow(item, _allowedWordColumns);
        if (validated != null) {
          batch.insert('words', validated, conflictAlgorithm: ConflictAlgorithm.replace);
          applied++;
        } else {
          skipped++;
        }
      }
    }

    // Process modified words
    if (delta.containsKey('modified')) {
      final List<dynamic> modified = delta['modified'];
      for (final item in modified) {
        if (item is! Map<String, dynamic>) { skipped++; continue; }
        final validated = _validateRow(item, _allowedWordColumns);
        if (validated != null) {
          batch.insert('words', validated, conflictAlgorithm: ConflictAlgorithm.replace);
          applied++;
        } else {
          skipped++;
        }
      }
    }

    // Process deleted words (by English key)
    if (delta.containsKey('deleted')) {
      final List<dynamic> deleted = delta['deleted'];
      for (final item in deleted) {
        if (item is String) {
          batch.delete('words', where: 'english = ?', whereArgs: [item]);
          applied++;
        }
      }
    }

    // Process GA dictionary updates
    if (delta.containsKey('ga_added')) {
      final List<dynamic> gaAdded = delta['ga_added'];
      for (final item in gaAdded) {
        if (item is! Map<String, dynamic>) { skipped++; continue; }
        final validated = _validateRow(item, _allowedGAColumns);
        if (validated != null) {
          batch.insert('ga_dictionary', validated, conflictAlgorithm: ConflictAlgorithm.replace);
          applied++;
        } else {
          skipped++;
        }
      }
    }

    await batch.commit(noResult: true);

    // Update local version
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocalVersion, version);

    return DeltaResult(applied: applied, skipped: skipped);
  }

  /// Validate a row against allowed columns
  static Map<String, dynamic>? _validateRow(
      Map<String, dynamic> row, Set<String> allowed) {
    final sanitized = <String, dynamic>{};
    for (final key in row.keys) {
      if (allowed.contains(key)) {
        sanitized[key] = row[key];
      }
    }
    if (sanitized['english'] == null ||
        sanitized['english'].toString().isEmpty) {
      return null;
    }
    return sanitized;
  }

  /// Generate a delta JSON from current DB (for teacher export)
  /// Exports all words added since [sinceVersion]
  static Future<String> generateDelta({String? sinceVersion}) async {
    final db = await DatabaseManager.instance.database;
    final allWords = await db.query('words');
    final gaDict = await db.query('ga_dictionary');

    final prefs = await SharedPreferences.getInstance();
    final currentVersion = prefs.getString(_keyLocalVersion) ?? '1.4.9';

    // Increment version
    final parts = currentVersion.split('.');
    final patch = int.tryParse(parts.last) ?? 0;
    parts[parts.length - 1] = '${patch + 1}';
    final newVersion = parts.join('.');

    final delta = {
      'version': newVersion,
      'generated': DateTime.now().toIso8601String(),
      'added': allWords,
      'ga_added': gaDict,
    };

    return jsonEncode(delta);
  }

  /// Export delta to a file in the updates directory
  static Future<String> exportDeltaFile() async {
    final deltaJson = await generateDelta();
    final dir = await getApplicationDocumentsDirectory();
    final updateDir = Directory('${dir.path}/$_deltaFolderName');
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${updateDir.path}/delta_$timestamp.json');
    await file.writeAsString(deltaJson);
    return file.path;
  }

  /// Get the delta updates directory
  static Future<Directory?> _getDeltaDirectory() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      return Directory('${docDir.path}/$_deltaFolderName');
    } catch (e) {
      debugPrint('[DeltaUpdate] Cannot get delta directory: $e');
      return null;
    }
  }

  /// Get current local data version
  static Future<String> getLocalVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocalVersion) ?? '1.4.9';
  }
}

/// Result of a delta update operation
class DeltaResult {
  final int applied;
  final int skipped;
  final String message;

  DeltaResult({this.applied = 0, this.skipped = 0, this.message = ''});
}
