import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/community/data/repositories/community_repository.dart';
import '../features/community/services/community_service.dart';
import '../features/profile/data/repositories/follow_repository.dart';
import '../models/app_models.dart';
import '../utils/user_access_utils.dart';
import 'feed_detail_screen.dart';
import 'follow_list_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key, required this.uid});

  final String uid;

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FollowRepository _followRepository = FollowRepository();
  final CommunityService _communityService = CommunityService(
    repository: CommunityRepositoryImpl(),
  );

  static const List<String> _postCategories = <String>[
    '전체',
    '자유',
    '궁금해요',
    '오늘의 루트',
    '꿀팁',
  ];
  static const DayFacilitySlotsDoc _emptyDaySlots = DayFacilitySlotsDoc(
    dayId: '',
    facilitySlots: <String, FacilitySlotsDoc>{},
  );

  bool _isLoading = true;
  String? _error;
  bool _isViewerAdmin = false;
  bool _isRestricted = false;
  bool _isTogglingRestriction = false;
  String _displayName = '';
  String _photoUrl = '';
  String _bio = '';
  int _followerCount = 0;
  int _followingCount = 0;
  List<_UserPostGridItem> _posts = const <_UserPostGridItem>[];

  String? get _viewerUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final userDocFuture = firestore.collection('users').doc(widget.uid).get();
      final myAdminFuture = UserAccessUtils.isCurrentUserAdmin();
      final followerFuture = _followRepository.getFollowerCount(widget.uid);
      final followingFuture = _followRepository.getFollowingCount(widget.uid);
      final postsFuture = firestore
          .collection('users')
          .doc(widget.uid)
          .collection('my_posts')
          .orderBy('createdAt', descending: true)
          .limit(120)
          .get();

      final resolved = await Future.wait<dynamic>([
        userDocFuture,
        myAdminFuture,
        followerFuture,
        followingFuture,
        postsFuture,
      ]);

      final userSnapshot =
          resolved[0] as DocumentSnapshot<Map<String, dynamic>>;
      final isViewerAdmin = resolved[1] as bool;
      final followerCount = resolved[2] as int;
      final followingCount = resolved[3] as int;
      final postsSnapshot = resolved[4] as QuerySnapshot<Map<String, dynamic>>;

      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final displayName = (userData['displayName'] as String? ?? '').trim();
      final photoUrl = (userData['photoURL'] as String? ?? '').trim();
      final photoUrlLegacy = (userData['photoUrl'] as String? ?? '').trim();
      final bio = (userData['bio'] as String? ?? '').trim();
      final statusMessage = (userData['statusMessage'] as String? ?? '').trim();
      final description = (userData['description'] as String? ?? '').trim();
      final isRestricted = UserAccessUtils.isRestrictedData(userData);

      final posts = postsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            if ((data['isDeleted'] as bool?) == true) return null;
            return _UserPostGridItem(
              postId: doc.id,
              thumbnailUrl: (data['thumbnailUrl'] as String? ?? '').trim(),
              contentText: (data['contentText'] as String? ?? '').trim(),
            );
          })
          .whereType<_UserPostGridItem>()
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _isViewerAdmin = isViewerAdmin;
        _isRestricted = isRestricted;
        _displayName = displayName.isNotEmpty ? displayName : widget.uid;
        _photoUrl = photoUrl.isNotEmpty ? photoUrl : photoUrlLegacy;
        _bio = bio.isNotEmpty
            ? bio
            : (statusMessage.isNotEmpty
                  ? statusMessage
                  : (description.isNotEmpty ? description : '소개글이 없습니다.'));
        _followerCount = followerCount;
        _followingCount = followingCount;
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '사용자 정보를 불러오지 못했습니다: $e';
      });
    }
  }

  Future<void> _toggleRestriction() async {
    if (_isTogglingRestriction) return;
    if (!_isViewerAdmin) return;
    if (_viewerUid == widget.uid) return;

    setState(() => _isTogglingRestriction = true);
    try {
      final next = !_isRestricted;
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'isRestricted': next,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _isRestricted = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? '이용금지 처리되었습니다.' : '이용금지 해제되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('처리 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isTogglingRestriction = false);
      }
    }
  }

  Future<void> _openFollowList(int initialTabIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FollowListScreen(uid: widget.uid, initialTabIndex: initialTabIndex),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openPostDetail(String postId) async {
    final normalizedPostId = postId.trim();
    if (normalizedPostId.isEmpty) return;
    CommunityPost? post;
    try {
      post = await _communityService.getPostById(
        postId: normalizedPostId,
        now: DateTime.now(),
        uid: FirebaseAuth.instance.currentUser?.uid ?? 'guest_demo',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('게시글을 불러오지 못했습니다: $e')));
      return;
    }

    if (!mounted) return;
    if (post == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글을 찾을 수 없습니다.')));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedDetailScreen(
          post: post!,
          categories: _postCategories,
          spotOptions: const <SpotDoc>[],
          todaySlotsDoc: _emptyDaySlots,
        ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F1F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          '사용자 프로필',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A8190),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      _UserAvatar(photoUrl: _photoUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F2533),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _bio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7E8799),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isViewerAdmin && _viewerUid != widget.uid)
                        FilledButton(
                          onPressed: _isTogglingRestriction
                              ? null
                              : _toggleRestriction,
                          style: FilledButton.styleFrom(
                            backgroundColor: _isRestricted
                                ? const Color(0xFF5F6B82)
                                : const Color(0xFFE95353),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(96, 40),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            _isTogglingRestriction
                                ? '처리중'
                                : (_isRestricted ? '해지' : '이용금지'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CountCard(
                        label: '팔로워',
                        value: _followerCount,
                        onTap: () => _openFollowList(0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CountCard(
                        label: '팔로잉',
                        value: _followingCount,
                        onTap: () => _openFollowList(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '작성된 게시물',
                  style: TextStyle(
                    color: Color(0xFF1A1D27),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (_posts.isEmpty)
                  const Text(
                    '작성된 게시물이 없어요.',
                    style: TextStyle(
                      color: Color(0xFF8E95A4),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = _posts[index];
                      return _UserPostGridTile(
                        item: item,
                        onTap: () => _openPostDetail(item.postId),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFD1D7E1),
      backgroundImage: (photoUrl.startsWith('http://') ||
              photoUrl.startsWith('https://'))
          ? NetworkImage(photoUrl)
          : null,
      child: (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))
          ? null
          : const Icon(Icons.person_rounded, color: Color(0xFF7E8798), size: 30),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Color(0xFF1D2230),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7C8493),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserPostGridItem {
  const _UserPostGridItem({
    required this.postId,
    required this.thumbnailUrl,
    required this.contentText,
  });

  final String postId;
  final String thumbnailUrl;
  final String contentText;
}

class _UserPostGridTile extends StatelessWidget {
  const _UserPostGridTile({required this.item, required this.onTap});

  final _UserPostGridItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: item.thumbnailUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                ),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    final text = item.contentText.isNotEmpty ? item.contentText : '(내용 없음)';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4A5262),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
