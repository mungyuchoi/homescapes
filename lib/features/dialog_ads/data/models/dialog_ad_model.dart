import 'package:cloud_firestore/cloud_firestore.dart';

enum DialogAdLinkType {
  none,
  web,
  deeplink;

  String get value {
    switch (this) {
      case DialogAdLinkType.none:
        return 'none';
      case DialogAdLinkType.web:
        return 'web';
      case DialogAdLinkType.deeplink:
        return 'deeplink';
    }
  }

  static DialogAdLinkType fromString(String raw) {
    switch (raw) {
      case 'web':
        return DialogAdLinkType.web;
      case 'deeplink':
        return DialogAdLinkType.deeplink;
      case 'none':
      default:
        return DialogAdLinkType.none;
    }
  }
}

class DialogAdModel {
  const DialogAdModel({
    required this.adId,
    required this.title,
    required this.message,
    required this.imageUrl,
    required this.linkType,
    required this.linkValue,
    required this.ctaText,
    required this.startAt,
    required this.endAt,
    required this.priority,
    required this.isActive,
    required this.showCloseButton,
    required this.allowHideToday,
    required this.createdAt,
    this.updatedAt,
  });

  final String adId;
  final String title;
  final String message;
  final String imageUrl;
  final DialogAdLinkType linkType;
  final String linkValue;
  final String ctaText;
  final DateTime startAt;
  final DateTime endAt;
  final int priority;
  final bool isActive;
  final bool showCloseButton;
  final bool allowHideToday;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory DialogAdModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return DialogAdModel(
      adId: (data['adId'] as String?)?.trim().isNotEmpty == true
          ? (data['adId'] as String).trim()
          : doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      message: (data['message'] as String?)?.trim() ?? '',
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      linkType: DialogAdLinkType.fromString(
        (data['linkType'] as String?)?.trim() ?? 'none',
      ),
      linkValue: (data['linkValue'] as String?)?.trim() ?? '',
      ctaText: (data['ctaText'] as String?)?.trim().isNotEmpty == true
          ? (data['ctaText'] as String).trim()
          : '자세히 보기',
      startAt: (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (data['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: (data['priority'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      showCloseButton: data['showCloseButton'] != false,
      allowHideToday: data['allowHideToday'] != false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adId': adId,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'linkType': linkType.value,
      'linkValue': linkValue,
      'ctaText': ctaText,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'priority': priority,
      'isActive': isActive,
      'showCloseButton': showCloseButton,
      'allowHideToday': allowHideToday,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  DialogAdModel copyWith({
    String? adId,
    String? title,
    String? message,
    String? imageUrl,
    DialogAdLinkType? linkType,
    String? linkValue,
    String? ctaText,
    DateTime? startAt,
    DateTime? endAt,
    int? priority,
    bool? isActive,
    bool? showCloseButton,
    bool? allowHideToday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DialogAdModel(
      adId: adId ?? this.adId,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      linkType: linkType ?? this.linkType,
      linkValue: linkValue ?? this.linkValue,
      ctaText: ctaText ?? this.ctaText,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      allowHideToday: allowHideToday ?? this.allowHideToday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    final inDateRange = !now.isBefore(startAt) && !now.isAfter(endAt);
    return isActive && inDateRange;
  }

  bool get hasBodyContent {
    return title.trim().isNotEmpty ||
        message.trim().isNotEmpty ||
        imageUrl.trim().isNotEmpty;
  }
}
