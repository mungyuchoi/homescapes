import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../models/app_models.dart';

class CommunityCategoryRepository {
  CommunityCategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<CommunityCategory>> fetchCategories() async {
    try {
      final snapshot = await _firestore
          .collection('meta')
          .doc('categories')
          .collection('items')
          .get();

      final categories =
          snapshot.docs
              .map((doc) => _parseCategory(doc.id, doc.data()))
              .whereType<CommunityCategory>()
              .toList()
            ..sort((a, b) {
              final byOrder = a.order.compareTo(b.order);
              if (byOrder != 0) return byOrder;
              return a.label.compareTo(b.label);
            });

      return categories.isNotEmpty ? categories : CommunityCategory.defaults;
    } catch (_) {
      return CommunityCategory.defaults;
    }
  }

  CommunityCategory? _parseCategory(String docId, Map<String, dynamic> data) {
    final enabled =
        _bool(data['enabled'], fallback: true) &&
        _bool(data['isEnabled'], fallback: true);
    if (!enabled) return null;

    final label = _firstString([
      data['label'],
      data['name'],
      data['title'],
      data['category'],
      docId,
    ]);
    if (label.isEmpty) return null;

    return CommunityCategory(
      id: _firstString([data['id'], docId]),
      label: label,
      iconKey: _firstString([
        data['iconKey'],
        data['icon'],
        data['type'],
        label,
      ]),
      order: _int(data['order'], fallback: _int(data['sortOrder'])),
    );
  }

  bool _bool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return fallback;
  }

  int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  String _firstString(List<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}
