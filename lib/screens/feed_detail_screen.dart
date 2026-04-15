import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/community/data/models/community_comment_model.dart';
import '../features/community/data/repositories/community_comment_repository.dart';
import '../features/community/data/repositories/community_like_repository.dart';
import '../features/profile/data/repositories/follow_repository.dart';
import '../models/app_models.dart';
import '../utils/user_access_utils.dart';
import '../widgets/common_widgets.dart';
import 'post_create_screen.dart';
import 'post_report_screen.dart';
import 'user_screen.dart';

class FeedDetailScreen extends StatefulWidget {
  const FeedDetailScreen({
    super.key,
    required this.post,
    required this.categories,
    required this.spotOptions,
    required this.todaySlotsDoc,
  });

  final CommunityPost post;
  final List<String> categories;
  final List<SpotDoc> spotOptions;
  final DayFacilitySlotsDoc todaySlotsDoc;

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  static const List<({String code, String label})> _commentReportReasons = [
    (code: 'spam', label: '스팸 콘텐츠가 있어요'),
    (code: 'abusive', label: '불쾌한 표현이 포함되어 있어요'),
    (code: 'violent', label: '폭력적이거나 위협적인 표현이에요'),
    (code: 'other', label: '다른 문제가 있어요'),
  ];

  final CommunityCommentRepository _commentRepository =
      CommunityCommentRepository();
  final CommunityLikeRepository _communityLikeRepository =
      CommunityLikeRepository();
  final FollowRepository _followRepository = FollowRepository();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  final List<File> _selectedImages = <File>[];
  bool _isSubmitting = false;
  bool _isPickingImage = false;
  bool _isBlockingUser = false;
  bool _isReportingComment = false;
  String? _replyingToCommentId;
  CommunityComment? _replyingToComment;
  String? _editingCommentId;
  CommunityComment? _editingComment;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _ensureCanWrite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 먼저 해주세요.')));
      return false;
    }
    final isRestricted = await UserAccessUtils.isCurrentUserRestricted();
    if (!isRestricted) return true;
    if (!mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이용금지된 회원입니다. 관리자에게 문의하세요.')));
    return false;
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (_isSubmitting) {
      return;
    }
    if (!await _ensureCanWrite()) return;

    final userProfile = await _resolveCurrentUserProfile();
    if (userProfile == null) {
      await _ensureCanWrite();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_editingCommentId != null) {
        final editingComment = _editingComment;
        final hasExistingImages = editingComment?.imageUrls.isNotEmpty ?? false;
        if (text.isEmpty && !hasExistingImages) {
          throw Exception('내용을 입력해 주세요.');
        }
        await _commentRepository.updateComment(
          postId: widget.post.postId,
          commentId: _editingCommentId!,
          uid: userProfile.uid,
          contentText: text,
        );
      } else {
        if (text.isEmpty && _selectedImages.isEmpty) {
          return;
        }
        await _commentRepository.addComment(
          postId: widget.post.postId,
          uid: userProfile.uid,
          displayName: userProfile.displayName,
          photoURL: userProfile.photoURL,
          contentText: text,
          parentCommentId: _replyingToCommentId,
          localImages: List<File>.from(_selectedImages),
        );
      }
      if (!mounted) return;
      _commentController.clear();
      _selectedImages.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToComment = null;
        _editingCommentId = null;
        _editingComment = null;
      });
      _commentFocusNode.unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('댓글 등록 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<_UserProfile?> _resolveCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    var displayName = (user.displayName ?? '').trim();
    var photoURL = (user.photoURL ?? '').trim();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final firestoreName = (data?['displayName'] as String? ?? '').trim();
      final firestorePhoto = (data?['photoURL'] as String? ?? '').trim();

      if (firestoreName.isNotEmpty) displayName = firestoreName;
      if (firestorePhoto.isNotEmpty) photoURL = firestorePhoto;
    } catch (error) {
      debugPrint('Failed to resolve profile from Firestore: $error');
    }
    if (displayName.isEmpty) {
      displayName = (user.email ?? '').split('@').first.trim();
    }
    if (displayName.isEmpty) {
      displayName = '익명';
    }

    return _UserProfile(
      uid: user.uid,
      displayName: displayName,
      photoURL: photoURL.isEmpty ? null : photoURL,
    );
  }

  Future<void> _pickCommentImages() async {
    if (!await _ensureCanWrite()) return;
    if (_isPickingImage || _selectedImages.length >= 5) {
      if (_selectedImages.length >= 5 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지는 최대 5개까지 추가할 수 있습니다.')),
        );
      }
      return;
    }

    setState(() => _isPickingImage = true);
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;

      final remaining = 5 - _selectedImages.length;
      final files = picked.take(remaining).map((item) => File(item.path));
      setState(() => _selectedImages.addAll(files));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 선택 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  List<String> _extractPostImageUrls(Map<String, dynamic>? data) {
    if (data == null) return const <String>[];
    final imageUrls = (data['images'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    return imageUrls;
  }

  Future<void> _startReply(CommunityComment comment) async {
    if (!await _ensureCanWrite()) return;
    setState(() {
      _replyingToCommentId = comment.commentId;
      _replyingToComment = comment;
      _editingCommentId = null;
      _editingComment = null;
    });
    _commentFocusNode.requestFocus();
  }

  void _startEditComment(CommunityComment comment) {
    setState(() {
      _editingCommentId = comment.commentId;
      _editingComment = comment;
      _replyingToCommentId = null;
      _replyingToComment = null;
      _selectedImages.clear();
    });
    _commentController.text = comment.contentText;
    _commentFocusNode.requestFocus();
  }

  Future<void> _togglePostLike() async {
    if (!await _ensureCanWrite()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    try {
      await _communityLikeRepository.toggleLike(
        postId: widget.post.postId,
        uid: uid,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('좋아요 처리 실패: $e')));
    }
  }

  Future<void> _toggleFollowAuthor() async {
    if (!await _ensureCanWrite()) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final targetUid = widget.post.uid.trim();
    if (myUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 이용해주세요.')));
      return;
    }
    if (targetUid.isEmpty || myUid == targetUid) return;

    try {
      await _followRepository.toggleFollow(myUid: myUid, targetUid: targetUid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('팔로우 처리 실패: $e')));
    }
  }

  Future<void> _openPostActionSheet() async {
    if (!await _ensureCanWrite()) return;
    final isMyPost = FirebaseAuth.instance.currentUser?.uid == widget.post.uid;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C212A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3E4658)
                        : const Color(0xFFD9DEE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    isMyPost ? Icons.edit_outlined : Icons.person_off_outlined,
                  ),
                  title: Text(isMyPost ? '편집하기' : '차단'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (isMyPost) {
                      await _openEditPostScreen();
                    } else {
                      await _showBlockUserDialog(
                        targetUid: widget.post.uid,
                        authorName: widget.post.author,
                      );
                    }
                  },
                ),
                if (isMyPost)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('삭제하기'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _showDeletePostDialog();
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.report_gmailerrorred_rounded),
                    title: const Text('신고'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await Navigator.of(this.context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PostReportScreen(post: widget.post),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCommentActionSheet(CommunityComment comment) async {
    if (!await _ensureCanWrite()) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return;
    }
    final isMyComment = comment.author.uid == currentUid;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C212A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3E4658)
                        : const Color(0xFFD9DEE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    isMyComment
                        ? Icons.edit_outlined
                        : Icons.person_off_outlined,
                  ),
                  title: Text(isMyComment ? '편집하기' : '차단'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (isMyComment) {
                      _startEditComment(comment);
                    } else {
                      await _showBlockUserDialog(
                        targetUid: comment.author.uid,
                        authorName: comment.author.displayName,
                        blockedCommentId: comment.commentId,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    isMyComment
                        ? Icons.delete_outline_rounded
                        : Icons.report_gmailerrorred_rounded,
                  ),
                  title: Text(isMyComment ? '삭제하기' : '신고'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    if (isMyComment) {
                      await _showDeleteCommentDialog(comment);
                    } else {
                      await _showCommentReportSheet(comment);
                    }
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditPostScreen() async {
    final updated = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute<CommunityPost>(
        builder: (_) => PostCreateScreen(
          initialCategory: widget.post.category,
          categories: widget.categories,
          spotOptions: widget.spotOptions,
          todaySlotsDoc: widget.todaySlotsDoc,
          editingPost: widget.post,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('게시글이 수정되었습니다.')));
    Navigator.of(context).pop(true);
  }

  Future<void> _openUserScreenByUid(String uid) async {
    final targetUid = uid.trim();
    if (targetUid.isEmpty) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => UserScreen(uid: targetUid)));
  }

  Future<void> _openUserScreen() async {
    await _openUserScreenByUid(widget.post.uid);
  }

  Future<void> _showDeletePostDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('정말로 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final deleted = await _softDeletePost();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (deleted && mounted) {
                  Navigator.of(this.context).pop(true);
                }
              },
              child: const Text(
                '삭제하기',
                style: TextStyle(color: Color(0xFFE24D4D)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _softDeletePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 이용해주세요.')));
      return false;
    }
    if (currentUser.uid != widget.post.uid) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('본인 게시글만 삭제할 수 있습니다.')));
      return false;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final postRef = firestore.collection('posts').doc(widget.post.postId);
      final myPostRef = firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('my_posts')
          .doc(widget.post.postId);
      batch.set(postRef, {
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(myPostRef, {
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();

      if (!mounted) return true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 처리 실패: $e')));
      return false;
    }
  }

  Future<void> _showDeleteCommentDialog(CommunityComment comment) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('댓글 삭제'),
          content: const Text('정말로 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final deleted = await _softDeleteComment(comment);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (!deleted || !mounted) return;
                if (_editingCommentId == comment.commentId) {
                  setState(() {
                    _editingCommentId = null;
                    _editingComment = null;
                  });
                  _commentController.clear();
                }
              },
              child: const Text(
                '삭제하기',
                style: TextStyle(color: Color(0xFFE24D4D)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _softDeleteComment(CommunityComment comment) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 이용해주세요.')));
      return false;
    }

    try {
      await _commentRepository.softDeleteComment(
        postId: widget.post.postId,
        commentId: comment.commentId,
        uid: currentUser.uid,
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('댓글이 삭제되었습니다.')));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('댓글 삭제 실패: $e')));
      return false;
    }
  }

  Future<void> _showBlockUserDialog({
    required String targetUid,
    required String authorName,
    String? blockedCommentId,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      barrierDismissible: !_isBlockingUser,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1C212A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(42),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: Color(0xFFF25E5E),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '해당 사용자를 차단할까요?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? const Color(0xFFEAF0FC)
                        : const Color(0xFF242832),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '사용자의 모든 게시글과 댓글이 즉시 가려지며,\n[설정 > 차단 내역 관리]에서 해제할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFFAAB4C6)
                        : const Color(0xFF6F7687),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isBlockingUser
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE3E7EE),
                          foregroundColor: const Color(0xFF646E80),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isBlockingUser
                            ? null
                            : () async {
                                final blocked = await _blockUser(
                                  targetUid: targetUid,
                                  authorName: authorName,
                                  blockedCommentId: blockedCommentId,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                if (blocked && mounted) {
                                  Navigator.of(this.context).pop(true);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3D3D),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                          _isBlockingUser ? '처리중...' : '차단하기',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _blockUser({
    required String targetUid,
    required String authorName,
    String? blockedCommentId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 이용해주세요.')));
      return false;
    }

    final normalizedTargetUid = targetUid.trim();
    if (normalizedTargetUid.isEmpty) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('차단할 사용자 정보가 없습니다.')));
      return false;
    }
    if (normalizedTargetUid == currentUser.uid) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('본인은 차단할 수 없습니다.')));
      return false;
    }

    setState(() => _isBlockingUser = true);
    try {
      final blockedUsersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('blocked_users');
      final docRef = blockedUsersRef.doc(normalizedTargetUid);

      final existing = await docRef.get();
      if (!existing.exists) {
        final blockedSnapshot = await blockedUsersRef.limit(4).get();
        if (blockedSnapshot.docs.length >= 3) {
          if (!mounted) return false;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('차단은 최대 3명까지 가능합니다.')));
          return false;
        }
      }

      await docRef.set({
        'blockedUid': normalizedTargetUid,
        'blockedCommentId': blockedCommentId,
        'blockedPostId': widget.post.postId,
        'blockedAuthor': authorName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('차단되었습니다.')));
      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('차단 처리 실패: $e')));
      return false;
    } finally {
      if (mounted) {
        setState(() => _isBlockingUser = false);
      }
    }
  }

  Future<void> _showCommentReportSheet(CommunityComment comment) async {
    var selectedCode = _commentReportReasons.first.code;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C212A) : Colors.white,
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
                          color: isDark
                              ? const Color(0xFF3E4658)
                              : const Color(0xFFD9DEE8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '댓글 신고하기',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._commentReportReasons.map((reason) {
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
                                  ? (isDark
                                        ? const Color(0xFF2A3346)
                                        : const Color(0xFFFFF1DF))
                                  : (isDark
                                        ? const Color(0xFF242A36)
                                        : const Color(0xFFF7F9FC)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFED9A3A)
                                    : (isDark
                                          ? const Color(0xFF353F51)
                                          : const Color(0xFFE2E7EF)),
                              ),
                            ),
                            child: Text(
                              reason.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFE5EBF7)
                                    : const Color(0xFF283043),
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
                        onPressed: _isReportingComment
                            ? null
                            : () async {
                                final reason = _commentReportReasons.firstWhere(
                                  (it) => it.code == selectedCode,
                                );
                                await _submitCommentReport(
                                  comment: comment,
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
                        child: Text(_isReportingComment ? '신고 중...' : '신고하기'),
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

  Future<void> _submitCommentReport({
    required CommunityComment comment,
    required String reasonCode,
    required String reasonLabel,
  }) async {
    final reporter = FirebaseAuth.instance.currentUser;
    if (reporter == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 후 신고할 수 있습니다.')));
      return;
    }
    if (comment.author.uid == reporter.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('본인 댓글은 신고할 수 없습니다.')));
      return;
    }
    if (comment.author.uid.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('신고할 사용자 정보가 없습니다.')));
      return;
    }

    setState(() => _isReportingComment = true);
    try {
      await _commentRepository.reportComment(
        postId: widget.post.postId,
        commentId: comment.commentId,
        targetAuthorUid: comment.author.uid,
        targetAuthorName: comment.author.displayName,
        reporterUid: reporter.uid,
        reasonCode: reasonCode,
        reasonLabel: reasonLabel,
      );
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
        setState(() => _isReportingComment = false);
      }
    }
  }

  String _formatRelativeTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '${time.year}.$month.$day';
  }

  Future<void> _openImageViewer({
    required List<String> imageUrls,
    required int initialIndex,
  }) async {
    if (imageUrls.isEmpty) return;

    final pageController = PageController(initialPage: initialIndex);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) {
        return Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 32,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final isSignedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          '뒤로가기',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _openPostActionSheet,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<CommunityComment>>(
        stream: _commentRepository.streamComments(widget.post.postId),
        builder: (context, commentSnapshot) {
          final comments = commentSnapshot.data ?? const <CommunityComment>[];
          final commentById = <String, CommunityComment>{
            for (final comment in comments) comment.commentId: comment,
          };
          final rootComments = <CommunityComment>[];
          final childrenByParent = <String, List<CommunityComment>>{};

          for (final comment in comments) {
            final parentId = (comment.parentCommentId ?? '').trim();
            if (parentId.isEmpty || !commentById.containsKey(parentId)) {
              rootComments.add(comment);
              continue;
            }
            childrenByParent
                .putIfAbsent(parentId, () => <CommunityComment>[])
                .add(comment);
          }

          int byCreatedAt(CommunityComment a, CommunityComment b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aTime.compareTo(bTime);
          }

          rootComments.sort(byCreatedAt);
          for (final childList in childrenByParent.values) {
            childList.sort(byCreatedAt);
          }

          final orderedComments = <({CommunityComment comment, int depth})>[];

          void addCommentTree(CommunityComment comment, int depth) {
            orderedComments.add((comment: comment, depth: depth));
            final children =
                childrenByParent[comment.commentId] ??
                const <CommunityComment>[];
            for (final child in children) {
              addCommentTree(child, depth + 1);
            }
          }

          for (final root in rootComments) {
            addCommentTree(root, 0);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.post.postId)
                    .snapshots(),
                builder: (context, postSnapshot) {
                  final postData = postSnapshot.data?.data();
                  final postImageUrls = _extractPostImageUrls(postData);
                  final firestoreLikeCount = postData?['likesCount'] as int?;
                  final currentUid = FirebaseAuth.instance.currentUser?.uid;
                  final hasAuthorUid = widget.post.uid.trim().isNotEmpty;
                  final isMyPost =
                      hasAuthorUid &&
                      currentUid != null &&
                      currentUid == widget.post.uid;
                  if (currentUid == null) {
                    return PostCard(
                      post: widget.post,
                      showFollowButton: false,
                      onAuthorTap: _openUserScreen,
                      onRouteItemTap: (_) {},
                      onImageTap: (index) => _openImageViewer(
                        imageUrls: postImageUrls,
                        initialIndex: index,
                      ),
                      likeCountOverride:
                          firestoreLikeCount ?? widget.post.likes,
                      commentCountOverride: comments.length,
                      imageUrls: postImageUrls,
                    );
                  }
                  if (isMyPost) {
                    return StreamBuilder<bool>(
                      stream: _communityLikeRepository.watchIsLiked(
                        postId: widget.post.postId,
                        uid: currentUid,
                      ),
                      builder: (context, likeSnapshot) {
                        return PostCard(
                          post: widget.post,
                          showFollowButton: false,
                          onAuthorTap: _openUserScreen,
                          onRouteItemTap: (_) {},
                          onLike: _togglePostLike,
                          onImageTap: (index) => _openImageViewer(
                            imageUrls: postImageUrls,
                            initialIndex: index,
                          ),
                          isLiked: likeSnapshot.data ?? false,
                          likeCountOverride:
                              firestoreLikeCount ?? widget.post.likes,
                          commentCountOverride: comments.length,
                          imageUrls: postImageUrls,
                        );
                      },
                    );
                  }
                  return StreamBuilder<bool>(
                    stream: _followRepository.watchIsFollowing(
                      myUid: currentUid,
                      targetUid: widget.post.uid,
                    ),
                    builder: (context, followSnapshot) {
                      return StreamBuilder<bool>(
                        stream: _communityLikeRepository.watchIsLiked(
                          postId: widget.post.postId,
                          uid: currentUid,
                        ),
                        builder: (context, likeSnapshot) {
                          return PostCard(
                            post: widget.post,
                            onFollow: _toggleFollowAuthor,
                            showFollowButton: hasAuthorUid,
                            isFollowing: followSnapshot.data ?? false,
                            onAuthorTap: _openUserScreen,
                            onRouteItemTap: (_) {},
                            onLike: _togglePostLike,
                            onImageTap: (index) => _openImageViewer(
                              imageUrls: postImageUrls,
                              initialIndex: index,
                            ),
                            isLiked: likeSnapshot.data ?? false,
                            likeCountOverride:
                                firestoreLikeCount ?? widget.post.likes,
                            commentCountOverride: comments.length,
                            imageUrls: postImageUrls,
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                '댓글 ${comments.length}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFE6ECF6)
                      : const Color(0xFF1D2130),
                ),
              ),
              const SizedBox(height: 10),
              if (commentSnapshot.connectionState == ConnectionState.waiting &&
                  !commentSnapshot.hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (commentSnapshot.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    '댓글을 불러오지 못했습니다: ${commentSnapshot.error}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7A8190),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (comments.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 44),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C212A)
                        : const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        size: 84,
                        color: isDark
                            ? const Color(0xFF707B90)
                            : const Color(0xFFB2B9C6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '첫 댓글을 남겨주세요.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF97A3BA)
                              : const Color(0xFF8A93A6),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...orderedComments.map((entry) {
                  final comment = entry.comment;
                  final leftPadding = (entry.depth * 20).toDouble();
                  return Padding(
                    padding: EdgeInsets.only(left: leftPadding),
                    child: _CommentTile(
                      comment: comment,
                      timeText: _formatRelativeTime(comment.createdAt),
                      onAuthorTap: () =>
                          _openUserScreenByUid(comment.author.uid),
                      onReplyTap: () => _startReply(comment),
                      onMoreTap: () => _openCommentActionSheet(comment),
                      onImageTap: (index) {
                        _openImageViewer(
                          imageUrls: comment.imageUrls,
                          initialIndex: index,
                        );
                      },
                    ),
                  );
                }),
            ],
          );
        },
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B24) : const Color(0xFFF5F7FB),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E3544)
                      : const Color(0xFFE3E7EE),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_editingComment != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A313D)
                          : const Color(0xFFE7ECF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_editingComment!.author.displayName}님 댓글 편집 중',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFDDE5F5)
                                  : const Color(0xFF4D566B),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _editingComment = null;
                              _editingCommentId = null;
                            });
                            _commentController.clear();
                          },
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                if (_replyingToComment != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A313D)
                          : const Color(0xFFE7ECF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_replyingToComment!.author.displayName}님에게 답글 작성 중',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFDDE5F5)
                                  : const Color(0xFF4D566B),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _replyingToComment = null;
                              _replyingToCommentId = null;
                            });
                          },
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 62,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final file = _selectedImages[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                file,
                                width: 62,
                                height: 62,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(
                                    () => _selectedImages.removeAt(index),
                                  );
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                if (_selectedImages.isNotEmpty) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252B36)
                              : const Color(0xFFE6EAF2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed:
                                  (_isPickingImage || _editingComment != null)
                                  ? null
                                  : _pickCommentImages,
                              icon: Icon(
                                Icons.photo_library_outlined,
                                color: isDark
                                    ? const Color(0xFFB4BED2)
                                    : const Color(0xFF7D8798),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocusNode,
                                minLines: 1,
                                maxLines: 3,
                                readOnly: !isSignedIn,
                                onTap: () async {
                                  if (!isSignedIn) {
                                    await _ensureCanWrite();
                                    return;
                                  }
                                  final allowed = await _ensureCanWrite();
                                  if (!allowed && mounted) {
                                    _commentFocusNode.unfocus();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: _replyingToComment == null
                                      ? (_editingComment == null
                                            ? '댓글을 입력해 주세요.'
                                            : '댓글을 수정해 주세요.')
                                      : '답글을 입력해 주세요.',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: _isSubmitting
                                    ? (isDark
                                          ? const Color(0xFF434C61)
                                          : const Color(0xFFC2C7D1))
                                    : const Color(0xFFAEB5C4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _submitComment,
                                icon: Icon(
                                  _editingComment == null
                                      ? Icons.arrow_upward_rounded
                                      : Icons.check_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.timeText,
    required this.onAuthorTap,
    required this.onReplyTap,
    required this.onMoreTap,
    required this.onImageTap,
  });

  final CommunityComment comment;
  final String timeText;
  final VoidCallback onAuthorTap;
  final VoidCallback onReplyTap;
  final VoidCallback onMoreTap;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authorName = comment.author.displayName.isEmpty
        ? '익명'
        : comment.author.displayName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C212A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A313D) : const Color(0xFFE6EAF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onAuthorTap,
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: comment.author.photoURL != null
                      ? NetworkImage(comment.author.photoURL!)
                      : null,
                  child: comment.author.photoURL == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onAuthorTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFEBF0F9)
                              : const Color(0xFF1F2533),
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF9AA6BF)
                                : const Color(0xFF8691A5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onMoreTap,
                icon: const Icon(Icons.more_horiz_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
              ),
              TextButton(onPressed: onReplyTap, child: const Text('답글')),
            ],
          ),
          if (comment.contentText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment.contentText,
              style: TextStyle(
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFDCE3F0)
                    : const Color(0xFF3A4153),
              ),
            ),
          ],
          if (comment.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: comment.imageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final imageUrl = comment.imageUrls[index];
                  return GestureDetector(
                    onTap: () => onImageTap(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 88,
                          height: 88,
                          color: isDark
                              ? const Color(0xFF2A313D)
                              : const Color(0xFFE6EAF2),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserProfile {
  const _UserProfile({
    required this.uid,
    required this.displayName,
    required this.photoURL,
  });

  final String uid;
  final String displayName;
  final String? photoURL;
}
