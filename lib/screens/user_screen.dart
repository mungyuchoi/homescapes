import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/community/data/repositories/community_category_repository.dart';
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
  final CommunityCategoryRepository _categoryRepository =
      CommunityCategoryRepository();
  static const List<({String code, String label})> _userReportReasons = [
    (code: 'spam', label: '스팸 또는 허위 활동이에요'),
    (code: 'abusive', label: '불쾌하거나 괴롭히는 사용자예요'),
    (code: 'impersonation', label: '다른 사람을 사칭하고 있어요'),
    (code: 'other', label: '다른 문제가 있어요'),
  ];

  List<CommunityCategory> _postCategories = CommunityCategory.defaults;
  static const DayFacilitySlotsDoc _emptyDaySlots = DayFacilitySlotsDoc(
    dayId: '',
    facilitySlots: <String, FacilitySlotsDoc>{},
  );

  bool _isLoading = true;
  String? _error;
  bool _isViewerAdmin = false;
  bool _isRestricted = false;
  bool _isTogglingRestriction = false;
  bool _isBlockingUser = false;
  bool _isReportingUser = false;
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
      final categoriesFuture = _categoryRepository.fetchCategories();
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
        categoriesFuture,
        myAdminFuture,
        followerFuture,
        followingFuture,
        postsFuture,
      ]);

      final userSnapshot =
          resolved[0] as DocumentSnapshot<Map<String, dynamic>>;
      final categories = resolved[1] as List<CommunityCategory>;
      final isViewerAdmin = resolved[2] as bool;
      final followerCount = resolved[3] as int;
      final followingCount = resolved[4] as int;
      final postsSnapshot = resolved[5] as QuerySnapshot<Map<String, dynamic>>;

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
        _postCategories = categories;
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
        SnackBar(content: Text(next ? '이용금지 처리되었습니다.' : '이용금지 해제되었습니다.')),
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

  Future<void> _showBlockUserDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 이용해주세요.')));
      return;
    }
    if (currentUser.uid == widget.uid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('본인은 차단할 수 없습니다.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isBlockingUser,
      builder: (context) {
        return AlertDialog(
          title: const Text('사용자를 차단할까요?'),
          content: Text(
            '$_displayName님의 게시글과 댓글이 내 화면에서 가려집니다.\n차단은 [설정 > 차단 내역 관리]에서 해제할 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: _isBlockingUser
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: _isBlockingUser
                  ? null
                  : () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE95353),
                foregroundColor: Colors.white,
              ),
              child: const Text('차단하기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _blockUser();
    }
  }

  Future<void> _blockUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (_isBlockingUser) return;

    setState(() => _isBlockingUser = true);
    try {
      final blockedUsersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('blocked_users');
      final docRef = blockedUsersRef.doc(widget.uid);
      final existing = await docRef.get();
      if (!existing.exists) {
        final blockedSnapshot = await blockedUsersRef.limit(4).get();
        if (blockedSnapshot.docs.length >= 3) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('차단은 최대 3명까지 가능합니다.')));
          return;
        }
      }

      await docRef.set({
        'blockedUid': widget.uid,
        'blockedAuthor': _displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _posts = const <_UserPostGridItem>[]);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('차단되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('차단 처리 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isBlockingUser = false);
      }
    }
  }

  Future<void> _showUserReportSheet() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 신고할 수 있습니다.')));
      return;
    }
    if (currentUser.uid == widget.uid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('본인은 신고할 수 없습니다.')));
      return;
    }

    var selectedCode = _userReportReasons.first.code;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DEE8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '사용자 신고하기',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._userReportReasons.map((reason) {
                      final selected = selectedCode == reason.code;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () =>
                              setModalState(() => selectedCode = reason.code),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFF1DF)
                                  : const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFED9A3A)
                                    : const Color(0xFFE2E7EF),
                              ),
                            ),
                            child: Text(
                              reason.label,
                              style: const TextStyle(
                                color: Color(0xFF283043),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isReportingUser
                            ? null
                            : () async {
                                final reason = _userReportReasons.firstWhere(
                                  (it) => it.code == selectedCode,
                                );
                                await _submitUserReport(
                                  reasonCode: reason.code,
                                  reasonLabel: reason.label,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFED9A3A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_isReportingUser ? '신고 중...' : '신고하기'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitUserReport({
    required String reasonCode,
    required String reasonLabel,
  }) async {
    final reporter = FirebaseAuth.instance.currentUser;
    if (reporter == null || _isReportingUser) return;

    setState(() => _isReportingUser = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final reportId = firestore
          .collection('meta')
          .doc('reports')
          .collection('users')
          .doc()
          .id;
      final payload = <String, dynamic>{
        'reportId': reportId,
        'targetType': 'user',
        'targetId': widget.uid,
        'targetAuthorUid': widget.uid,
        'targetAuthorName': _displayName,
        'reporterUid': reporter.uid,
        'reasonCode': reasonCode,
        'reasonLabel': reasonLabel,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();
      batch.set(
        firestore
            .collection('meta')
            .doc('reports')
            .collection('users')
            .doc(reportId),
        payload,
      );
      batch.set(
        firestore
            .collection('users')
            .doc(reporter.uid)
            .collection('reports_users')
            .doc(reportId),
        payload,
      );
      batch.set(firestore.collection('users').doc(widget.uid), {
        'reportsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('신고 처리 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isReportingUser = false);
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
                if (_viewerUid != widget.uid) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isReportingUser
                              ? null
                              : _showUserReportSheet,
                          icon: const Icon(Icons.report_gmailerrorred_rounded),
                          label: Text(_isReportingUser ? '신고 중' : '신고'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE95353),
                            side: const BorderSide(color: Color(0xFFE95353)),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isBlockingUser
                              ? null
                              : _showBlockUserDialog,
                          icon: const Icon(Icons.person_off_outlined),
                          label: Text(_isBlockingUser ? '처리중' : '차단'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5F6B82),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
      backgroundImage:
          (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))
          ? NetworkImage(photoUrl)
          : null,
      child: (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))
          ? null
          : const Icon(
              Icons.person_rounded,
              color: Color(0xFF7E8798),
              size: 30,
            ),
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
                  errorBuilder: (context, error, stackTrace) => _fallback(),
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
