import 'package:cloud_firestore/cloud_firestore.dart';

class SearchFirestoreDataSource {
  SearchFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _keywordsCollection {
    return _firestore
        .collection('meta')
        .doc('popular_search')
        .collection('keywords');
  }

  DocumentReference<Map<String, dynamic>> get _popularSearchDoc {
    return _firestore.collection('meta').doc('popular_search');
  }

  Future<List<String>> fetchPopularKeywords({int limit = 5}) async {
    final fromLegacyDoc = await _fetchFromLegacyPopularSearchDoc(limit: limit);
    if (fromLegacyDoc.isNotEmpty) {
      return fromLegacyDoc;
    }
    return _fetchFromKeywordsCollection(limit: limit);
  }

  Future<void> increasePopularKeywordCount(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    await _increaseCountInPopularSearchDoc(trimmed);
    await _increaseCountInKeywordsCollection(trimmed);
  }

  Future<List<String>> _fetchFromKeywordsCollection({
    required int limit,
  }) async {
    try {
      final snapshot = await _keywordsCollection
          .orderBy('count', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => _string(doc.data()['keyword']))
          .where((keyword) => keyword.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _fetchFromLegacyPopularSearchDoc({
    required int limit,
  }) async {
    try {
      final snapshot = await _popularSearchDoc.get();
      final data = snapshot.data();
      if (data == null || data.isEmpty) {
        return const [];
      }

      final entries = <_KeywordCount>[];
      final keywordsMap = data['keywords'];
      if (keywordsMap is Map) {
        _collectCountEntries(source: keywordsMap, destination: entries);
      }
      if (entries.isEmpty) {
        _collectCountEntries(source: data, destination: entries);
      }
      if (entries.isEmpty) {
        return const [];
      }

      entries.sort((a, b) {
        final byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return a.keyword.compareTo(b.keyword);
      });

      return entries
          .take(limit)
          .map((entry) => entry.keyword)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _increaseCountInPopularSearchDoc(String keyword) async {
    final normalizedKeyword = _normalizeKeyword(keyword);
    final docRef = _popularSearchDoc;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final rawKeywords = data['keywords'];
      final keywordsMap = _toStringDynamicMap(rawKeywords);
      final rawEntry = keywordsMap[normalizedKeyword];

      int nextCount = 1;
      if (rawEntry is Map) {
        nextCount = _int(rawEntry['count']) + 1;
      } else if (rawEntry != null) {
        nextCount = _int(rawEntry) + 1;
      }

      keywordsMap[normalizedKeyword] = <String, dynamic>{
        'keyword': keyword,
        'count': nextCount,
      };

      transaction.set(docRef, <String, dynamic>{
        'keywords': keywordsMap,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _increaseCountInKeywordsCollection(String keyword) async {
    final normalizedKeyword = _normalizeKeyword(keyword);
    final keywordDoc = _keywordsCollection.doc(normalizedKeyword);
    await keywordDoc.set(<String, dynamic>{
      'keyword': keyword,
      'normalizedKeyword': normalizedKeyword,
      'count': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _collectCountEntries({
    required Map source,
    required List<_KeywordCount> destination,
  }) {
    source.forEach((rawKey, rawValue) {
      final fallbackKeyword = _string(rawKey);
      if (fallbackKeyword.isEmpty) return;

      if (rawValue is Map) {
        final keyword = _string(rawValue['keyword']).isNotEmpty
            ? _string(rawValue['keyword'])
            : fallbackKeyword;
        final count = _int(rawValue['count']);
        if (count <= 0 || keyword.isEmpty) return;
        destination.add(_KeywordCount(keyword: keyword, count: count));
        return;
      }

      final count = _int(rawValue);
      if (count <= 0) return;
      destination.add(_KeywordCount(keyword: fallbackKeyword, count: count));
    });
  }

  Map<String, dynamic> _toStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return {...value};
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return <String, dynamic>{};
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(_string(value)) ?? 0;
  }

  String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}

class _KeywordCount {
  const _KeywordCount({required this.keyword, required this.count});

  final String keyword;
  final int count;
}
