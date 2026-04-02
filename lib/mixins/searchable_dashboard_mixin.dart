import 'package:flutter/material.dart';
import 'package:speechmate/services/dictionary_service.dart';
import 'package:speechmate/services/neural_engine_service.dart';

/// A mixin that provides shared dictionary search + neural engine fallback logic
/// for both Student and Teacher dashboards - eliminating duplication.
mixin SearchableDashboardMixin<T extends StatefulWidget> on State<T> {
  final DictionaryService dashSearchDictService = DictionaryService();
  final NeuralEngineService dashSearchNeuralEngine = NeuralEngineService();

  Map<String, dynamic>? searchResult;
  bool searchedNicobarese = false;
  bool isSearchLoading = false;
  bool hasSearched = false;

  Future<void> initSearch() async {
    await dashSearchDictService.loadDictionary(DictionaryType.words);
    await dashSearchDictService.loadDictionary(DictionaryType.phrases);
  }

  Future<void> performMixinSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => isSearchLoading = true);

    // 1. Direct Search (Exact/Fuzzy from Dictionary)
    var found = await dashSearchDictService.searchEverywhere(query);

    // 2. Neural Engine Fallback
    if (found == null) {
      final neuralResult = await dashSearchNeuralEngine.predict(query);
      if (neuralResult.text.isNotEmpty) {
        found = {
          'english': query,
          'nicobarese': neuralResult.text,
          '_isGenerated': true,
          '_confidence': neuralResult.confidence,
        };
      }
    }

    if (mounted) {
      setState(() {
        searchResult = found;
        hasSearched = true;

        if (found != null) {
          if (found.containsKey('_searchedNicobarese')) {
            searchedNicobarese = found['_searchedNicobarese'];
          } else if (found.containsKey('_isGenerated')) {
            searchedNicobarese = false;
          } else {
            final q = query.trim().toLowerCase();
            searchedNicobarese =
                found['nicobarese'].toString().toLowerCase() == q;
          }
        } else {
          searchedNicobarese = false;
        }
        isSearchLoading = false;
      });
    }
  }

  void clearMixinSearch(TextEditingController controller) {
    setState(() {
      controller.clear();
      searchResult = null;
      hasSearched = false;
      searchedNicobarese = false;
    });
  }

  void disposeMixinSearch() {
    dashSearchDictService.unload(DictionaryType.words);
  }
}
