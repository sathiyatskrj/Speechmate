import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:speechmate/services/database_manager.dart';

class P2PSyncService {
  static Future<String> generateDictionaryPayload() async {
    final db = await DatabaseManager.instance.database;
    final allWords = await db.query('words');
    
    // Convert to JSON
    final jsonString = jsonEncode(allWords);

    // Create Archive
    final archive = Archive();
    final file = ArchiveFile('dictionary_update.json', jsonString.length, utf8.encode(jsonString));
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

  // To be used by Students/Import tool later
  static Future<void> importDictionaryPayload(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    for (final file in archive) {
      if (file.isFile && file.name == 'dictionary_update.json') {
        final data = file.content as List<int>;
        final jsonString = utf8.decode(data);
        final List<dynamic> wordsList = jsonDecode(jsonString);
        
        final db = await DatabaseManager.instance.database;
        final batch = db.batch();
        for (var item in wordsList) {
           // Basic upsert logic could go here based on word id/english
           // For now, simulating import
           batch.insert('words', item, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }
    }
  }
}
