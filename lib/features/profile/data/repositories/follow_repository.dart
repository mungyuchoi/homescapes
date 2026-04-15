import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowUserItem {
  const FollowUserItem({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.bio,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final String bio;
}

class FollowRepository {
  FollowRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _followingOf(String uid) {
    return _firestore.collection('users').doc(uid).collection('following');
  }

  CollectionReference<Map<String, dynamic>> _followersOf(String uid) {
    return _firestore.collection('users').doc(uid).collection('followers');
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  String? get currentUid => _auth.currentUser?.uid;

  Stream<bool> watchIsFollowing({
    required String myUid,
    required String targetUid,
  }) {
    if (myUid.trim().isEmpty || targetUid.trim().isEmpty) {
      return const Stream<bool>.empty();
    }
    return _followingOf(myUid)
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<bool> isFollowing({
    required String myUid,
    required String targetUid,
  }) async {
    if (myUid.trim().isEmpty || targetUid.trim().isEmpty) return false;
    final doc = await _followingOf(myUid).doc(targetUid).get();
    return doc.exists;
  }

  Future<int> getFollowerCount(String uid) async {
    final snapshot = await _followersOf(uid).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getFollowingCount(String uid) async {
    final snapshot = await _followingOf(uid).count().get();
    return snapshot.count ?? 0;
  }

  Future<void> toggleFollow({
    required String myUid,
    required String targetUid,
  }) async {
    final normalizedMyUid = myUid.trim();
    final normalizedTargetUid = targetUid.trim();
    if (normalizedMyUid.isEmpty || normalizedTargetUid.isEmpty) return;
    if (normalizedMyUid == normalizedTargetUid) return;

    final followingRef = _followingOf(normalizedMyUid).doc(normalizedTargetUid);
    final followerRef = _followersOf(normalizedTargetUid).doc(normalizedMyUid);
    final followingDoc = await followingRef.get();

    if (followingDoc.exists) {
      final batch = _firestore.batch();
      batch.delete(followingRef);
      batch.delete(followerRef);
      await batch.commit();
      return;
    }

    final myProfile = await _userRef(normalizedMyUid).get();
    final targetProfile = await _userRef(normalizedTargetUid).get();
    final myData = myProfile.data() ?? const <String, dynamic>{};
    final targetData = targetProfile.data() ?? const <String, dynamic>{};
    final createdAt = FieldValue.serverTimestamp();

    final batch = _firestore.batch();
    batch.set(followingRef, {
      'uid': normalizedTargetUid,
      'displayName': (targetData['displayName'] as String? ?? '').trim(),
      'photoURL': (targetData['photoURL'] as String? ?? '').trim(),
      'bio': (targetData['bio'] as String? ?? '').trim(),
      'createdAt': createdAt,
    });
    batch.set(followerRef, {
      'uid': normalizedMyUid,
      'displayName': (myData['displayName'] as String? ?? '').trim(),
      'photoURL': (myData['photoURL'] as String? ?? '').trim(),
      'bio': (myData['bio'] as String? ?? '').trim(),
      'createdAt': createdAt,
    });
    await batch.commit();
  }

  Future<List<FollowUserItem>> getFollowers(String uid) async {
    final snapshot = await _followersOf(uid).orderBy('createdAt').get();
    return snapshot.docs.map(_toFollowUser).toList();
  }

  Future<List<FollowUserItem>> getFollowing(String uid) async {
    final snapshot = await _followingOf(uid).orderBy('createdAt').get();
    return snapshot.docs.map(_toFollowUser).toList();
  }

  FollowUserItem _toFollowUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final uid = (data['uid'] as String? ?? doc.id).trim();
    final displayName = (data['displayName'] as String? ?? '').trim();
    final photoUrl = (data['photoURL'] as String? ?? '').trim();
    final bio = (data['bio'] as String? ?? '').trim();
    return FollowUserItem(
      uid: uid,
      displayName: displayName.isEmpty ? uid : displayName,
      photoUrl: photoUrl,
      bio: bio,
    );
  }
}
