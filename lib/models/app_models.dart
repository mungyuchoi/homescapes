import 'package:flutter/material.dart';

enum FacilityStatus { available, soon, later, closed }

class DayFacilitySlotsDoc {
  const DayFacilitySlotsDoc({required this.dayId, required this.facilitySlots});

  final String dayId;
  final Map<String, FacilitySlotsDoc> facilitySlots;
}

class SpotJob {
  const SpotJob({
    required this.name,
    required this.description,
    required this.detailUrl,
  });

  final String name;
  final String description;
  final String detailUrl;
}

class SpotDoc {
  const SpotDoc({
    required this.spotId,
    required this.title,
    required this.floor,
    required this.durationMin,
    required this.aptType,
    required this.joyReward,
    required this.ageRule,
    required this.description,
    required this.imageUrl,
    required this.officialUrl,
    this.jobDescription = '체험 직무 설명을 준비중입니다.',
    this.imageUrls = const [],
    this.jobs = const [],
    this.sourcePath = '',
  });

  final String spotId;
  final String title;
  final String floor;
  final int durationMin;
  final String aptType;
  final String joyReward;
  final String ageRule;
  final String description;
  final String imageUrl;
  final String officialUrl;
  final String jobDescription;
  final List<String> imageUrls;
  final List<SpotJob> jobs;
  final String sourcePath;

  List<String> get galleryImages {
    if (imageUrls.isNotEmpty) return imageUrls;
    if (imageUrl.isEmpty) return const [];
    return [imageUrl];
  }
}

class UserTodayRootDoc {
  const UserTodayRootDoc({
    required this.uid,
    required this.dayId,
    required this.items,
  });

  final String uid;
  final String dayId;
  final List<TodayRootItem> items;
}

class TodayRootItem {
  const TodayRootItem({
    required this.spotId,
    required this.spotName,
    required this.timeRange,
    this.note = '',
  });

  final String spotId;
  final String spotName;
  final String timeRange;
  final String note;
}

class FacilitySlotsDoc {
  const FacilitySlotsDoc({
    required this.facilityId,
    required this.facilityName,
    required this.floor,
    required this.slots,
  });

  final String facilityId;
  final String facilityName;
  final String floor;
  final List<TimeOfDay> slots;
}

class FacilitySlot {
  const FacilitySlot({
    required this.facilityId,
    required this.name,
    required this.floor,
    required this.daySlots,
    required this.nextStart,
  });

  final String facilityId;
  final String name;
  final String floor;
  final List<TimeOfDay> daySlots;
  final DateTime? nextStart;
}

class FacilityMapNode {
  const FacilityMapNode({
    required this.name,
    required this.floor,
    required this.x,
    required this.y,
  });

  final String name;
  final String floor;
  final double x;
  final double y;
}

class CommunityCategory {
  const CommunityCategory({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.order,
  });

  final String id;
  final String label;
  final String iconKey;
  final int order;

  static const all = CommunityCategory(
    id: 'all',
    label: '전체',
    iconKey: 'apps',
    order: -1,
  );

  static const defaults = [
    CommunityCategory(id: 'free', label: '자유', iconKey: 'chat', order: 0),
    CommunityCategory(id: 'question', label: '궁금해요', iconKey: 'help', order: 1),
    CommunityCategory(id: 'tip', label: '꿀팁', iconKey: 'lightbulb', order: 2),
    CommunityCategory(id: 'showoff', label: '자랑', iconKey: 'star', order: 3),
  ];

  IconData get icon {
    switch (iconKey.trim().toLowerCase()) {
      case 'chat':
      case 'free':
      case '자유':
        return Icons.chat_bubble_outline_rounded;
      case 'help':
      case 'question':
      case '궁금해요':
        return Icons.help_outline_rounded;
      case 'route':
      case '오늘의 루트':
        return Icons.route_rounded;
      case 'lightbulb':
      case 'tip':
      case '꿀팁':
        return Icons.lightbulb_outline_rounded;
      case 'campaign':
      case 'notice':
        return Icons.campaign_outlined;
      case 'star':
      case 'showoff':
      case '자랑':
        return Icons.star_border_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  static IconData iconForLabel(
    String label, {
    List<CommunityCategory> categories = defaults,
  }) {
    final normalized = label.trim();
    for (final category in categories) {
      if (category.label == normalized || category.id == normalized) {
        return category.icon;
      }
    }
    switch (normalized) {
      case '자유':
        return Icons.chat_bubble_outline_rounded;
      case '궁금해요':
        return Icons.help_outline_rounded;
      case '오늘의 루트':
        return Icons.route_rounded;
      case '꿀팁':
        return Icons.lightbulb_outline_rounded;
      case '자랑':
        return Icons.star_border_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}

class CommunityPost {
  CommunityPost({
    required this.postId,
    required this.uid,
    required this.author,
    this.photoURL,
    required this.timeAgo,
    required this.category,
    required this.content,
    required this.spotId,
    required this.facility,
    required this.likes,
    required this.comments,
    this.routeItems = const [],
    this.imageUrls = const [],
    this.createdAt,
  });

  final String postId;
  final String uid;
  final String author;
  final String? photoURL;
  final String timeAgo;
  final String category;
  final String content;
  final String spotId;
  final String facility;
  final int likes;
  final int comments;
  final List<TodayRootItem> routeItems;
  final List<String> imageUrls;
  final DateTime? createdAt;

  String? get photoUrl => photoURL;
}
