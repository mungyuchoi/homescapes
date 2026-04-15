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
