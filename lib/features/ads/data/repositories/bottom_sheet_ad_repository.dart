import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/bottom_sheet_ad_model.dart';

class BottomSheetAdRepository {
  BottomSheetAdRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _adsCollection {
    return _firestore
        .collection('meta')
        .doc('bottom_sheet_ads')
        .collection('bottom_sheet_ads');
  }

  Future<List<BottomSheetAdModel>> getAllAds() async {
    try {
      final snapshot = await _adsCollection
          .orderBy('priority')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => BottomSheetAdModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[BottomSheetAdRepository] getAllAds error: $e');
      return [];
    }
  }

  Future<List<BottomSheetAdModel>> getValidAds() async {
    try {
      final now = DateTime.now();
      final snapshot = await _adsCollection
          .where('isActive', isEqualTo: true)
          .where('startAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('priority')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => BottomSheetAdModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[BottomSheetAdRepository] getValidAds error: $e');
      final ads = await getAllAds();
      return ads.where((ad) => ad.isValid).toList();
    }
  }

  Future<String> createAd(BottomSheetAdModel ad) async {
    final docRef = _adsCollection.doc();
    await docRef.set({
      ...ad.copyWith(adId: docRef.id).toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateAd(String adId, BottomSheetAdModel ad) async {
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
