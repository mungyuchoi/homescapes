import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/app_models.dart';

class CommunityFirestoreDataSource {
  CommunityFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _baseQuery() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(100);
  }

  Future<List<CommunityPost>> fetchPosts({DateTime? now}) async {
    return fetchPostsFromServer(now: now);
  }

  Future<List<CommunityPost>> fetchPostsFromCache({DateTime? now}) async {
    final baseNow = now ?? DateTime.now();
    try {
      final snapshot = await _baseQuery().get(
        const GetOptions(source: Source.cache),
      );
      return _parseSnapshot(snapshot, baseNow);
    } catch (_) {
      return const [];
    }
  }

  Future<List<CommunityPost>> fetchPostsFromServer({DateTime? now}) async {
    final baseNow = now ?? DateTime.now();
    final snapshot = await _baseQuery().get(
      const GetOptions(source: Source.serverAndCache),
    );
    return _parseSnapshot(snapshot, baseNow);
  }

  Future<CommunityPost?> fetchPostById(String postId, {DateTime? now}) async {
    final baseNow = now ?? DateTime.now();
    final snapshot = await _firestore
        .collection('posts')
        .doc(postId)
        .get(const GetOptions(source: Source.serverAndCache));
    final data = snapshot.data();
    if (data == null) return null;
    return _parsePost(postId: snapshot.id, data: data, now: baseNow);
  }

  List<CommunityPost> _parseSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    DateTime now,
  ) {
    final parsed = <CommunityPost>[];
    for (final doc in snapshot.docs) {
      final post = _parsePost(postId: doc.id, data: doc.data(), now: now);
      if (post != null) parsed.add(post);
    }
    return parsed;
  }

  CommunityPost? _parsePost({
    required String postId,
    required Map<String, dynamic> data,
    required DateTime now,
  }) {
    if ((data['isDeleted'] as bool?) == true) return null;
    if ((data['isHidden'] as bool?) == true) return null;

    final authorMap = _map(data['author']);
    final displayName = _string(authorMap['displayName']).isNotEmpty
        ? _string(authorMap['displayName'])
        : '익명';
    final authorUid = _string(authorMap['uid']);
    final authorPhotoUrl = _string(authorMap['photoURL']).isNotEmpty
        ? _string(authorMap['photoURL'])
        : _string(authorMap['photoUrl']);

    final tags = _stringList(data['tags']);
    final category = _string(data['category']).isNotEmpty
        ? _string(data['category'])
        : (tags.isNotEmpty ? tags.first : '자유');

    final contentText = _string(data['contentText']);
    final contentHtml = _string(data['contentHtml']);
    final resolvedContent = contentText.isNotEmpty
        ? contentText
        : _stripHtml(contentHtml);
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final imageUrls = _stringList(data['images']);

    final spotId = _string(data['spotId']);
    final facility = _string(data['spotName']).isNotEmpty
        ? _string(data['spotName'])
        : (_string(data['facility']).isNotEmpty
              ? _string(data['facility'])
              : '커뮤니티');

    return CommunityPost(
      postId: postId,
      uid: authorUid,
      author: displayName,
      photoURL: authorPhotoUrl,
      timeAgo: _toRelativeTime(createdAt, now),
      category: category,
      content: resolvedContent.isNotEmpty ? resolvedContent : '(내용 없음)',
      spotId: spotId,
      facility: facility,
      likes: _int(data['likesCount']),
      comments: _int(data['commentCount']),
      routeItems: _parseRouteItems(data['routeItems']),
      imageUrls: imageUrls,
      createdAt: createdAt,
    );
  }

  List<TodayRootItem> _parseRouteItems(dynamic value) {
    if (value is! List) return const [];
    final items = <TodayRootItem>[];
    for (final raw in value) {
      if (raw is! Map) continue;
      final item = raw.cast<String, dynamic>();
      final spotName = _string(item['spotName']);
      final spotId = _string(item['spotId']);
      final timeRange = _string(item['timeRange']);
      if (spotName.isEmpty && spotId.isEmpty) continue;
      items.add(
        TodayRootItem(
          spotId: spotId.isNotEmpty ? spotId : spotName,
          spotName: spotName.isNotEmpty ? spotName : spotId,
          timeRange: timeRange,
          note: _string(item['note']),
        ),
      );
    }
    return items;
  }

  String _stripHtml(String html) {
    if (html.isEmpty) return '';
    final withoutTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return withoutTags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _toRelativeTime(DateTime? dateTime, DateTime now) {
    if (dateTime == null) return '';
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}.$month.$day';
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    return const {};
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => _string(item))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _string(dynamic value) {
    if (value is String) return value.trim();
    return '';
  }
}
