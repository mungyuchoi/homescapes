import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/community_comment_model.dart';

class CommunityCommentRepository {
  CommunityCommentRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _commentCollection(String postId) {
    return _firestore.collection('posts').doc(postId).collection('comments');
  }

  Stream<List<CommunityComment>> streamComments(
    String postId, {
    int limit = 200,
  }) {
    return _commentCollection(postId)
        .where('isDeleted', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snap) {
          return snap.docs.map(CommunityComment.fromFirestore).toList();
        });
  }

  Future<void> addComment({
    required String postId,
    required String uid,
    required String displayName,
    String? photoURL,
    required String contentText,
    String? parentCommentId,
    List<File> localImages = const [],
  }) async {
    final trimmedText = contentText.trim();
    final normalizedParentId = (parentCommentId ?? '').trim();
    final commentRef = _commentCollection(postId).doc();
    final postRef = _firestore.collection('posts').doc(postId);

    var depth = 0;
    String? resolvedParentId;
    if (normalizedParentId.isNotEmpty) {
      final parentDoc = await _commentCollection(
        postId,
      ).doc(normalizedParentId).get();
      if (parentDoc.exists) {
        final parentDepth = (parentDoc.data()?['depth'] as int?) ?? 0;
        depth = (parentDepth + 1).clamp(1, 2);
        resolvedParentId = normalizedParentId;
      }
    }

    final uploadTargets = localImages
        .where((image) => image.path.trim().isNotEmpty)
        .toList();
    final uploadedImageUrls = <String>[];
    for (var i = 0; i < uploadTargets.length; i++) {
      final url = await _uploadCommentImage(
        postId: postId,
        commentId: commentRef.id,
        imageFile: uploadTargets[i],
        index: i,
      );
      uploadedImageUrls.add(url);
    }

    var contentHtml = _textToHtml(trimmedText);
    for (final url in uploadedImageUrls) {
      contentHtml = '$contentHtml<br/><img src="$url" />';
    }

    final batch = _firestore.batch();
    batch.set(commentRef, {
      'commentId': commentRef.id,
      'postId': postId,
      'author': {'uid': uid, 'displayName': displayName, 'photoURL': photoURL},
      'contentText': trimmedText,
      'contentHtml': contentHtml,
      'imageUrls': uploadedImageUrls,
      'parentCommentId': resolvedParentId,
      'depth': depth,
      'likesCount': 0,
      'reportsCount': 0,
      'isDeleted': false,
      'isHidden': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(postRef, {
      'postId': postId,
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('my_comments')
          .doc(commentRef.id),
      {
        'commentId': commentRef.id,
        'postId': postId,
        'contentText': trimmedText,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(_firestore.collection('users').doc(uid), {
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String uid,
    required String contentText,
  }) async {
    final commentRef = _commentCollection(postId).doc(commentId);
    final doc = await commentRef.get();
    if (!doc.exists) {
      throw Exception('댓글을 찾을 수 없습니다.');
    }

    final data = doc.data() ?? const <String, dynamic>{};
    final author =
        (data['author'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final authorUid = (author['uid'] as String? ?? '').trim();
    if (authorUid.isEmpty || authorUid != uid) {
      throw Exception('본인 댓글만 수정할 수 있습니다.');
    }

    final trimmedText = contentText.trim();
    final hasImages =
        (data['imageUrls'] as List<dynamic>? ?? const []).isNotEmpty;
    if (trimmedText.isEmpty && !hasImages) {
      throw Exception('내용을 입력해 주세요.');
    }

    await commentRef.set({
      'contentText': trimmedText,
      'contentHtml': _textToHtml(trimmedText),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> softDeleteComment({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final commentRef = _commentCollection(postId).doc(commentId);
    final doc = await commentRef.get();
    if (!doc.exists) {
      throw Exception('댓글을 찾을 수 없습니다.');
    }

    final data = doc.data() ?? const <String, dynamic>{};
    final author =
        (data['author'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final authorUid = (author['uid'] as String? ?? '').trim();
    if (authorUid.isEmpty || authorUid != uid) {
      throw Exception('본인 댓글만 삭제할 수 있습니다.');
    }

    final alreadyDeleted = (data['isDeleted'] as bool?) ?? false;
    if (alreadyDeleted) {
      return;
    }

    final batch = _firestore.batch();
    batch.set(commentRef, {
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('posts').doc(postId), {
      'commentCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('users').doc(uid), {
      'commentCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> reportComment({
    required String postId,
    required String commentId,
    required String targetAuthorUid,
    required String targetAuthorName,
    required String reporterUid,
    required String reasonCode,
    required String reasonLabel,
  }) async {
    final reportId = _firestore
        .collection('meta')
        .doc('reports')
        .collection('comments')
        .doc()
        .id;

    final payload = <String, dynamic>{
      'reportId': reportId,
      'targetType': 'comment',
      'targetId': commentId,
      'targetPostId': postId,
      'targetAuthorUid': targetAuthorUid,
      'targetAuthorName': targetAuthorName,
      'reporterUid': reporterUid,
      'reasonCode': reasonCode,
      'reasonLabel': reasonLabel,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection('meta')
          .doc('reports')
          .collection('comments')
          .doc(reportId),
      payload,
    );
    batch.set(
      _firestore
          .collection('users')
          .doc(reporterUid)
          .collection('reports_comments')
          .doc(reportId),
      payload,
    );
    batch.set(_commentCollection(postId).doc(commentId), {
      'reportsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<String> _uploadCommentImage({
    required String postId,
    required String commentId,
    required File imageFile,
    required int index,
  }) async {
    final fileName = 'img_${index.toString().padLeft(3, '0')}.jpg';
    final ref = _storage.ref().child(
      'posts/$postId/comments/$commentId/images/$fileName',
    );
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public, max-age=31536000',
    );
    await ref.putFile(imageFile, metadata);
    return ref.getDownloadURL();
  }

  String _textToHtml(String text) {
    final escaped = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('\n', '<br/>');
    return '<p>$escaped</p>';
  }
}
