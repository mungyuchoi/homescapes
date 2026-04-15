import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homescapes/models/app_models.dart';

import '../datasources/community_firestore_data_source.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> fetchCommunityPosts({
    DateTime? now,
    String uid = 'guest_demo',
  });

  Future<List<CommunityPost>> fetchCommunityPostsFromCache({
    DateTime? now,
    String uid = 'guest_demo',
  });

  Future<CommunityPost?> fetchPostById({
    required String postId,
    DateTime? now,
    String uid = 'guest_demo',
  });
}

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl({
    CommunityFirestoreDataSource? dataSource,
    FirebaseFirestore? firestore,
  }) : dataSource = dataSource ?? CommunityFirestoreDataSource(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final CommunityFirestoreDataSource dataSource;
  final FirebaseFirestore _firestore;

  @override
  Future<List<CommunityPost>> fetchCommunityPosts({
    DateTime? now,
    String uid = 'guest_demo',
  }) async {
    final posts = await dataSource.fetchPostsFromServer(now: now);
    return _filterBlockedPosts(posts: posts, uid: uid);
  }

  @override
  Future<List<CommunityPost>> fetchCommunityPostsFromCache({
    DateTime? now,
    String uid = 'guest_demo',
  }) async {
    final posts = await dataSource.fetchPostsFromCache(now: now);
    return _filterBlockedPosts(posts: posts, uid: uid);
  }

  @override
  Future<CommunityPost?> fetchPostById({
    required String postId,
    DateTime? now,
    String uid = 'guest_demo',
  }) async {
    final post = await dataSource.fetchPostById(postId, now: now);
    if (post == null) return null;
    final blockedUids = await _loadBlockedUids(uid: uid);
    if (blockedUids.contains(post.uid.trim())) {
      return null;
    }
    return post;
  }

  Future<List<CommunityPost>> _filterBlockedPosts({
    required List<CommunityPost> posts,
    required String uid,
  }) async {
    if (posts.isEmpty) return posts;
    final blockedUids = await _loadBlockedUids(uid: uid);
    if (blockedUids.isEmpty) return posts;
    return posts
        .where((post) => !blockedUids.contains(post.uid.trim()))
        .toList(growable: false);
  }

  Future<Set<String>> _loadBlockedUids({required String uid}) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty || normalizedUid == 'guest_demo') {
      return const <String>{};
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(normalizedUid)
          .collection('blocked_users')
          .get();
      final blockedUids = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final blockedUid = (data['blockedUid'] as String? ?? '').trim();
        if (blockedUid.isNotEmpty) {
          blockedUids.add(blockedUid);
          continue;
        }
        final docId = doc.id.trim();
        if (docId.isNotEmpty) {
          blockedUids.add(docId);
        }
      }
      return blockedUids;
    } catch (_) {
      return const <String>{};
    }
  }
}
