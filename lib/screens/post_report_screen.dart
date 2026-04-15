import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_models.dart';

class PostReportScreen extends StatefulWidget {
  const PostReportScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  State<PostReportScreen> createState() => _PostReportScreenState();
}

class _PostReportScreenState extends State<PostReportScreen> {
  static const List<({String code, String label})> _reasons = [
    (code: 'spam', label: '스팸 콘텐츠가 있어요'),
    (code: 'abusive', label: '불쾌한 표현이 포함되어 있어요'),
    (code: 'violent', label: '폭력적이거나 위협적인 표현이에요'),
    (code: 'other', label: '다른 문제가 있어요'),
  ];

  String? _selectedCode;
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (_isSubmitting || _selectedCode == null) return;

    final reporter = FirebaseAuth.instance.currentUser;
    if (reporter == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 신고할 수 있습니다.')));
      return;
    }

    final reason = _reasons.firstWhere((it) => it.code == _selectedCode);
    final firestore = FirebaseFirestore.instance;
    final reportId = firestore
        .collection('meta')
        .doc('reports')
        .collection('posts')
        .doc()
        .id;

    setState(() => _isSubmitting = true);
    try {
      final batch = firestore.batch();
      final metaReportRef = firestore
          .collection('meta')
          .doc('reports')
          .collection('posts')
          .doc(reportId);
      final userReportRef = firestore
          .collection('users')
          .doc(reporter.uid)
          .collection('reports_posts')
          .doc(reportId);
      final reportPayload = <String, dynamic>{
        'reportId': reportId,
        'targetType': 'post',
        'targetId': widget.post.postId,
        'targetAuthorUid': widget.post.uid,
        'targetAuthorName': widget.post.author,
        'reporterUid': reporter.uid,
        'reasonCode': reason.code,
        'reasonLabel': reason.label,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(metaReportRef, reportPayload);
      batch.set(userReportRef, reportPayload);
      batch.set(
        firestore.collection('posts').doc(widget.post.postId),
        {
          'reportsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('신고 처리 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF121417) : const Color(0xFFF5F6F8);
    final cardBg = isDark ? const Color(0xFF1D222A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2A313D) : const Color(0xFFE1E5EC);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          '게시글 신고하기',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A2020)
                          : const Color(0xFFFFE9E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '신고해 주신 내용은 운영자가 확인 후 필요할 경우 적절한\n조치를 진행할 예정이에요.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: isDark
                            ? const Color(0xFFFFB7B7)
                            : const Color(0xFFE34646),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '신고 유형을 선택해 주세요.',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFE8EDF8)
                          : const Color(0xFF242834),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._reasons.map((reason) {
                    final selected = _selectedCode == reason.code;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCode = reason.code),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? (isDark
                                      ? const Color(0xFF2A3346)
                                      : const Color(0xFFFFF1DF))
                                : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFED9A3A)
                                  : cardBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            reason.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFE2E8F6)
                                  : const Color(0xFF2A2F3C),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_selectedCode == null || _isSubmitting)
                      ? null
                      : _submitReport,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED9A3A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEFC089),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? '신고 중...' : '신고하기',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
