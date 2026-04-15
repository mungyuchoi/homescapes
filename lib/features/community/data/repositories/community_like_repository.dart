import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityLikeRepository {
  CommunityLikeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _likeCollection(String postId) {
    return _firestore.collection('posts').doc(postId).collection('likes');
  }

  DocumentReference<Map<String, dynamic>> _postRef(String postId) {
    return _firestore.collection('posts').doc(postId);
  }

  String _toText(dynamic value) {
    if (value is String) return value.trim();
    return '';
  }

  Future<bool> isLiked({
    required String postId,
    required String uid,
  }) async {
    final doc = await _likeCollection(postId).doc(uid).get();
    return doc.exists;
  }

  Stream<bool> watchIsLiked({
    required String postId,
    required String uid,
  }) {
    return _likeCollection(postId).doc(uid).snapshots().map((doc) => doc.exists);
  }

  Future<bool> toggleLike({
    required String postId,
    required String uid,
  }) async {
    final likeRef = _likeCollection(postId).doc(uid);
    final likedPostRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_posts')
        .doc(postId);
    final userRef = _firestore.collection('users').doc(uid);
    final postRef = _postRef(postId);

    return _firestore.runTransaction((tx) async {
      final likeDoc = await tx.get(likeRef);
      final postDoc = await tx.get(postRef);
      if (!postDoc.exists) {
        throw Exception('게시물을 찾을 수 없습니다.');
      }

      final postData = postDoc.data() ?? const <String, dynamic>{};
      final authorMap = postData['author'];
      final authorUid = authorMap is Map
          ? _toText(authorMap['uid'])
          : '';
      final postTitle = _toText(postData['facility']);
      final postThumbnail = _toText(postData['thumbnailUrl']);

      if (likeDoc.exists) {
        tx.delete(likeRef);
        tx.delete(likedPostRef);
        tx.update(postRef, {'likesCount': FieldValue.increment(-1)});
        tx.set(userRef, {'likedPostsCount': FieldValue.increment(-1)}, SetOptions(merge: true));
        if (authorUid.isNotEmpty) {
          tx.set(
            _firestore.collection('users').doc(authorUid),
            {'likesReceived': FieldValue.increment(-1)},
            SetOptions(merge: true),
          );
        }
        return false;
      }

      tx.set(likeRef, {
        'uid': uid,
        'likedAt': FieldValue.serverTimestamp(),
      });
      tx.set(likedPostRef, {
        'postId': postId,
        'title': postTitle,
        'thumbnailUrl': postThumbnail,
        'likedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(postRef, {'likesCount': FieldValue.increment(1)}, SetOptions(merge: true));
      tx.set(userRef, {'likedPostsCount': FieldValue.increment(1)}, SetOptions(merge: true));
      if (authorUid.isNotEmpty) {
        tx.set(
          _firestore.collection('users').doc(authorUid),
          {'likesReceived': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
      return true;
    });
  }
}
