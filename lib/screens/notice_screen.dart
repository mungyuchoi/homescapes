import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final Set<String> _expandedIds = <String>{};
  bool _isAdmin = false;

  CollectionReference<Map<String, dynamic>> get _noticeCollection =>
      FirebaseFirestore.instance.collection('meta').doc('notice').collection('notices');

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
  }

  Future<void> _loadAdminRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snapshot.data();
      final roles = data?['roles'];
      var isAdmin = false;

      if (roles is List) {
        isAdmin = roles.any((role) => role.toString() == 'admin');
      } else if (roles is Map) {
        isAdmin = roles['admin'] == true;
      } else if (roles is String) {
        isAdmin = roles == 'admin';
      }

      if (!mounted) return;
      setState(() => _isAdmin = isAdmin);
    } catch (_) {}
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--.--.--';
    final yy = (dateTime.year % 100).toString().padLeft(2, '0');
    final mm = dateTime.month.toString().padLeft(2, '0');
    final dd = dateTime.day.toString().padLeft(2, '0');
    return '$yy.$mm.$dd';
  }

  Future<void> _openCreateNoticeSheet() async {
    final titleController = TextEditingController();
    final descriptionHtmlController = TextEditingController();
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '공지사항 작성',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1D27),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionHtmlController,
                      minLines: 8,
                      maxLines: 14,
                      decoration: const InputDecoration(
                        labelText: 'descriptionHtml',
                        hintText: '<p>공지 본문...</p>',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final descriptionHtml = descriptionHtmlController.text.trim();
                                if (title.isEmpty || descriptionHtml.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('제목과 descriptionHtml을 입력해 주세요.')),
                                  );
                                  return;
                                }

                                setLocalState(() => isSaving = true);
                                try {
                                  final uid = FirebaseAuth.instance.currentUser?.uid;
                                  await _noticeCollection.add({
                                    'title': title,
                                    'descriptionHtml': descriptionHtml,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'createdByUid': uid,
                                  });
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('공지사항이 등록되었습니다.')),
                                  );
                                } finally {
                                  if (mounted) {
                                    setLocalState(() => isSaving = false);
                                  }
                                }
                              },
                        child: Text(isSaving ? '등록 중...' : '등록'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF1F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1D27)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: Color(0xFF1A1D27),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (_isAdmin)
            TextButton.icon(
              onPressed: _openCreateNoticeSheet,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('작성'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _noticeCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active &&
              snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                '공지사항을 불러오지 못했습니다.',
                style: TextStyle(
                  color: Color(0xFF6F7683),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final notices =
              (snapshot.data?.docs ?? const []).map(_NoticeItem.fromDoc).toList();
          if (notices.isEmpty) {
            return const Center(
              child: Text(
                '등록된 공지사항이 없습니다.',
                style: TextStyle(
                  color: Color(0xFF7E8492),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notice = notices[index];
              final expanded = _expandedIds.contains(notice.id);

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.title,
                            style: const TextStyle(
                              color: Color(0xFF1C1F28),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(notice.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF8C93A0),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (expanded && notice.descriptionHtml.trim().isNotEmpty) ...[
                            const SizedBox(height: 18),
                            HtmlWidget(
                              notice.descriptionHtml,
                              textStyle: const TextStyle(
                                color: Color(0xFF252934),
                                height: 1.5,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE1E4EA),
                    ),
                    InkWell(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      onTap: () {
                        setState(() {
                          if (expanded) {
                            _expandedIds.remove(notice.id);
                          } else {
                            _expandedIds.add(notice.id);
                          }
                        });
                      },
                      child: SizedBox(
                        height: 62,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                expanded ? '접기' : '펼치기',
                                style: const TextStyle(
                                  color: Color(0xFF8C93A0),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF8C93A0),
                                size: 28,
                              ),
                            ],
                          ),
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
}

class _NoticeItem {
  const _NoticeItem({
    required this.id,
    required this.title,
    required this.descriptionHtml,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String descriptionHtml;
  final DateTime? createdAt;

  factory _NoticeItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return _NoticeItem(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : '제목 없음',
      descriptionHtml: _resolveDescriptionHtml(data),
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  static String _resolveDescriptionHtml(Map<String, dynamic> data) {
    final html = (data['descriptionHtml'] as String?)?.trim();
    if (html != null && html.isNotEmpty) return html;
    final plain = (data['description'] as String?)?.trim() ?? '';
    if (plain.isEmpty) return '';
    return '<p>${plain.replaceAll('\n', '<br/>')}</p>';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
