import 'package:shared_preferences/shared_preferences.dart';

class SearchLocalDataSource {
  const SearchLocalDataSource();

  static const String _recentKeywordsKey = 'search_recent_keywords';
  static const String _popularKeywordsKey = 'search_cached_popular_keywords';
  static const int _maxRecentKeywords = 10;
  static const int _maxPopularKeywords = 5;

  Future<List<String>> fetchRecentKeywords() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_recentKeywordsKey) ?? const [];
    return saved
        .map((keyword) => keyword.trim())
        .where((keyword) => keyword.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> fetchCachedPopularKeywords() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_popularKeywordsKey) ?? const [];
    return saved
        .map((keyword) => keyword.trim())
        .where((keyword) => keyword.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveCachedPopularKeywords(List<String> keywords) async {
    final preferences = await SharedPreferences.getInstance();
    final normalized = <String>[];
    final seen = <String>{};
    for (final raw in keywords) {
      final keyword = raw.trim();
      if (keyword.isEmpty) continue;
      final normalizedKeyword = _normalizeKeyword(keyword);
      if (!seen.add(normalizedKeyword)) continue;
      normalized.add(keyword);
      if (normalized.length >= _maxPopularKeywords) break;
    }
    await preferences.setStringList(_popularKeywordsKey, normalized);
  }

  Future<void> saveRecentKeyword(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getStringList(_recentKeywordsKey) ?? const [];
    final updated = <String>[
      trimmed,
      ...current.where((saved) => !_isSameKeyword(saved, trimmed)),
    ];
    if (updated.length > _maxRecentKeywords) {
      updated.removeRange(_maxRecentKeywords, updated.length);
    }

    await preferences.setStringList(_recentKeywordsKey, updated);
  }

  Future<void> removeRecentKeyword(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getStringList(_recentKeywordsKey) ?? const [];
    final updated = current
        .where((saved) => !_isSameKeyword(saved, trimmed))
        .toList(growable: false);
    await preferences.setStringList(_recentKeywordsKey, updated);
  }

  bool _isSameKeyword(String a, String b) {
    return _normalizeKeyword(a) == _normalizeKeyword(b);
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}
