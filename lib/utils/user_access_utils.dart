import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAccessUtils {
  const UserAccessUtils._();

  static bool isAdminRoles(dynamic roles) {
    if (roles is List) {
      return roles.any((role) => role.toString().trim() == 'admin');
    }
    if (roles is Map) {
      return roles['admin'] == true;
    }
    if (roles is String) {
      return roles.trim() == 'admin';
    }
    return false;
  }

  static bool isRestrictedData(Map<String, dynamic>? data) {
    if (data == null) return false;
    final isRestricted = data['isRestricted'] == true;
    final isBanned = data['isBanned'] == true;
    final banned = data['banned'] == true;
    final writeRestricted = data['writeRestricted'] == true;
    final canWrite = data['canWrite'];
    if (canWrite is bool && canWrite == false) {
      return true;
    }
    return isRestricted || isBanned || banned || writeRestricted;
  }

  static Future<Map<String, dynamic>?> loadUserData({
    required String uid,
    FirebaseFirestore? firestore,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return null;
    final snapshot = await (firestore ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(normalizedUid)
        .get();
    return snapshot.data();
  }

  static Future<bool> isCurrentUserAdmin({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) return false;
    try {
      final data = await loadUserData(uid: user.uid, firestore: firestore);
      return isAdminRoles(data?['roles']);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isCurrentUserRestricted({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    final user = (auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) return false;
    try {
      final data = await loadUserData(uid: user.uid, firestore: firestore);
      return isRestrictedData(data);
    } catch (_) {
      return false;
    }
  }
}
