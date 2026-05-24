import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/native_library_service.dart';

class P2PSyncService {
  static Future<String> generateDictionaryPayload() async {
    final db = await DatabaseManager.instance.database;
    final allWords = await db.query('words');
    final gaDict = await db.query('ga_dictionary');
    
    // Convert to JSON
    final combinedMap = {
      'words': allWords,
      'ga_dictionary': gaDict,
    };
    final jsonString = jsonEncode(combinedMap);

    // Encrypt sync payload natively using standard offline C++ FFI
    final secureService = NativeLibraryService();
    final String processedPayload = secureService.isAvailable
        ? secureService.encryptSyncPayload(jsonString, 'speechmate_secure_key_2026')
        : jsonString;

    // Create Archive
    final archive = Archive();
    final file = ArchiveFile('dictionary_update.json', processedPayload.length, utf8.encode(processedPayload));
    archive.addFile(file);

    // Encode to ZIP
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    if (zipData == null) {
      throw Exception("Failed to compress dictionary update.");
    }

    // Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/speechmate_update.zip');
    await zipFile.writeAsBytes(zipData);

    return zipFile.path;
  }

  static Future<void> exportAndShare() async {
    try {
       final filePath = await generateDictionaryPayload();
       await Share.shareXFiles([XFile(filePath)], subject: 'SpeechMate Dictionary Update', text: 'Apply this dictionary update via SpeechMate Import tool.');
    } catch (e) {
       debugPrint("Error exporting payload: $e");
    }
  }

  // Schema validation - only allow known columns
  static const Set<String> _allowedWordColumns = {'id', 'category_id', 'english', 'nicobarese', 'emoji', 'image', 'audio'};
  static const Set<String> _allowedGAColumns = {'id', 'english', 'great_andamanese', 'pos', 'audio'};

  static Map<String, dynamic>? _validateRow(Map<String, dynamic> row, Set<String> allowed) {
    // Strip any keys not in the schema
    final sanitized = <String, dynamic>{};
    for (final key in row.keys) {
      if (allowed.contains(key)) {
        sanitized[key] = row[key];
      }
    }
    // Must have at least 'english' to be valid
    if (sanitized['english'] == null || sanitized['english'].toString().isEmpty) return null;
    return sanitized;
  }

  // To be used by Students/Import tool later
  static Future<void> importDictionaryPayload(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw Exception('File not found: $zipPath');
    }
    
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    int importedWords = 0;
    int skippedWords = 0;
    
    for (final archiveFile in archive) {
      if (archiveFile.isFile && archiveFile.name == 'dictionary_update.json') {
        final data = archiveFile.content as List<int>;
        final jsonString = utf8.decode(data);
        
        // Decrypt sync payload natively using C++ FFI
        final secureService = NativeLibraryService();
        final String decryptedPayload = secureService.isAvailable
            ? secureService.decryptSyncPayload(jsonString, 'speechmate_secure_key_2026')
            : jsonString;
            
        final Map<String, dynamic> dataMap = jsonDecode(decryptedPayload);
        
        final db = await DatabaseManager.instance.database;
        final batch = db.batch();
        
        if (dataMap.containsKey('words')) {
           final List<dynamic> wordsList = dataMap['words'];
           for (var item in wordsList) {
              if (item is! Map<String, dynamic>) { skippedWords++; continue; }
              final validated = _validateRow(item, _allowedWordColumns);
              if (validated != null) {
                batch.insert('words', validated, conflictAlgorithm: ConflictAlgorithm.replace);
                importedWords++;
              } else {
                skippedWords++;
              }
           }
        }
        
        if (dataMap.containsKey('ga_dictionary')) {
           final List<dynamic> gaList = dataMap['ga_dictionary'];
           for (var item in gaList) {
              if (item is! Map<String, dynamic>) { skippedWords++; continue; }
              final validated = _validateRow(item, _allowedGAColumns);
              if (validated != null) {
                batch.insert('ga_dictionary', validated, conflictAlgorithm: ConflictAlgorithm.replace);
                importedWords++;
              } else {
                skippedWords++;
              }
           }
        }
        
        await batch.commit(noResult: true);
        debugPrint('[P2PSync] Imported $importedWords entries, skipped $skippedWords invalid.');
      }
    }
  }
}
