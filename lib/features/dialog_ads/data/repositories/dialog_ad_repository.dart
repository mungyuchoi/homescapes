import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/dialog_ad_model.dart';

class DialogAdRepository {
  DialogAdRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _adsCollection {
    return _firestore
        .collection('meta')
        .doc('dialog_ads')
        .collection('dialog_ads');
  }

  Future<List<DialogAdModel>> getAllAds() async {
    try {
      final snapshot = await _adsCollection
          .orderBy('priority')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map(DialogAdModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('[DialogAdRepository] getAllAds error: $e');
      return [];
    }
  }

  Future<List<DialogAdModel>> getValidAds() async {
    try {
      final now = DateTime.now();
      final snapshot = await _adsCollection
          .where('isActive', isEqualTo: true)
          .where('startAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('priority')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map(DialogAdModel.fromFirestore).toList();
    } catch (e) {
      debugPrint('[DialogAdRepository] getValidAds error: $e');
      final ads = await getAllAds();
      return ads.where((ad) => ad.isValid).toList();
    }
  }

  Future<String> createAd(DialogAdModel ad) async {
    final docRef = _adsCollection.doc();
    await docRef.set({
      ...ad.copyWith(adId: docRef.id).toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateAd(String adId, DialogAdModel ad) async {
    await _adsCollection.doc(adId).update({
      ...ad.copyWith(adId: adId).toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAd(String adId) async {
    await _adsCollection.doc(adId).delete();
  }

  Future<void> toggleAdActive(String adId, bool isActive) async {
    await _adsCollection.doc(adId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
