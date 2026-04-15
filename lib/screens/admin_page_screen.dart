import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/user_access_utils.dart';
import 'bottom_sheet_ad_management_screen.dart';
import 'dialog_ad_management_screen.dart';
import 'notice_screen.dart';

class AdminPageScreen extends StatefulWidget {
  const AdminPageScreen({super.key});

  @override
  State<AdminPageScreen> createState() => _AdminPageScreenState();
}

class _AdminPageScreenState extends State<AdminPageScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
  }

  Future<void> _loadAdminRole() async {
    final isAdmin = await UserAccessUtils.isCurrentUserAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _isLoading = false;
    });
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
          '관리자 페이지',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            )
          : !_isAdmin
          ? const Center(
              child: Text(
                '관리자 권한이 없습니다.',
                style: TextStyle(
                  color: Color(0xFF7A8190),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _AdminMenuTile(
                  title: '문의 관리',
                  icon: Icons.support_agent_rounded,
                  onTap: () => _open(const _AdminInquiryPage()),
                ),
                _AdminMenuTile(
                  title: '신고 관리',
                  icon: Icons.report_gmailerrorred_rounded,
                  onTap: () => _open(const _AdminReportPage()),
                ),
                _AdminMenuTile(
                  title: '사용자 관리',
                  icon: Icons.groups_rounded,
                  onTap: () => _open(const _AdminUserManagePage()),
                ),
                _AdminMenuTile(
                  title: '게시글 관리',
                  icon: Icons.feed_outlined,
                  onTap: () => _open(const _AdminPostManagePage()),
                ),
                _AdminMenuTile(
                  title: '통계 대시보드',
                  icon: Icons.dashboard_customize_outlined,
                  onTap: () => _open(const _AdminDashboardPage()),
                ),
                _AdminMenuTile(
                  title: '기간별 통계',
                  icon: Icons.date_range_rounded,
                  onTap: () => _open(const _AdminPeriodStatsPage()),
                ),
                _AdminMenuTile(
                  title: '인기 콘텐츠',
                  icon: Icons.trending_up_rounded,
                  onTap: () => _open(const _AdminPopularContentPage()),
                ),
                _AdminMenuTile(
                  title: '공지사항 관리',
                  icon: Icons.campaign_outlined,
                  onTap: () => _open(const NoticeScreen()),
                ),
                _AdminMenuTile(
                  title: '바텀시트 광고 관리',
                  icon: Icons.ads_click_rounded,
                  onTap: () => _open(const BottomSheetAdManagementScreen()),
                ),
                _AdminMenuTile(
                  title: '앱 시작 팝업 관리',
                  icon: Icons.open_in_new_rounded,
                  onTap: () => _open(const DialogAdManagementScreen()),
                ),
              ],
            ),
    );
  }

  Future<void> _open(Widget page) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF5E6778)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1F2430),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B92A2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminInquiryPage extends StatelessWidget {
  const _AdminInquiryPage();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('meta')
        .doc('feedback')
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

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
          '문의 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('문의를 불러오지 못했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '등록된 문의가 없습니다.',
                style: TextStyle(
                  color: Color(0xFF7A8190),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final feedbackId = doc.id;
              final uid = _string(data['uid']);
              final displayName = _string(data['displayName']);
              final email = _string(data['email']);
              final message = _string(data['message']);
              final reply = _string(data['reply']);
              final status = _normalizeStatus(_string(data['status']));
              final createdAt = _parseDateTime(data['createdAt']);
              final statusStyle = _statusStyle(status);

              return Container(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusStyle.$2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusStyle.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDateTime(createdAt),
                          style: const TextStyle(
                            color: Color(0xFF8A91A1),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.isNotEmpty ? message : '(문의 내용 없음)',
                      style: const TextStyle(
                        color: Color(0xFF1F2533),
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayName.isNotEmpty ? displayName : uid,
                      style: const TextStyle(
                        color: Color(0xFF5E6778),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF8A91A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (reply.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '답변: $reply',
                          style: const TextStyle(
                            color: Color(0xFF596275),
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _openReplySheet(
                          context: context,
                          feedbackId: feedbackId,
                          uid: uid,
                          currentReply: reply,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4C88FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(118, 38),
                        ),
                        icon: const Icon(Icons.reply_rounded, size: 18),
                        label: Text(
                          reply.isEmpty ? '답변 작성' : '답변 수정',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openReplySheet({
    required BuildContext context,
    required String feedbackId,
    required String uid,
    required String currentReply,
  }) async {
    final controller = TextEditingController(text: currentReply);
    var isSaving = false;
    var isClosingSheet = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> saveReply() async {
              final reply = controller.text.trim();
              if (reply.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('답변 내용을 입력해 주세요.')),
                );
                return;
              }

              if (isSaving) return;
              setSheetState(() => isSaving = true);

              try {
                await _updateFeedbackReply(
                  feedbackId: feedbackId,
                  uid: uid,
                  reply: reply,
                );
                if (!sheetContext.mounted) return;
                isClosingSheet = true;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('문의 답변이 저장되었습니다.')),
                );
              } catch (e) {
                if (!sheetContext.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('답변 저장 실패: $e')));
              } finally {
                if (!isClosingSheet && sheetContext.mounted) {
                  setSheetState(() => isSaving = false);
                }
              }
            }

            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            return SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '문의 답변 작성',
                          style: TextStyle(
                            color: Color(0xFF1F2533),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller,
                          maxLines: 6,
                          minLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: '문의에 대한 답변을 입력해 주세요.',
                            filled: true,
                            fillColor: const Color(0xFFF6F7FB),
                            contentPadding: const EdgeInsets.fromLTRB(
                              12,
                              12,
                              12,
                              12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSaving ? null : saveReply,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4C88FF),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                            ),
                            child: Text(
                              isSaving ? '저장 중...' : '답변 저장',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _updateFeedbackReply({
    required String feedbackId,
    required String uid,
    required String reply,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final feedbackRef = firestore
        .collection('meta')
        .doc('feedback')
        .collection('items')
        .doc(feedbackId);

    final feedbackData = <String, dynamic>{
      'reply': reply,
      'status': 'answered',
      'updatedAt': now,
      'repliedAt': now,
    };
    if (adminUid.isNotEmpty) {
      feedbackData['repliedBy'] = adminUid;
    }
    batch.set(feedbackRef, feedbackData, SetOptions(merge: true));

    if (uid.isNotEmpty) {
      final userRef = firestore
          .collection('users')
          .doc(uid)
          .collection('feedback')
          .doc(feedbackId);
      batch.set(userRef, {
        'feedbackId': feedbackId,
        'status': 'answered',
        'reply': reply,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  static String _string(dynamic value) {
    if (value is String) return value.trim();
    return '';
  }

  static String _normalizeStatus(String rawStatus) {
    switch (rawStatus) {
      case 'answered':
      case 'resolved':
      case 'closed':
        return 'answered';
      case 'pending':
      default:
        return 'pending';
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _formatDateTime(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) return '방금 전';
    return '${value.year}.${_two(value.month)}.${_two(value.day)} ${_two(value.hour)}:${_two(value.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static (String, Color) _statusStyle(String status) {
    switch (status) {
      case 'answered':
        return ('답변 완료', const Color(0xFF4C88FF));
      case 'pending':
      default:
        return ('접수 대기', const Color(0xFFED9A3A));
    }
  }
}

class _AdminReportPage extends StatelessWidget {
  const _AdminReportPage();

  @override
  Widget build(BuildContext context) {
    final postsQuery = FirebaseFirestore.instance
        .collection('meta')
        .doc('reports')
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(100);
    final commentsQuery = FirebaseFirestore.instance
        .collection('meta')
        .doc('reports')
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(100);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            '신고 관리',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFFED9A3A),
            unselectedLabelColor: Color(0xFF7D8495),
            indicatorColor: Color(0xFFED9A3A),
            tabs: [
              Tab(text: '게시글 신고'),
              Tab(text: '댓글 신고'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AdminCollectionBody(
              stream: postsQuery.snapshots(),
              emptyText: '게시글 신고가 없습니다.',
            ),
            _AdminCollectionBody(
              stream: commentsQuery.snapshots(),
              emptyText: '댓글 신고가 없습니다.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUserManagePage extends StatelessWidget {
  const _AdminUserManagePage();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('lastLoginAt', descending: true)
        .limit(200)
        .snapshots();

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
          '사용자 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('사용자 목록을 불러오지 못했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            );
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '사용자 데이터가 없습니다.',
                style: TextStyle(
                  color: Color(0xFF7A8190),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final uid = doc.id;
              final displayName = (data['displayName'] as String? ?? '').trim();
              final restricted = UserAccessUtils.isRestrictedData(data);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isNotEmpty ? displayName : uid,
                            style: const TextStyle(
                              color: Color(0xFF1F2533),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            uid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8A91A1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .set({
                              'isRestricted': !restricted,
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: restricted
                            ? const Color(0xFF5F6B82)
                            : const Color(0xFFE95353),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(88, 38),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        restricted ? '해지' : '이용금지',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminPostManagePage extends StatelessWidget {
  const _AdminPostManagePage();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

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
          '게시글 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('게시글을 불러오지 못했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            );
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '게시글이 없습니다.',
                style: TextStyle(
                  color: Color(0xFF7A8190),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final postId = doc.id;
              final content = (data['contentText'] as String? ?? '').trim();
              final isHidden = (data['isHidden'] as bool?) ?? false;
              final isDeleted = (data['isDeleted'] as bool?) ?? false;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.isNotEmpty ? content : '(내용 없음)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2533),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      postId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A91A1),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .set({
                                  'isHidden': !isHidden,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: isHidden
                                ? const Color(0xFF4E6FAF)
                                : const Color(0xFF6F7788),
                            minimumSize: const Size(84, 36),
                          ),
                          child: Text(
                            isHidden ? '숨김해제' : '숨김',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .set({
                                  'isDeleted': !isDeleted,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: isDeleted
                                ? const Color(0xFF3D8D6B)
                                : const Color(0xFFE05656),
                            minimumSize: const Size(84, 36),
                          ),
                          child: Text(
                            isDeleted ? '삭제해제' : '삭제',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  Future<Map<String, int>> _loadCounts() async {
    final firestore = FirebaseFirestore.instance;
    final userCountFuture = firestore.collection('users').count().get();
    final postCountFuture = firestore.collection('posts').count().get();
    final postReportCountFuture = firestore
        .collection('meta')
        .doc('reports')
        .collection('posts')
        .count()
        .get();
    final commentReportCountFuture = firestore
        .collection('meta')
        .doc('reports')
        .collection('comments')
        .count()
        .get();
    final noticeCountFuture = firestore
        .collection('meta')
        .doc('notice')
        .collection('notices')
        .count()
        .get();

    final resolved = await Future.wait([
      userCountFuture,
      postCountFuture,
      postReportCountFuture,
      commentReportCountFuture,
      noticeCountFuture,
    ]);

    return <String, int>{
      'users': resolved[0].count ?? 0,
      'posts': resolved[1].count ?? 0,
      'postReports': resolved[2].count ?? 0,
      'commentReports': resolved[3].count ?? 0,
      'notices': resolved[4].count ?? 0,
    };
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
          '통계 대시보드',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _loadCounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('통계를 불러오지 못했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _StatCard(title: '사용자 수', value: '${data['users']}'),
              _StatCard(title: '게시글 수', value: '${data['posts']}'),
              _StatCard(title: '게시글 신고 수', value: '${data['postReports']}'),
              _StatCard(title: '댓글 신고 수', value: '${data['commentReports']}'),
              _StatCard(title: '공지사항 수', value: '${data['notices']}'),
            ],
          );
        },
      ),
    );
  }
}

class _AdminPeriodStatsPage extends StatefulWidget {
  const _AdminPeriodStatsPage();

  @override
  State<_AdminPeriodStatsPage> createState() => _AdminPeriodStatsPageState();
}

class _AdminPeriodStatsPageState extends State<_AdminPeriodStatsPage> {
  int _days = 7;

  Future<Map<String, int>> _loadPeriodStats() async {
    final firestore = FirebaseFirestore.instance;
    final from = DateTime.now().subtract(Duration(days: _days));
    final fromTs = Timestamp.fromDate(from);

    final postCountFuture = firestore
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: fromTs)
        .count()
        .get();
    final userCountFuture = firestore
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: fromTs)
        .count()
        .get();
    final postReportCountFuture = firestore
        .collection('meta')
        .doc('reports')
        .collection('posts')
        .where('createdAt', isGreaterThanOrEqualTo: fromTs)
        .count()
        .get();
    final commentReportCountFuture = firestore
        .collection('meta')
        .doc('reports')
        .collection('comments')
        .where('createdAt', isGreaterThanOrEqualTo: fromTs)
        .count()
        .get();

    final resolved = await Future.wait([
      postCountFuture,
      userCountFuture,
      postReportCountFuture,
      commentReportCountFuture,
    ]);
    return <String, int>{
      'posts': resolved[0].count ?? 0,
      'users': resolved[1].count ?? 0,
      'postReports': resolved[2].count ?? 0,
      'commentReports': resolved[3].count ?? 0,
    };
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
          '기간별 통계',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _days = 7),
                  style: FilledButton.styleFrom(
                    backgroundColor: _days == 7
                        ? const Color(0xFFED9A3A)
                        : const Color(0xFFD8DEE8),
                    foregroundColor: _days == 7
                        ? Colors.white
                        : const Color(0xFF596070),
                  ),
                  child: const Text('7일'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _days = 30),
                  style: FilledButton.styleFrom(
                    backgroundColor: _days == 30
                        ? const Color(0xFFED9A3A)
                        : const Color(0xFFD8DEE8),
                    foregroundColor: _days == 30
                        ? Colors.white
                        : const Color(0xFF596070),
                  ),
                  child: const Text('30일'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, int>>(
            future: _loadPeriodStats(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('통계를 불러오지 못했습니다: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
                  ),
                );
              }
              final data = snapshot.data!;
              return Column(
                children: [
                  _StatCard(title: '신규 게시글', value: '${data['posts']}'),
                  _StatCard(title: '신규 가입자', value: '${data['users']}'),
                  _StatCard(title: '게시글 신고', value: '${data['postReports']}'),
                  _StatCard(title: '댓글 신고', value: '${data['commentReports']}'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminPopularContentPage extends StatelessWidget {
  const _AdminPopularContentPage();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('likesCount', descending: true)
        .limit(50)
        .snapshots();

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
          '인기 콘텐츠',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('인기 콘텐츠를 불러오지 못했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            );
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '인기 콘텐츠가 없습니다.',
                style: TextStyle(
                  color: Color(0xFF7A8190),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final content = (data['contentText'] as String? ?? '').trim();
              final likeCount = (data['likesCount'] as int?) ?? 0;
              final commentCount = (data['commentCount'] as int?) ?? 0;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.isNotEmpty ? content : '(내용 없음)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2533),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '좋아요 $likeCount · 댓글 $commentCount',
                      style: const TextStyle(
                        color: Color(0xFF7E8798),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminCollectionBody extends StatelessWidget {
  const _AdminCollectionBody({required this.stream, required this.emptyText});

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('데이터를 불러오지 못했습니다: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: const TextStyle(
                color: Color(0xFF7A8190),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final primary =
                (data['title'] as String? ??
                        data['reasonLabel'] as String? ??
                        data['targetType'] as String? ??
                        docs[index].id)
                    .trim();
            final secondary =
                (data['contentText'] as String? ??
                        data['targetId'] as String? ??
                        data['reporterUid'] as String? ??
                        '')
                    .trim();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary.isNotEmpty ? primary : '(제목 없음)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F2533),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (secondary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF80889A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1F2533),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFED9A3A),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
