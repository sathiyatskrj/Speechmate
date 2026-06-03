import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';

class DatabaseManager {
  static final DatabaseManager instance = DatabaseManager._init();
  static Database? _database;
  static Completer<Database>? _initCompleter;

  DatabaseManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Prevent concurrent initialization — second caller waits for the first
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDB('speechmate.db');
      _initCompleter!.complete(_database!);
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _createIndexes,
    );
  }

  // Simple in-memory query cache
  final Map<String, dynamic> _cache = {};
  void clearCache() => _cache.clear();

  /// Create performance indexes on frequently queried columns
  Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_words_category ON words(category_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_words_english ON words(english)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_flashcards_word ON flashcards(word_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_flashcards_review ON flashcards(next_review_date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_phrases_english ON phrases(english)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_dialects_english ON dialects(english)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ga_dict_english ON ga_dictionary(english)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_ga_phrases_english ON ga_phrases(english)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_flora_fauna_category ON flora_fauna(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_kinship_key ON kinship(rel_key)');
      
      // Seed mock Indigenous Knowledge data
      await _seedMockKnowledge(db);
      await _seedKinship(db);
      debugPrint('[DatabaseManager] Indexes created/verified.');
    } catch (e) {
      debugPrint('[DatabaseManager] Index creation failed: $e');
    }
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
     if (oldVersion < 4) {
       debugPrint('[DatabaseManager] Upgraded to v4 (performance indexes).');
     }
     if (oldVersion < 5) {
       const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
       await db.execute('''
       CREATE TABLE ga_dictionary (
         id $idType,
         english TEXT,
         great_andamanese TEXT,
         pos TEXT,
         audio TEXT
       )
       ''');
       await db.execute('''
       CREATE TABLE ga_phrases (
         id $idType,
         english TEXT,
         great_andamanese TEXT,
         audio TEXT
       )
       ''');
       debugPrint('[DatabaseManager] Upgraded to v5 (Great Andamanese tables).');
     }
     if (oldVersion < 6) {
       try {
         await db.execute('ALTER TABLE flashcards ADD COLUMN target_language TEXT DEFAULT \'nicobarese\'');
       } catch (e) { debugPrint("Silent error caught: $e");
         // Column may already exist
       }
       debugPrint('[DatabaseManager] Upgraded to v6 (target_language column).');
     }
     if (oldVersion < 7) {
       const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
       await db.execute('''
       CREATE TABLE flora_fauna (
         id $idType,
         category TEXT,
         native_name TEXT,
         english_name TEXT,
         scientific_name TEXT,
         traditional_use TEXT,
         image_asset TEXT,
         audio_asset TEXT
       )
       ''');
       await db.execute('''
       CREATE TABLE stories (
         id $idType,
         title TEXT,
         storyteller TEXT,
         audio_path TEXT,
         duration_seconds INTEGER,
         timestamp INTEGER
       )
       ''');
       debugPrint('[DatabaseManager] Upgraded to v7 (flora_fauna and stories tables).');
     }
     if (oldVersion < 8) {
       const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
       await db.execute('''
       CREATE TABLE kinship (
         id $idType,
         rel_key TEXT,
         native_term TEXT,
         english_label TEXT,
         description TEXT,
         audio_asset TEXT
       )
       ''');
       debugPrint('[DatabaseManager] Upgraded to v8 (kinship table).');
     }
     if (oldVersion < 9) {
       try {
         await db.execute('ALTER TABLE phrases ADD COLUMN audio_category TEXT DEFAULT \'\'');
         await db.execute('ALTER TABLE phrases ADD COLUMN audio_file TEXT DEFAULT \'\'');
         // Re-seed phrases with audio metadata
         await db.delete('phrases');
       } catch (e) {
         debugPrint('[DatabaseManager] v9 upgrade note: $e');
       }
       debugPrint('[DatabaseManager] Upgraded to v9 (phrases audio columns).');
     }
     if (oldVersion < 10) {
       try {
         await db.execute('''
         CREATE TABLE IF NOT EXISTS pet_milestones (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             event_type TEXT NOT NULL,
             english_term TEXT,
             nicobarese_term TEXT,
             timestamp INTEGER NOT NULL
         )
         ''');
         await db.execute('''
         CREATE TABLE IF NOT EXISTS pet_diary (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             day_count INTEGER NOT NULL,
             entry_text TEXT NOT NULL,
             mood_recorded TEXT NOT NULL,
             timestamp INTEGER NOT NULL
         )
         ''');
         await db.execute('''
         CREATE TABLE IF NOT EXISTS pet_personality_traits (
             playful REAL DEFAULT 0.0,
             studious REAL DEFAULT 0.0,
             musical REAL DEFAULT 0.0,
             adventurous REAL DEFAULT 0.0
         )
         ''');
         await db.execute('''
         CREATE TABLE IF NOT EXISTS pet_social_history (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             peer_name TEXT NOT NULL,
             interaction_type TEXT NOT NULL,
             result TEXT,
             timestamp INTEGER NOT NULL
         )
         ''');
         await db.execute('''
         CREATE TABLE IF NOT EXISTS pet_habitat (
             jungle_unlocked INTEGER DEFAULT 0,
             creatures_unlocked INTEGER DEFAULT 0,
             hut_unlocked INTEGER DEFAULT 0,
             village_unlocked INTEGER DEFAULT 0,
             campfire_level INTEGER DEFAULT 0
         )
         ''');
         
         // Seed initial personality & habitat rows
         final countPers = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pet_personality_traits'));
         if (countPers == null || countPers == 0) {
           await db.insert('pet_personality_traits', {
               'playful': 0.0,
               'studious': 0.0,
               'musical': 0.0,
               'adventurous': 0.0
           });
         }
         final countHab = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pet_habitat'));
         if (countHab == null || countHab == 0) {
           await db.insert('pet_habitat', {
               'jungle_unlocked': 0,
               'creatures_unlocked': 0,
               'hut_unlocked': 0,
               'village_unlocked': 0,
               'campfire_level': 0
           });
         }
       } catch (e) {
         debugPrint('[DatabaseManager] v10 upgrade error: $e');
       }
       debugPrint('[DatabaseManager] Upgraded to v10 (pet subsystem tables).');
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
      next_review_date $intType,
      target_language TEXT DEFAULT 'nicobarese'
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
      text TEXT,
      audio_category TEXT,
      audio_file TEXT
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

    await db.execute('''
    CREATE TABLE ga_dictionary (
      id $idType,
      english TEXT,
      great_andamanese TEXT,
      pos TEXT,
      audio TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE ga_phrases (
      id $idType,
      english TEXT,
      great_andamanese TEXT,
      audio TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE flora_fauna (
      id $idType,
      category TEXT,
      native_name TEXT,
      english_name TEXT,
      scientific_name TEXT,
      traditional_use TEXT,
      image_asset TEXT,
      audio_asset TEXT
    )
    ''');
    
    await db.execute('''
    CREATE TABLE stories (
      id $idType,
      title TEXT,
      storyteller TEXT,
      audio_path TEXT,
      duration_seconds INTEGER,
      timestamp INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE kinship (
      id $idType,
      rel_key TEXT,
      native_term TEXT,
      english_label TEXT,
      description TEXT,
      audio_asset TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE pet_milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        english_term TEXT,
        nicobarese_term TEXT,
        timestamp INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE pet_diary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_count INTEGER NOT NULL,
        entry_text TEXT NOT NULL,
        mood_recorded TEXT NOT NULL,
        timestamp INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE pet_personality_traits (
        playful REAL DEFAULT 0.0,
        studious REAL DEFAULT 0.0,
        musical REAL DEFAULT 0.0,
        adventurous REAL DEFAULT 0.0
    )
    ''');

    await db.execute('''
    CREATE TABLE pet_social_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        peer_name TEXT NOT NULL,
        interaction_type TEXT NOT NULL,
        result TEXT,
        timestamp INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE pet_habitat (
        jungle_unlocked INTEGER DEFAULT 0,
        creatures_unlocked INTEGER DEFAULT 0,
        hut_unlocked INTEGER DEFAULT 0,
        village_unlocked INTEGER DEFAULT 0,
        campfire_level INTEGER DEFAULT 0
    )
    ''');
  }

  static Future<void> _seedKinship(Database db) async {
    final kCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM kinship'));
    if (kCount == null || kCount == 0) {
      Batch batch = db.batch();
      batch.insert('kinship', {'rel_key': 'parent', 'native_term': 'Yom', 'english_label': 'Parent', 'description': 'General term for father or mother.', 'audio_asset': 'assets/audio/yom.mp3'});
      batch.insert('kinship', {'rel_key': 'child', 'native_term': 'Kun', 'english_label': 'Child', 'description': 'The younger generation.', 'audio_asset': 'assets/audio/kun.mp3'});
      batch.insert('kinship', {'rel_key': 'elder_sibling', 'native_term': 'Mem', 'english_label': 'Elder Sibling/Relative', 'description': 'Anyone older in the family group or Tuhet.', 'audio_asset': 'assets/audio/mem.mp3'});
      batch.insert('kinship', {'rel_key': 'younger_sibling', 'native_term': 'Kahem', 'english_label': 'Younger Sibling/Cousin', 'description': 'Anyone younger in the family group.', 'audio_asset': 'assets/audio/kahem.mp3'});
      batch.insert('kinship', {'rel_key': 'spouse', 'native_term': 'Piha', 'english_label': 'Spouse', 'description': 'Marriage partner.', 'audio_asset': 'assets/audio/piha.mp3'});
      await batch.commit(noResult: true);
    }
  }

  static Future<void> _seedMockKnowledge(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM flora_fauna'));
    if (count != null && count > 0) return;

    Batch batch = db.batch();
    batch.insert('flora_fauna', {
      'category': 'Birds',
      'native_name': 'Hiyup',
      'english_name': 'Nicobar Pigeon',
      'scientific_name': 'Caloenas nicobarica',
      'traditional_use': 'Culturally significant to the islands. Known for its iridescent feathers. Often featured in folklore.',
      'image_asset': 'assets/images/nicobar_pigeon.png',
      'audio_asset': 'assets/audio/hiyup.mp3',
    });
    batch.insert('flora_fauna', {
      'category': 'Plants',
      'native_name': 'Hòm',
      'english_name': 'Pandanus',
      'scientific_name': 'Pandanus odoratifer',
      'traditional_use': 'A staple food source. The fruit paste is extracted and preserved. Leaves are woven into mats and baskets.',
      'image_asset': 'assets/images/pandanus.png',
      'audio_asset': 'assets/audio/hom.mp3',
    });
    batch.insert('flora_fauna', {
      'category': 'Marine Life',
      'native_name': 'Kapuh',
      'english_name': 'Dugong',
      'scientific_name': 'Dugong dugon',
      'traditional_use': 'State animal of Andaman and Nicobar. Represents the health of seagrass meadows.',
      'image_asset': 'assets/images/dugong.png',
      'audio_asset': 'assets/audio/kapuh.mp3',
    });
    await batch.commit(noResult: true);
    debugPrint('[DatabaseManager] Seeded mock flora_fauna data.');
  }

  Future<void> seedExtraFromJson(String table, String path, Map<String, dynamic> Function(dynamic) mapper) async {
      final db = await instance.database;
      final res = await db.query(table, limit: 1);
      if (res.isNotEmpty) return;
      
      try {
        final String jsonString = await rootBundle.loadString(path);
        final decoded = json.decode(jsonString);
        // Support watermarked structure: {"_speechmate_metadata": {...}, "entries": [...]}
        final List<dynamic> jsonList = (decoded is Map && decoded.containsKey('entries'))
            ? decoded['entries'] as List<dynamic>
            : decoded as List<dynamic>;
        Batch batch = db.batch();
        for (var item in jsonList) {
          batch.insert(table, mapper(item));
        }
        await batch.commit(noResult: true);
      } catch (e) {
         debugPrint('[DatabaseManager] ⚠ Failed to seed $table from $path: $e');
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

  /// Reverse lookup — search by Nicobarese word to get English translation.
  /// Returns the first match found across all word categories.
  Future<Map<String, dynamic>?> searchByNicobarese(String nicobareseQuery) async {
    final db = await instance.database;
    final q = nicobareseQuery.trim().toLowerCase();
    // Try exact match first
    var results = await db.query('words',
      where: 'LOWER(nicobarese) = ?', whereArgs: [q], limit: 1);
    if (results.isNotEmpty) return results.first;
    // Try LIKE match
    results = await db.query('words',
      where: 'LOWER(nicobarese) LIKE ?', whereArgs: ['%$q%'], limit: 5);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<void> seedCategoryFromJson(String categoryId, String path) async {
      final db = await instance.database;
      // Check if already seeded
      final res = await db.query('words', where: 'category_id = ?', whereArgs: [categoryId], limit: 1);
      if (res.isNotEmpty) return;
      
      try {
        final String jsonString = await rootBundle.loadString(path);
        final decoded = json.decode(jsonString);
        // Support watermarked structure: {"_speechmate_metadata": {...}, "entries": [...]}
        final List<dynamic> jsonList = (decoded is Map && decoded.containsKey('entries'))
            ? decoded['entries'] as List<dynamic>
            : decoded as List<dynamic>;
        
        Batch batch = db.batch();
        for (var item in jsonList) {
          batch.insert('words', {
             'category_id': categoryId,
             'english': item['english'] ?? item['text'] ?? item['name'] ?? '',
             'nicobarese': item['nicobarese'] ?? '',
             'emoji': item['emoji'] ?? '',
             'image': item['image'] ?? '',
             'audio': item['audio'] is Map ? item['audio']['file'] : item['audio'] ?? '',
          });
        }
        await batch.commit(noResult: true);
      } catch (e) {
         debugPrint('[DatabaseManager] ⚠ Failed to seed category $categoryId from $path: $e');
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
             'audio': item['audio'] is Map ? item['audio']['file'] : item['audio'] ?? '',
          });
     }
     await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getWordsByCategory(String categoryId) async {
     final db = await instance.database;
     return await db.query('words', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<void> saveToVault(String english, String nicobarese) async {
    // Treat saving to vault from AR as saving a flashcard for long-term retention
    await saveFlashcard(english, nicobarese);
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
      'target_language': 'nicobarese',
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

  // === SRS Dashboard Statistics ===

  /// Get count of flashcards due for review right now
  Future<int> getDueFlashcardCount() async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE next_review_date <= ?',
      [now],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Get total flashcard count
  Future<int> getTotalFlashcardCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM flashcards');
    return result.first['count'] as int? ?? 0;
  }

  /// Get average ease factor (retention indicator)
  Future<double> getAverageEaseFactor() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT AVG(ease_factor) as avg_ease FROM flashcards');
    return (result.first['avg_ease'] as double?) ?? 2.5;
  }

  /// Get flashcard distribution by repetition count
  Future<Map<String, int>> getFlashcardDistribution() async {
    final db = await instance.database;
    final newCards = await db.rawQuery(
      'SELECT COUNT(*) as c FROM flashcards WHERE repetition = 0',
    );
    final learning = await db.rawQuery(
      'SELECT COUNT(*) as c FROM flashcards WHERE repetition BETWEEN 1 AND 3',
    );
    final mature = await db.rawQuery(
      'SELECT COUNT(*) as c FROM flashcards WHERE repetition > 3',
    );
    return {
      'new': newCards.first['c'] as int? ?? 0,
      'learning': learning.first['c'] as int? ?? 0,
      'mature': mature.first['c'] as int? ?? 0,
    };
  }

  // === Dialect query helpers ===

  /// Get all available dialects for a word
  Future<Map<String, dynamic>?> getDialectsForWord(String english) async {
    final db = await instance.database;
    final results = await db.query(
      'dialects',
      where: 'LOWER(english) = ?',
      whereArgs: [english.trim().toLowerCase()],
      limit: 1,
    );
    if (results.isNotEmpty) return results.first;
    return null;
  }

  /// Get all dialect entries
  Future<List<Map<String, dynamic>>> getAllDialects() async {
    final db = await instance.database;
    return await db.query('dialects', orderBy: 'english ASC');
  }

  // === Great Andamanese helpers ===

  /// Get all GA dictionary entries
  Future<List<Map<String, dynamic>>> getGADictionary() async {
    final db = await instance.database;
    return await db.query('ga_dictionary', orderBy: 'english ASC');
  }

  /// Search GA dictionary
  Future<List<Map<String, dynamic>>> searchGADictionary(String query) async {
    final db = await instance.database;
    final q = '%${query.trim().toLowerCase()}%';
    return await db.query(
      'ga_dictionary',
      where: 'LOWER(english) LIKE ? OR LOWER(great_andamanese) LIKE ?',
      whereArgs: [q, q],
    );
  }

  /// Get GA dictionary filtered by part of speech
  Future<List<Map<String, dynamic>>> getGAByPOS(String pos) async {
    final db = await instance.database;
    return await db.query(
      'ga_dictionary',
      where: 'pos = ?',
      whereArgs: [pos],
      orderBy: 'english ASC',
    );
  }

  /// Get all GA phrases
  Future<List<Map<String, dynamic>>> getGAPhrases() async {
    final db = await instance.database;
    return await db.query('ga_phrases');
  }

  /// Save a Great Andamanese word as a flashcard for SRS
  Future<void> saveGAFlashcard(String english, String greatAndamanese) async {
    final db = await instance.database;
    final wordId = 'ga_${english.toLowerCase().replaceAll(' ', '_')}';

    final result = await db.query('flashcards', where: 'word_id = ?', whereArgs: [wordId]);
    if (result.isNotEmpty) return;

    await db.insert('flashcards', {
      'word_id': wordId,
      'english': english,
      'nicobarese': greatAndamanese, // Stores translation in nicobarese column for backward compat
      'interval': 0,
      'repetition': 0,
      'ease_factor': 2.5,
      'next_review_date': DateTime.now().millisecondsSinceEpoch,
      'target_language': 'great_andamanese',
    });
  }

  // === Pet Subsystem Helpers ===

  Future<void> addPetMilestone(String eventType, String? englishTerm, String? nicobareseTerm) async {
    final db = await instance.database;
    await db.insert('pet_milestones', {
      'event_type': eventType,
      'english_term': englishTerm,
      'nicobarese_term': nicobareseTerm,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPetMilestones() async {
    final db = await instance.database;
    return await db.query('pet_milestones', orderBy: 'timestamp DESC');
  }

  Future<void> addPetDiaryEntry(int dayCount, String entryText, String moodRecorded) async {
    final db = await instance.database;
    await db.insert('pet_diary', {
      'day_count': dayCount,
      'entry_text': entryText,
      'mood_recorded': moodRecorded,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPetDiary() async {
    final db = await instance.database;
    return await db.query('pet_diary', orderBy: 'day_count DESC');
  }

  Future<Map<String, dynamic>> getPetPersonality() async {
    final db = await instance.database;
    final res = await db.query('pet_personality_traits', limit: 1);
    if (res.isNotEmpty) return res.first;
    
    // Fallback seed if empty
    await db.insert('pet_personality_traits', {
      'playful': 0.0,
      'studious': 0.0,
      'musical': 0.0,
      'adventurous': 0.0,
    });
    final retry = await db.query('pet_personality_traits', limit: 1);
    return retry.first;
  }

  Future<void> updatePetPersonality(double playful, double studious, double musical, double adventurous) async {
    final db = await instance.database;
    await db.update('pet_personality_traits', {
      'playful': playful,
      'studious': studious,
      'musical': musical,
      'adventurous': adventurous,
    });
  }

  Future<void> addPetSocialHistory(String peerName, String interactionType, String? result) async {
    final db = await instance.database;
    await db.insert('pet_social_history', {
      'peer_name': peerName,
      'interaction_type': interactionType,
      'result': result,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPetSocialHistory() async {
    final db = await instance.database;
    return await db.query('pet_social_history', orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>> getPetHabitat() async {
    final db = await instance.database;
    final res = await db.query('pet_habitat', limit: 1);
    if (res.isNotEmpty) return res.first;

    // Fallback seed if empty
    await db.insert('pet_habitat', {
      'jungle_unlocked': 0,
      'creatures_unlocked': 0,
      'hut_unlocked': 0,
      'village_unlocked': 0,
      'campfire_level': 0,
    });
    final retry = await db.query('pet_habitat', limit: 1);
    return retry.first;
  }

  Future<void> updatePetHabitat({
    int? jungle,
    int? creatures,
    int? hut,
    int? village,
    int? campfire,
  }) async {
    final db = await instance.database;
    final current = await getPetHabitat();
    await db.update('pet_habitat', {
      'jungle_unlocked': jungle ?? current['jungle_unlocked'],
      'creatures_unlocked': creatures ?? current['creatures_unlocked'],
      'hut_unlocked': hut ?? current['hut_unlocked'],
      'village_unlocked': village ?? current['village_unlocked'],
      'campfire_level': campfire ?? current['campfire_level'],
    });
  }
}

