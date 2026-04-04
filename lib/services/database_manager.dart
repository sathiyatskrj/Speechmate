import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class DatabaseManager {
  static final DatabaseManager instance = DatabaseManager._init();
  static Database? _database;

  DatabaseManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('speechmate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
     if (oldVersion < 2) {
       const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
       const textType = 'TEXT NOT NULL';
       await db.execute('''
        CREATE TABLE words (
          id $idType,
          category_id $textType,
          english $textType,
          nicobarese $textType,
          emoji TEXT,
          image TEXT,
          audio TEXT
        )
        ''');
     }
     if (oldVersion < 3) {
       const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
       await db.execute('''
       CREATE TABLE phrases (
         id $idType,
         english TEXT,
         nicobarese TEXT,
         text TEXT
       )
       ''');
       await db.execute('''
       CREATE TABLE dialects (
         id $idType,
         english TEXT,
         car TEXT,
         central TEXT,
         coast TEXT,
         teressa TEXT,
         chowra TEXT
       )
       ''');
     }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE flashcards (
      id $idType,
      word_id $textType,
      english $textType,
      nicobarese $textType,
      interval $intType,
      repetition $intType,
      ease_factor $numType,
      next_review_date $intType
    )
    ''');
    
    await db.execute('''
    CREATE TABLE words (
      id $idType,
      category_id $textType,
      english $textType,
      nicobarese $textType,
      emoji TEXT,
      image TEXT,
      audio TEXT
    )
    ''');
    
    await db.execute('''
    CREATE TABLE phrases (
      id $idType,
      english TEXT,
      nicobarese TEXT,
      text TEXT
    )
    ''');
    
    await db.execute('''
    CREATE TABLE dialects (
      id $idType,
      english TEXT,
      car TEXT,
      central TEXT,
      coast TEXT,
      teressa TEXT,
      chowra TEXT
    )
    ''');
  }

  Future<void> seedExtraFromJson(String table, String path, Map<String, dynamic> Function(dynamic) mapper) async {
      final db = await instance.database;
      final res = await db.query(table, limit: 1);
      if (res.isNotEmpty) return;
      
      try {
        final String jsonString = await rootBundle.loadString(path);
        final List<dynamic> jsonList = json.decode(jsonString);
        Batch batch = db.batch();
        for (var item in jsonList) {
          batch.insert(table, mapper(item));
        }
        await batch.commit(noResult: true);
      } catch (e) {
         // Fail silently
      }
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<Map<String, dynamic>?> searchExact(String query, String table, List<String> columns) async {
    final db = await instance.database;
    final qCol = columns.map((c) => 'LOWER($c) = ?').join(' OR ');
    final q = query.trim().toLowerCase();
    final List<String> args = List.generate(columns.length, (_) => q);

    final results = await db.query(table, where: qCol, whereArgs: args, limit: 1);
    if (results.isNotEmpty) return results.first;
    return null;
  }
  
  Future<List<Map<String, dynamic>>> searchLike(String query, String table, List<String> columns) async {
    final db = await instance.database;
    final qCol = columns.map((c) => 'LOWER($c) LIKE ?').join(' OR ');
    final q = '%${query.trim().toLowerCase()}%';
    final List<String> args = List.generate(columns.length, (_) => q);

    return await db.query(table, where: qCol, whereArgs: args);
  }

  Future<void> seedCategoryFromJson(String categoryId, String path) async {
      final db = await instance.database;
      // Check if already seeded
      final res = await db.query('words', where: 'category_id = ?', whereArgs: [categoryId], limit: 1);
      if (res.isNotEmpty) return;
      
      try {
        final String jsonString = await rootBundle.loadString(path);
        final List<dynamic> jsonList = json.decode(jsonString);
        
        Batch batch = db.batch();
        for (var item in jsonList) {
          batch.insert('words', {
             'category_id': categoryId,
             'english': item['english'] ?? item['text'] ?? item['name'] ?? '',
             'nicobarese': item['nicobarese'] ?? '',
             'emoji': item['emoji'] ?? '',
             'image': item['image'] ?? '',
             'audio': item['audio']?['file'] ?? item['audio'] ?? '',
          });
        }
        await batch.commit(noResult: true);
      } catch (e) {
         // Fail silently if JSON missing
      }
  }
  
  Future<void> seedCategoryFromList(String categoryId, List<Map<String,dynamic>> items) async {
     final db = await instance.database;
     final res = await db.query('words', where: 'category_id = ?', whereArgs: [categoryId], limit: 1);
     if (res.isNotEmpty) return;
     
     Batch batch = db.batch();
     for (var item in items) {
          batch.insert('words', {
             'category_id': categoryId,
             'english': item['name'] ?? item['english'] ?? item['text'] ?? '',
             'nicobarese': item['nicobarese'] ?? '',
             'emoji': item['emoji'] ?? '',
             'image': item['image'] ?? '',
             'audio': item['audio']?['file'] ?? item['audio'] ?? '',
          });
     }
     await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getWordsByCategory(String categoryId) async {
     final db = await instance.database;
     return await db.query('words', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<void> saveFlashcard(String english, String nicobarese) async {
    final db = await instance.database;
    final wordId = english.toLowerCase().replaceAll(' ', '_');
    
    // Check if exists
    final result = await db.query('flashcards', where: 'word_id = ?', whereArgs: [wordId]);
    if (result.isNotEmpty) return; // Already a flashcard

    // Insert new card using SM-2 defaults
    await db.insert('flashcards', {
      'word_id': wordId,
      'english': english,
      'nicobarese': nicobarese,
      'interval': 0,
      'repetition': 0,
      'ease_factor': 2.5,
      'next_review_date': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getDueFlashcards() async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.query('flashcards', where: 'next_review_date <= ?', whereArgs: [now]);
  }

  Future<void> updateFlashcard(String wordId, int interval, int repetition, double easeFactor, int nextReviewDate) async {
    final db = await instance.database;
    await db.update(
      'flashcards',
      {
        'interval': interval,
        'repetition': repetition,
        'ease_factor': easeFactor,
        'next_review_date': nextReviewDate,
      },
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }
}
