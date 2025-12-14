import 'dart:convert';
import 'package:flutter/services.dart';

class DictionaryService {
  List<dynamic> _dictionary = [];

  Future<void> load() async {
    final String response =
    await rootBundle.loadString('assets/data/dictionary.json');
    _dictionary = json.decode(response);
  }

  Map<String, dynamic>? search(String query) {
    query = query.trim().toLowerCase();

    return _dictionary.firstWhere(
          (entry) => entry['english'].toLowerCase() == query,
      orElse: () => null,
    );
  }
}
