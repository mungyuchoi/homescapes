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

  Future<List<String>> fetchPopularKeywords({int limit = 5}) async {
    return _fetchFromKeywordsCollection(limit: limit);
  }

  Future<void> increasePopularKeywordCount(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

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

  String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}
