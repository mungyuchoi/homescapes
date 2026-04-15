import 'package:cloud_firestore/cloud_firestore.dart';

enum BottomSheetAdLinkType {
  web,
  deeplink;

  String get value {
    switch (this) {
      case BottomSheetAdLinkType.web:
        return 'web';
      case BottomSheetAdLinkType.deeplink:
        return 'deeplink';
    }
  }

  static BottomSheetAdLinkType fromString(String raw) {
    switch (raw) {
      case 'deeplink':
        return BottomSheetAdLinkType.deeplink;
      case 'web':
      default:
        return BottomSheetAdLinkType.web;
    }
  }
}

class BottomSheetAdModel {
  const BottomSheetAdModel({
    required this.adId,
    required this.title,
    required this.imageUrl,
    required this.linkType,
    required this.linkValue,
    required this.startAt,
    required this.endAt,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  final String adId;
  final String title;
  final String imageUrl;
  final BottomSheetAdLinkType linkType;
  final String linkValue;
  final DateTime startAt;
  final DateTime endAt;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory BottomSheetAdModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return BottomSheetAdModel(
      adId: (data['adId'] as String?)?.trim().isNotEmpty == true
          ? (data['adId'] as String).trim()
          : doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      linkType: BottomSheetAdLinkType.fromString(
        (data['linkType'] as String?)?.trim() ?? 'web',
      ),
      linkValue: (data['linkValue'] as String?)?.trim() ?? '',
      startAt: (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (data['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: (data['priority'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adId': adId,
      'title': title,
      'imageUrl': imageUrl,
      'linkType': linkType.value,
      'linkValue': linkValue,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'priority': priority,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  BottomSheetAdModel copyWith({
    String? adId,
    String? title,
    String? imageUrl,
    BottomSheetAdLinkType? linkType,
    String? linkValue,
    DateTime? startAt,
    DateTime? endAt,
    int? priority,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BottomSheetAdModel(
      adId: adId ?? this.adId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      linkType: linkType ?? this.linkType,
      linkValue: linkValue ?? this.linkValue,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    final inDateRange = !now.isBefore(startAt) && !now.isAfter(endAt);
    return isActive && inDateRange;
  }
}
