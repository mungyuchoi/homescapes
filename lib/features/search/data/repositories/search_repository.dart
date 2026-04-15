import 'package:homescapes/features/search/data/models/search_models.dart';
import 'package:homescapes/features/spot/data/repositories/spot_repository.dart';

import '../datasources/search_firestore_data_source.dart';
import '../datasources/search_local_data_source.dart';
import '../datasources/search_seed_data_source.dart';

abstract class SearchRepository {
  Future<SearchData> fetchCachedSearchData();

  Future<SearchData> fetchSearchData();

  Future<List<String>> searchByKeyword({required String query});

  Future<void> trackSearchKeyword({required String keyword});

  Future<void> removeRecentKeyword({required String keyword});
}

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl({
    SearchSeedDataSource? seedDataSource,
    SearchFirestoreDataSource? firestoreDataSource,
    SearchLocalDataSource? localDataSource,
    SpotRepository? spotRepository,
  }) : _seedDataSource = seedDataSource ?? const SearchSeedDataSource(),
       _firestoreDataSource =
           firestoreDataSource ?? SearchFirestoreDataSource(),
       _localDataSource = localDataSource ?? const SearchLocalDataSource(),
       _spotRepository = spotRepository ?? const SpotRepositoryImpl();

  final SearchSeedDataSource _seedDataSource;
  final SearchFirestoreDataSource _firestoreDataSource;
  final SearchLocalDataSource _localDataSource;
  final SpotRepository _spotRepository;

  static SearchData? _sharedCachedSearchData;
  static List<String>? _sharedCachedSpotTitles;

  SearchData? _cachedSearchData = _sharedCachedSearchData;
  List<String>? _cachedSpotTitles = _sharedCachedSpotTitles;

  @override
  Future<SearchData> fetchCachedSearchData() async {
    final cached = _cachedSearchData;
    if (cached != null) {
      return cached;
    }

    final recentKeywords = await _localDataSource.fetchRecentKeywords();
    final cachedPopularKeywords = await _localDataSource
        .fetchCachedPopularKeywords();
    final seedData = await _seedDataSource.fetchSearchData();
    final resolvedPopularKeywords = _resolvePopularKeywords(
      remote: cachedPopularKeywords,
      fallback: seedData.popularKeywords,
      limit: 5,
    );

    final resolved = SearchData(
      popularKeywords: resolvedPopularKeywords,
      recentKeywords: recentKeywords,
    );
    _setCachedSearchData(resolved);
    return resolved;
  }

  @override
  Future<SearchData> fetchSearchData() async {
    final seedData = await _seedDataSource.fetchSearchData();
    final popularKeywords = await _firestoreDataSource.fetchPopularKeywords(
      limit: 5,
    );
    final recentKeywords = await _localDataSource.fetchRecentKeywords();
    final resolvedPopularKeywords = _resolvePopularKeywords(
      remote: popularKeywords,
      fallback: seedData.popularKeywords,
      limit: 5,
    );

    final resolved = SearchData(
      popularKeywords: resolvedPopularKeywords,
      recentKeywords: recentKeywords,
    );
    _setCachedSearchData(resolved);
    try {
      await _localDataSource.saveCachedPopularKeywords(resolvedPopularKeywords);
    } catch (_) {
      // 인기 검색어 로컬 캐시 실패는 검색 로딩 흐름을 막지 않는다.
    }
    return resolved;
  }

  @override
  Future<List<String>> searchByKeyword({required String query}) async {
    final data = _cachedSearchData ?? await fetchCachedSearchData();
    final spotTitles = await _fetchSpotTitles();
    final normalizedQuery = query.trim().toLowerCase();
    final all = _deduplicateKeywords([
      ...spotTitles,
      ...data.popularKeywords,
      ...data.recentKeywords,
    ]);

    if (normalizedQuery.isEmpty) {
      return all;
    }

    final matched = all
        .where((keyword) => keyword.toLowerCase().contains(normalizedQuery))
        .toList();
    matched.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      final aStartsWith = aLower.startsWith(normalizedQuery);
      final bStartsWith = bLower.startsWith(normalizedQuery);
      if (aStartsWith != bStartsWith) {
        return aStartsWith ? -1 : 1;
      }
      return aLower.compareTo(bLower);
    });
    return matched;
  }

  @override
  Future<void> trackSearchKeyword({required String keyword}) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return;
    await _localDataSource.saveRecentKeyword(trimmedKeyword);
    await _firestoreDataSource.increasePopularKeywordCount(trimmedKeyword);

    final cached = _cachedSearchData;
    if (cached != null) {
      _setCachedSearchData(
        SearchData(
          popularKeywords: cached.popularKeywords,
          recentKeywords: _prependRecentKeyword(
            current: cached.recentKeywords,
            keyword: trimmedKeyword,
          ),
        ),
      );
    }
  }

  @override
  Future<void> removeRecentKeyword({required String keyword}) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return;

    await _localDataSource.removeRecentKeyword(trimmedKeyword);

    final cached = _cachedSearchData;
    if (cached != null) {
      _setCachedSearchData(
        SearchData(
          popularKeywords: cached.popularKeywords,
          recentKeywords: cached.recentKeywords
              .where(
                (item) =>
                    _normalizeKeyword(item) != _normalizeKeyword(trimmedKeyword),
              )
              .toList(growable: false),
        ),
      );
    }
  }

  Future<List<String>> _fetchSpotTitles() async {
    if (_cachedSpotTitles != null) {
      return _cachedSpotTitles!;
    }

    try {
      final spots = await _spotRepository.fetchSpotsCollection();
      final titles = <String>[];
      final seen = <String>{};
      for (final spot in spots.values) {
        final title = spot.title.trim();
        if (title.isEmpty) continue;
        final normalized = _normalizeKeyword(title);
        if (!seen.add(normalized)) continue;
        titles.add(title);
      }
      _setCachedSpotTitles(titles);
      return titles;
    } catch (_) {
      return const [];
    }
  }

  List<String> _deduplicateKeywords(List<String> keywords) {
    final deduplicated = <String>[];
    final seen = <String>{};
    for (final raw in keywords) {
      final keyword = raw.trim();
      if (keyword.isEmpty) continue;
      final normalized = _normalizeKeyword(keyword);
      if (!seen.add(normalized)) continue;
      deduplicated.add(keyword);
    }
    return deduplicated;
  }

  List<String> _resolvePopularKeywords({
    required List<String> remote,
    required List<String> fallback,
    required int limit,
  }) {
    final merged = _deduplicateKeywords([...remote, ...fallback]);
    if (merged.length <= limit) {
      return merged;
    }
    return merged.take(limit).toList(growable: false);
  }

  List<String> _prependRecentKeyword({
    required List<String> current,
    required String keyword,
  }) {
    final updated = <String>[
      keyword,
      ...current.where(
        (item) => _normalizeKeyword(item) != _normalizeKeyword(keyword),
      ),
    ];
    if (updated.length > 10) {
      updated.removeRange(10, updated.length);
    }
    return updated;
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  void _setCachedSearchData(SearchData data) {
    _cachedSearchData = data;
    _sharedCachedSearchData = data;
  }

  void _setCachedSpotTitles(List<String> titles) {
    _cachedSpotTitles = titles;
    _sharedCachedSpotTitles = titles;
  }
}
