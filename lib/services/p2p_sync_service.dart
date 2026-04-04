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
    final gaDict = await db.query('ga_dictionary');
    
    // Convert to JSON
    final combinedMap = {
      'words': allWords,
      'ga_dictionary': gaDict,
    };
    final jsonString = jsonEncode(combinedMap);

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
        final Map<String, dynamic> dataMap = jsonDecode(jsonString);
        
        final db = await DatabaseManager.instance.database;
        final batch = db.batch();
        
        if (dataMap.containsKey('words')) {
           final List<dynamic> wordsList = dataMap['words'];
           for (var item in wordsList) {
              batch.insert('words', item, conflictAlgorithm: ConflictAlgorithm.replace);
           }
        }
        
        if (dataMap.containsKey('ga_dictionary')) {
           final List<dynamic> gaList = dataMap['ga_dictionary'];
           for (var item in gaList) {
              batch.insert('ga_dictionary', item, conflictAlgorithm: ConflictAlgorithm.replace);
           }
        }
        
        await batch.commit(noResult: true);
      }
    }
  }
}
