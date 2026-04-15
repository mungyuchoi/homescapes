import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../models/app_models.dart';

class CommunityPostRepository {
  CommunityPostRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<CommunityPost> createPost({
    required String category,
    required String contentText,
    required List<File> localImages,
    required List<TodayRootItem> routeItems,
  }) async {
    final userProfile = await _resolveCurrentUserProfile();
    final postRef = _firestore.collection('posts').doc();
    final normalizedCategory = category.trim().isEmpty ? '자유' : category.trim();
    final sanitizedRouteItems = routeItems
        .where(
          (item) =>
              item.spotId.trim().isNotEmpty || item.spotName.trim().isNotEmpty,
        )
        .toList();

    final routeSummary = _buildRouteSummary(sanitizedRouteItems);
    final normalizedContent = contentText.trim().isNotEmpty
        ? contentText.trim()
        : (routeSummary.isNotEmpty ? routeSummary : '(내용 없음)');

    final uploadTargets = localImages
        .where((image) => image.path.trim().isNotEmpty)
        .take(10)
        .toList();
    final uploadedImageUrls = <String>[];
    for (var i = 0; i < uploadTargets.length; i++) {
      final imageUrl = await _uploadPostImage(
        postId: postRef.id,
        imageFile: uploadTargets[i],
        index: i,
      );
      uploadedImageUrls.add(imageUrl);
    }

    final firstRoute = sanitizedRouteItems.isNotEmpty
        ? sanitizedRouteItems.first
        : null;
    final firstSpotName = firstRoute?.spotName.trim() ?? '';
    final firstSpotId = firstRoute?.spotId.trim() ?? '';
    final resolvedFacility = firstSpotName.isNotEmpty
        ? firstSpotName
        : (normalizedCategory == '오늘의 루트' ? '오늘의 루트' : '커뮤니티');

    final now = DateTime.now();
    final postPayload = <String, dynamic>{
      'postId': postRef.id,
      'category': normalizedCategory,
      'tags': [normalizedCategory],
      'author': <String, dynamic>{
        'uid': userProfile.uid,
        'displayName': userProfile.displayName,
        'photoURL': userProfile.photoURL,
      },
      'contentText': normalizedContent,
      'contentHtml': _textToHtml(normalizedContent),
      'images': uploadedImageUrls,
      'thumbnailUrl': uploadedImageUrls.isNotEmpty
          ? uploadedImageUrls.first
          : '',
      'routeItems': sanitizedRouteItems
          .map(
            (item) => <String, dynamic>{
              'spotId': item.spotId,
              'spotName': item.spotName,
              'timeRange': item.timeRange,
              'note': item.note,
            },
          )
          .toList(),
      'spotId': firstSpotId,
      'spotName': firstSpotName,
      'facility': resolvedFacility,
      'likesCount': 0,
      'commentCount': 0,
      'reportsCount': 0,
      'isDeleted': false,
      'isHidden': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAtClient': now.millisecondsSinceEpoch,
    };

    final batch = _firestore.batch();
    batch.set(postRef, postPayload);
    batch.set(
      _firestore
          .collection('users')
          .doc(userProfile.uid)
          .collection('my_posts')
          .doc(postRef.id),
      <String, dynamic>{
        'postId': postRef.id,
        'category': normalizedCategory,
        'contentText': normalizedContent,
        'thumbnailUrl': uploadedImageUrls.isNotEmpty
            ? uploadedImageUrls.first
            : '',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _firestore.collection('users').doc(userProfile.uid),
      <String, dynamic>{
        'postCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    return CommunityPost(
      postId: postRef.id,
      uid: userProfile.uid,
      author: userProfile.displayName,
      photoURL: userProfile.photoURL,
      timeAgo: '방금 전',
      category: normalizedCategory,
      content: normalizedContent,
      spotId: firstSpotId,
      facility: resolvedFacility,
      likes: 0,
      comments: 0,
      routeItems: sanitizedRouteItems,
      imageUrls: uploadedImageUrls,
      createdAt: now,
    );
  }

  Future<CommunityPost> updatePost({
    required String postId,
    required String category,
    required String contentText,
    required List<String> existingImageUrls,
    required List<File> localImages,
    required List<TodayRootItem> routeItems,
  }) async {
    final userProfile = await _resolveCurrentUserProfile();
    final postRef = _firestore.collection('posts').doc(postId);
    final snapshot = await postRef.get();
    if (!snapshot.exists) {
      throw Exception('게시글을 찾을 수 없습니다.');
    }

    final data = snapshot.data() ?? const <String, dynamic>{};
    final author = data['author'];
    final authorUid = author is Map ? (author['uid'] as String? ?? '') : '';
    if (authorUid.trim().isNotEmpty && authorUid.trim() != userProfile.uid) {
      throw Exception('본인 게시글만 수정할 수 있습니다.');
    }

    final normalizedCategory = category.trim().isEmpty ? '자유' : category.trim();
    final sanitizedRouteItems = routeItems
        .where(
          (item) =>
              item.spotId.trim().isNotEmpty || item.spotName.trim().isNotEmpty,
        )
        .toList();
    final routeSummary = _buildRouteSummary(sanitizedRouteItems);
    final normalizedContent = contentText.trim().isNotEmpty
        ? contentText.trim()
        : (routeSummary.isNotEmpty ? routeSummary : '(내용 없음)');

    final retainedImages = existingImageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    final remainSlots = 10 - retainedImages.length;
    final uploadTargets = localImages
        .where((image) => image.path.trim().isNotEmpty)
        .take(remainSlots > 0 ? remainSlots : 0)
        .toList();
    final uploadedImageUrls = <String>[];
    for (var i = 0; i < uploadTargets.length; i++) {
      final imageUrl = await _uploadPostImage(
        postId: postId,
        imageFile: uploadTargets[i],
        index: retainedImages.length + i,
      );
      uploadedImageUrls.add(imageUrl);
    }
    final resolvedImages = <String>[...retainedImages, ...uploadedImageUrls];

    final firstRoute = sanitizedRouteItems.isNotEmpty
        ? sanitizedRouteItems.first
        : null;
    final firstSpotName = firstRoute?.spotName.trim() ?? '';
    final firstSpotId = firstRoute?.spotId.trim() ?? '';
    final resolvedFacility = firstSpotName.isNotEmpty
        ? firstSpotName
        : (normalizedCategory == '오늘의 루트' ? '오늘의 루트' : '커뮤니티');

    final now = DateTime.now();
    await postRef.set({
      'category': normalizedCategory,
      'tags': [normalizedCategory],
      'contentText': normalizedContent,
      'contentHtml': _textToHtml(normalizedContent),
      'images': resolvedImages,
      'thumbnailUrl': resolvedImages.isNotEmpty ? resolvedImages.first : '',
      'routeItems': sanitizedRouteItems
          .map(
            (item) => <String, dynamic>{
              'spotId': item.spotId,
              'spotName': item.spotName,
              'timeRange': item.timeRange,
              'note': item.note,
            },
          )
          .toList(),
      'spotId': firstSpotId,
      'spotName': firstSpotName,
      'facility': resolvedFacility,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtClient': now.millisecondsSinceEpoch,
    }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(userProfile.uid)
        .collection('my_posts')
        .doc(postId)
        .set({
          'category': normalizedCategory,
          'contentText': normalizedContent,
          'thumbnailUrl': resolvedImages.isNotEmpty ? resolvedImages.first : '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    final likesCount = (data['likesCount'] as int?) ?? 0;
    final commentCount = (data['commentCount'] as int?) ?? 0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
    return CommunityPost(
      postId: postId,
      uid: userProfile.uid,
      author: userProfile.displayName,
      photoURL: userProfile.photoURL,
      timeAgo: '방금 전',
      category: normalizedCategory,
      content: normalizedContent,
      spotId: firstSpotId,
      facility: resolvedFacility,
      likes: likesCount,
      comments: commentCount,
      routeItems: sanitizedRouteItems,
      imageUrls: resolvedImages,
      createdAt: createdAt,
    );
  }

  Future<_UserProfile> _resolveCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    var displayName = (user.displayName ?? '').trim();
    var photoURL = (user.photoURL ?? '').trim();
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      final firestoreName = (data?['displayName'] as String? ?? '').trim();
      final firestorePhoto = (data?['photoURL'] as String? ?? '').trim();
      final firestorePhotoLegacy = (data?['photoUrl'] as String? ?? '').trim();
      if (firestoreName.isNotEmpty) displayName = firestoreName;
      if (firestorePhoto.isNotEmpty) {
        photoURL = firestorePhoto;
      } else if (firestorePhotoLegacy.isNotEmpty) {
        photoURL = firestorePhotoLegacy;
      }
    } catch (_) {}

    if (displayName.isEmpty) {
      displayName = (user.email ?? '').split('@').first.trim();
    }
    if (displayName.isEmpty) {
      displayName = '익명';
    }

    return _UserProfile(
      uid: user.uid,
      displayName: displayName,
      photoURL: photoURL,
    );
  }

  Future<String> _uploadPostImage({
    required String postId,
    required File imageFile,
    required int index,
  }) async {
    final fileName = 'img_${index.toString().padLeft(3, '0')}.jpg';
    final ref = _storage.ref().child('posts/$postId/images/$fileName');
    await ref.putFile(
      imageFile,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
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

  String _buildRouteSummary(List<TodayRootItem> routeItems) {
    if (routeItems.isEmpty) return '';
    return routeItems
        .map((item) {
          final spotName = item.spotName.trim().isNotEmpty
              ? item.spotName.trim()
              : item.spotId.trim();
          final timeRange = item.timeRange.trim();
          if (timeRange.isEmpty) return spotName;
          return '$spotName ($timeRange)';
        })
        .where((line) => line.isNotEmpty)
        .join(' > ');
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
  final String photoURL;
}
