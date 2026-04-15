import 'package:homescapes/models/app_models.dart';

import '../data/repositories/community_repository.dart';

class CommunityService {
  const CommunityService({required this.repository});

  final CommunityRepository repository;

  Future<List<CommunityPost>> getPosts({
    String? category,
    DateTime? now,
    String uid = 'guest_demo',
  }) async {
    final posts = await repository.fetchCommunityPosts(now: now, uid: uid);
    if (category == null || category.isEmpty || category == '전체') {
      return posts;
    }
    return posts.where((post) => post.category == category).toList();
  }

  Future<List<CommunityPost>> getCachedPosts({
    String? category,
    DateTime? now,
    String uid = 'guest_demo',
  }) async {
    final posts = await repository.fetchCommunityPostsFromCache(
      now: now,
      uid: uid,
    );
    if (category == null || category.isEmpty || category == '전체') {
      return posts;
    }
    return posts.where((post) => post.category == category).toList();
  }

  Future<List<CommunityPost>> getAllPosts({
    DateTime? now,
    String uid = 'guest_demo',
  }) {
    return repository.fetchCommunityPosts(now: now, uid: uid);
  }

  Future<CommunityPost?> getPostById({
    required String postId,
    DateTime? now,
    String uid = 'guest_demo',
  }) {
    return repository.fetchPostById(postId: postId, now: now, uid: uid);
  }
}
