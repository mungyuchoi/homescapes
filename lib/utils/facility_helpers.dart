import 'package:flutter/material.dart';

import '../models/app_models.dart';

class FacilityHelpers {
  const FacilityHelpers._();

  static List<FacilitySlot> buildCurrentSlots({
    required DayFacilitySlotsDoc todaySlotsDoc,
    required DateTime now,
  }) {
    final slots = todaySlotsDoc.facilitySlots.values.map((doc) {
      return FacilitySlot(
        facilityId: doc.facilityId,
        name: doc.facilityName,
        floor: doc.floor,
        daySlots: doc.slots,
        nextStart: findNextStart(slotTimes: doc.slots, now: now),
      );
    }).toList();

    slots.sort((a, b) {
      if (a.nextStart == null && b.nextStart == null) {
        return a.name.compareTo(b.name);
      }
      if (a.nextStart == null) return 1;
      if (b.nextStart == null) return -1;
      return a.nextStart!.compareTo(b.nextStart!);
    });

    return slots;
  }

  static DateTime? findNextStart({
    required List<TimeOfDay> slotTimes,
    required DateTime now,
  }) {
    for (final slot in slotTimes) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        slot.hour,
        slot.minute,
      );
      if (!candidate.isBefore(now)) return candidate;
    }
    return null;
  }

  static FacilityStatus statusFor({
    required FacilitySlot slot,
    required int bufferMin,
    required DateTime now,
  }) {
    if (slot.nextStart == null) return FacilityStatus.closed;
    final deltaMin = slot.nextStart!.difference(now).inMinutes;
    if (deltaMin < 0) return FacilityStatus.closed;
    if (deltaMin <= bufferMin) return FacilityStatus.available;
    if (deltaMin <= 30) return FacilityStatus.soon;
    return FacilityStatus.later;
  }

  static String statusLabel({
    required FacilitySlot slot,
    required FacilityStatus status,
    required DateTime now,
  }) {
    if (slot.nextStart == null || status == FacilityStatus.closed) {
      return '종료/확인필요';
    }
    final deltaMin = slot.nextStart!.difference(now).inMinutes;
    return deltaMin <= 0 ? '입장 가능' : '$deltaMin분';
  }

  static List<TimeOfDay> remainingSlots({
    required FacilitySlot slot,
    required DateTime now,
  }) {
    return slot.daySlots.where((timeOfDay) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      return !candidate.isBefore(now);
    }).toList();
  }

  static String formatClock(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Color statusColor(FacilityStatus status) {
    switch (status) {
      case FacilityStatus.available:
        return const Color(0xFF5DEB8A);
      case FacilityStatus.soon:
        return const Color(0xFFFFC84A);
      case FacilityStatus.later:
        return const Color(0xFF8EB2FF);
      case FacilityStatus.closed:
        return const Color(0xFF9CA3AF);
    }
  }
}
