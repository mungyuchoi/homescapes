import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/card_catalog_models.dart';

class CardCatalogRepository {
  CardCatalogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _catalogCollection {
    return _firestore.collection('card_catalog');
  }

  Future<CardCatalogSeason> fetchActiveSeason() async {
    final activeSeasonId = await _fetchActiveSeasonId();
    if (activeSeasonId.isEmpty) {
      throw Exception('활성 카드 시즌을 찾지 못했습니다.');
    }

    final seasonRef = _catalogCollection.doc(activeSeasonId);
    final seasonSnapshot = await seasonRef.get();
    final seasonData = seasonSnapshot.data();
    if (seasonData == null) {
      throw Exception('카드 시즌 정보를 찾지 못했습니다: $activeSeasonId');
    }

    final setsSnapshot = await seasonRef.collection('sets').get();
    final sets =
        setsSnapshot.docs
            .map((doc) => _parseSet(doc.id, doc.data()))
            .where((set) => set.name.isNotEmpty)
            .toList(growable: false)
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            if (byOrder != 0) return byOrder;
            return a.name.compareTo(b.name);
          });

    final setOrderById = {for (final set in sets) set.id: set.order};

    final cardsSnapshot = await seasonRef.collection('cards').get();
    final cards =
        cardsSnapshot.docs
            .map((doc) => _parseCard(doc.id, doc.data()))
            .where((card) => card.isActive && card.name.isNotEmpty)
            .toList(growable: false)
          ..sort((a, b) {
            final bySet = (setOrderById[a.setId] ?? 9999).compareTo(
              setOrderById[b.setId] ?? 9999,
            );
            if (bySet != 0) return bySet;
            final bySlot = a.slotIndex.compareTo(b.slotIndex);
            if (bySlot != 0) return bySlot;
            return a.name.compareTo(b.name);
          });

    return CardCatalogSeason(
      id: activeSeasonId,
      name: _string(seasonData['name']).isNotEmpty
          ? _string(seasonData['name'])
          : activeSeasonId,
      title: _string(seasonData['title']),
      totalCards: _int(seasonData['totalCards'], fallback: cards.length),
      startAt: _dateTime(seasonData['startAt']),
      endAt: _dateTime(seasonData['endAt']),
      sets: sets,
      cards: cards,
    );
  }

  Future<String> _fetchActiveSeasonId() async {
    try {
      final configSnapshot = await _catalogCollection.doc('config').get();
      final configuredId = _string(configSnapshot.data()?['activeSeasonId']);
      if (configuredId.isNotEmpty) return configuredId;
    } catch (_) {
      // Fallback below.
    }

    try {
      final activeSnapshot = await _catalogCollection
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (activeSnapshot.docs.isNotEmpty) {
        return activeSnapshot.docs.first.id;
      }
    } catch (_) {
      // Surface the empty result to the caller.
    }

    return '';
  }

  CardCatalogSet _parseSet(String docId, Map<String, dynamic> data) {
    final id = _string(data['id']).isNotEmpty ? _string(data['id']) : docId;
    return CardCatalogSet(
      id: id,
      name: _string(data['name']),
      order: _int(data['order'], fallback: _trailingNumber(id)),
    );
  }

  CardCatalogCard _parseCard(String docId, Map<String, dynamic> data) {
    final id = _string(data['id']).isNotEmpty ? _string(data['id']) : docId;
    return CardCatalogCard(
      id: id,
      name: _string(data['name']),
      setId: _string(data['setId']),
      slotIndex: _int(data['slotIndex'], fallback: _trailingNumber(id)),
      stars: _int(data['stars'], fallback: 1).clamp(1, 5).toInt(),
      isGold: _bool(data['isGold']),
      imageUrl: _string(data['imageUrl']),
      isActive: _bool(data['isActive'], fallback: true),
    );
  }

  int _trailingNumber(String value) {
    final match = RegExp(r'(\d+)$').firstMatch(value);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  DateTime? _dateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _bool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    final text = _string(value).toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  int _int(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(_string(value)) ?? fallback;
  }

  String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
