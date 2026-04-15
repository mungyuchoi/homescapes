import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef NotificationPayloadHandler =
    Future<void> Function(Map<String, String> payload);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onOpenPayload,
  });
  const NotificationScreen.inquiry({super.key, this.onOpenPayload})
    : initialTabIndex = 1;

  final int initialTabIndex;
  final NotificationPayloadHandler? onOpenPayload;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingFeedback = false;

  static const _tabs = ['내 소식', '문의 내역'];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, _tabs.length - 1);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _openFeedbackComposer() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 문의를 작성할 수 있어요.')));
      return;
    }

    _feedbackController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F8FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, bottomInset + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '문의 작성',
                      style: TextStyle(
                        color: Color(0xFF1A1D27),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _feedbackController,
                autofocus: true,
                minLines: 4,
                maxLines: 7,
                maxLength: 400,
                decoration: InputDecoration(
                  hintText: '불편한 점이나 개선 아이디어를 남겨주세요.',
                  hintStyle: const TextStyle(
                    color: Color(0xFF959CAB),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE3E7EE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE3E7EE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFED9A3A)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmittingFeedback
                      ? null
                      : () async {
                          final message = _feedbackController.text;
                          Navigator.of(sheetContext).pop();
                          await _submitFeedback(message);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED9A3A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSubmittingFeedback ? '등록 중...' : '문의 등록',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitFeedback(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문의 내용을 입력해 주세요.')));
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 문의를 작성할 수 있어요.')));
      return;
    }

    setState(() => _isSubmittingFeedback = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final feedbackId = firestore
          .collection('meta')
          .doc('feedback')
          .collection('items')
          .doc()
          .id;
      final metaRef = firestore
          .collection('meta')
          .doc('feedback')
          .collection('items')
          .doc(feedbackId);
      final userRef = firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('feedback')
          .doc(feedbackId);
      final displayName = (currentUser.displayName ?? '').trim();
      final batch = firestore.batch();

      batch.set(metaRef, {
        'feedbackId': feedbackId,
        'uid': currentUser.uid,
        'displayName': displayName,
        'email': currentUser.email,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(userRef, {'feedbackId': feedbackId});

      await batch.commit();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문의가 접수되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('문의 등록 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmittingFeedback = false);
      }
    }
  }

  Future<List<_FeedbackEntry>> _loadFeedbackEntries(
    List<String> feedbackIds,
  ) async {
    if (feedbackIds.isEmpty) return const <_FeedbackEntry>[];

    final firestore = FirebaseFirestore.instance;
    final snapshots = await Future.wait(
      feedbackIds.map(
        (feedbackId) => firestore
            .collection('meta')
            .doc('feedback')
            .collection('items')
            .doc(feedbackId)
            .get(),
      ),
    );

    final entries = snapshots
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data();
          if (data == null) return null;
          return _FeedbackEntry.fromMap(doc.id, data);
        })
        .whereType<_FeedbackEntry>()
        .toList();

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    IconData fallbackIcon = Icons.notifications_none_rounded,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Column(
        children: [
          const Spacer(flex: 7),
          Image.asset(
            'assets/img/icon/gray_icon.png',
            width: 220,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Icon(fallbackIcon, size: 120, color: const Color(0xFFB1B6C1)),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1B1E27),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF717986),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(flex: 9),
        ],
      ),
    );
  }

  Widget _buildInquiryTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildEmptyState(
        title: '로그인 후 문의 내역을 확인할 수 있어요.',
        subtitle: '하단 문의 작성 버튼으로 바로 문의를 남길 수 있어요.',
        fallbackIcon: Icons.lock_outline_rounded,
      );
    }

    final userFeedbackStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('feedback')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: userFeedbackStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '문의 내역을 불러오지 못했습니다: ${snapshot.error}',
              style: const TextStyle(
                color: Color(0xFF727A89),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
          );
        }

        final feedbackIds = snapshot.data!.docs
            .map((doc) {
              final fromData = (doc.data()['feedbackId'] as String? ?? '')
                  .trim();
              return fromData.isNotEmpty ? fromData : doc.id.trim();
            })
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false);

        if (feedbackIds.isEmpty) {
          return _buildEmptyState(
            title: '새로운 문의 내역이 없습니다.',
            subtitle: '문의를 남기면 이 탭에서 상태를 확인할 수 있어요.',
            fallbackIcon: Icons.sms_outlined,
          );
        }

        return FutureBuilder<List<_FeedbackEntry>>(
          future: _loadFeedbackEntries(feedbackIds),
          builder: (context, feedbackSnapshot) {
            if (feedbackSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
              );
            }
            if (feedbackSnapshot.hasError) {
              return Center(
                child: Text(
                  '문의 상세를 불러오지 못했습니다: ${feedbackSnapshot.error}',
                  style: const TextStyle(
                    color: Color(0xFF727A89),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final entries = feedbackSnapshot.data ?? const <_FeedbackEntry>[];
            if (entries.isEmpty) {
              return _buildEmptyState(
                title: '문의 상세를 찾지 못했습니다.',
                subtitle: '잠시 후 다시 시도해 주세요.',
                fallbackIcon: Icons.sms_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: entries.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _FeedbackCard(entry: entry);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openMyNewsEntry(_MyNewsEntry entry) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(entry.notificationId)
          .set({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}

    final onOpenPayload = widget.onOpenPayload;
    if (onOpenPayload == null) return;
    await onOpenPayload(entry.toPayload());
  }

  Widget _buildMyNewsTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return _buildEmptyState(
        title: '로그인 후 알림을 확인할 수 있어요.',
        subtitle: '로그인하면 내 활동 알림이 표시됩니다.',
        fallbackIcon: Icons.lock_outline_rounded,
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(120)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '알림을 불러오지 못했습니다: ${snapshot.error}',
              style: const TextStyle(
                color: Color(0xFF727A89),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
          );
        }

        final entries = snapshot.data!.docs
            .map(_MyNewsEntry.fromDoc)
            .whereType<_MyNewsEntry>()
            .toList(growable: false);

        if (entries.isEmpty) {
          return _buildEmptyState(
            title: '새로운 알림이 없습니다.',
            subtitle: '활동이 생기면 여기에 표시될거예요.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          itemCount: entries.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _MyNewsCard(
              entry: entry,
              onTap: () => _openMyNewsEntry(entry),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F5),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _isSubmittingFeedback ? null : _openFeedbackComposer,
              backgroundColor: const Color(0xFFED9A3A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(_isSubmittingFeedback ? '등록 중...' : '문의 작성'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1A1D27),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    '알림',
                    style: TextStyle(
                      color: Color(0xFF1A1D27),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E7EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final selected = _selectedTabIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTabIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF1C1F28)
                                  : const Color(0xFF9198A8),
                              fontSize: 17,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildMyNewsTab()
                  : _buildInquiryTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyNewsEntry {
  const _MyNewsEntry({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.actorUid,
    required this.postId,
    required this.commentId,
    required this.feedbackId,
    required this.isRead,
    required this.createdAt,
  });

  final String notificationId;
  final String type;
  final String title;
  final String body;
  final String actorUid;
  final String postId;
  final String commentId;
  final String feedbackId;
  final bool isRead;
  final DateTime createdAt;

  String get createdAtLabel {
    if (createdAt.millisecondsSinceEpoch == 0) return '방금 전';
    return '${createdAt.year}.${_two(createdAt.month)}.${_two(createdAt.day)} ${_two(createdAt.hour)}:${_two(createdAt.minute)}';
  }

  IconData get leadingIcon {
    switch (type) {
      case 'COMMUNITY_POST_COMMENT':
      case 'COMMUNITY_COMMENT_REPLY':
        return Icons.chat_bubble_outline_rounded;
      case 'COMMUNITY_POST_LIKE':
        return Icons.favorite_border_rounded;
      case 'USER_FOLLOWED':
        return Icons.person_add_alt_rounded;
      case 'COMMUNITY_FOLLOWING_POST':
        return Icons.campaign_outlined;
      case 'FEEDBACK_UPDATED':
        return Icons.sms_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Map<String, String> toPayload() {
    return {
      'type': type,
      'actorUid': actorUid,
      'postId': postId,
      'commentId': commentId,
      'feedbackId': feedbackId,
    };
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static _MyNewsEntry? fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final type = (data['type'] as String? ?? '').trim();
    final title = (data['title'] as String? ?? '').trim();
    final body = (data['body'] as String? ?? '').trim();

    return _MyNewsEntry(
      notificationId: doc.id,
      type: type,
      title: title.isNotEmpty ? title : '알림',
      body: body.isNotEmpty ? body : '(내용 없음)',
      actorUid: (data['actorUid'] as String? ?? '').trim(),
      postId: (data['postId'] as String? ?? '').trim(),
      commentId: (data['commentId'] as String? ?? '').trim(),
      feedbackId: (data['feedbackId'] as String? ?? '').trim(),
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: _FeedbackEntry._parseDateTime(data['createdAt']),
    );
  }
}

class _MyNewsCard extends StatelessWidget {
  const _MyNewsCard({required this.entry, required this.onTap});

  final _MyNewsEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: entry.isRead ? Colors.white : const Color(0xFFFFF5E9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FA),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(
                entry.leadingIcon,
                color: const Color(0xFF5A6375),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            color: Color(0xFF1C202C),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.createdAtLabel,
                        style: const TextStyle(
                          color: Color(0xFF8D95A5),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5C6476),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry});

  final _FeedbackEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(entry.status);
    final reply = entry.reply;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusStyle.$2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusStyle.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                entry.createdAtLabel,
                style: const TextStyle(
                  color: Color(0xFF8D95A5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.message,
            style: const TextStyle(
              color: Color(0xFF1C202C),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
  }

  (String, Color) _statusStyle(String status) {
    switch (status) {
      case 'answered':
      case 'resolved':
      case 'closed':
        return ('답변 완료', const Color(0xFF4C88FF));
      case 'pending':
      default:
        return ('접수 대기', const Color(0xFFED9A3A));
    }
  }
}

class _FeedbackEntry {
  const _FeedbackEntry({
    required this.feedbackId,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.reply,
  });

  final String feedbackId;
  final String message;
  final String status;
  final DateTime createdAt;
  final String reply;

  String get createdAtLabel {
    if (createdAt.millisecondsSinceEpoch == 0) return '방금 전';
    return '${createdAt.year}.${_two(createdAt.month)}.${_two(createdAt.day)} ${_two(createdAt.hour)}:${_two(createdAt.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  factory _FeedbackEntry.fromMap(String id, Map<String, dynamic> data) {
    final message = (data['message'] as String? ?? '').trim();
    final status = (data['status'] as String? ?? 'pending').trim();
    final createdAt = _parseDateTime(data['createdAt']);
    final reply = (data['reply'] as String? ?? '').trim();

    return _FeedbackEntry(
      feedbackId: id,
      message: message.isNotEmpty ? message : '(내용 없음)',
      status: status.isNotEmpty ? status : 'pending',
      createdAt: createdAt,
      reply: reply,
    );
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
}
