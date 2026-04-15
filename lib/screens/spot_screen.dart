import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../utils/ad_utils.dart';
import '../utils/facility_helpers.dart';
import '../widgets/app_banner_ad.dart';
import '../widgets/common_widgets.dart';

class SpotScreen extends StatelessWidget {
  const SpotScreen({
    super.key,
    required this.now,
    required this.dayId,
    required this.slots,
    required this.bufferMin,
    required this.selectedMapFloor,
    required this.mapNodeByName,
    required this.onBufferChanged,
    required this.onMapFloorChanged,
    required this.onSpotTap,
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.hasSpotData,
  });

  final DateTime now;
  final String dayId;
  final List<FacilitySlot> slots;
  final int bufferMin;
  final String selectedMapFloor;
  final Map<String, FacilityMapNode> mapNodeByName;
  final ValueChanged<int> onBufferChanged;
  final ValueChanged<String> onMapFloorChanged;
  final ValueChanged<FacilitySlot> onSpotTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final bool Function(FacilitySlot slot) hasSpotData;

  @override
  Widget build(BuildContext context) {
    final topSlots = slots.take(6).toList();
    final floorFilters = const ['전체', '3층', 'M층'];
    final allSpotsGridSlots = _buildAllSpotsGridSlots();

    final mapSlots = slots.where((slot) {
      final node = mapNodeByName[slot.name];
      if (node == null) return false;
      if (selectedMapFloor != '전체' && node.floor != selectedMapFloor) {
        return false;
      }
      return true;
    }).toList();

    int countBy(FacilityStatus target) {
      return mapSlots
          .where(
            (slot) =>
                FacilityHelpers.statusFor(
                  slot: slot,
                  bufferMin: bufferMin,
                  now: now,
                ) ==
                target,
          )
          .length;
    }

    final visibleSlots = slots
        .where(hasSpotData)
        .map(
          (slot) => MapEntry(
            slot,
            FacilityHelpers.remainingSlots(slot: slot, now: now),
          ),
        )
        .where((entry) => entry.value.isNotEmpty)
        .take(12)
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AppTopHeader(
          title: '체험관',
          onSearchTap: onSearchTap,
          onNotificationTap: onNotificationTap,
        ),
        AppBannerAd(
          adUnitId: AdUtils.spotTopAnchoredBannerAdUnitId,
          type: AppBannerAdType.anchored,
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          debugLabel: 'spotTopAnchored',
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2430), Color(0xFF2E3647)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2B000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘의 실시간 맵 브리핑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '현재 ${FacilityHelpers.formatClock(now)}',
                    style: const TextStyle(
                      color: Color(0xFFA5B0C8),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showBufferInfoDialog(
                          context,
                          bufferMin: bufferMin,
                        ),
                        borderRadius: BorderRadius.circular(99),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFFFE4B8),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '대기 $bufferMin분',
                        style: const TextStyle(
                          color: Color(0xFFFFC97D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: const Color(0xFFED9A3A),
                  activeTrackColor: const Color(0xFFFFC97D),
                  inactiveTrackColor: const Color(0xFF556079),
                ),
                child: Slider(
                  value: bufferMin.toDouble(),
                  min: 0,
                  max: 30,
                  divisions: 30,
                  onChanged: (value) => onBufferChanged(value.round()),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topSlots.map((slot) {
                  final status = FacilityHelpers.statusFor(
                    slot: slot,
                    bufferMin: bufferMin,
                    now: now,
                  );
                  return InkWell(
                    onTap: () => onSpotTap(slot),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1320).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF414E69)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: FacilityHelpers.statusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${slot.name} · ${slot.floor}',
                            style: const TextStyle(
                              color: Color(0xFFE7EAF2),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            FacilityHelpers.statusLabel(
                              slot: slot,
                              status: status,
                              now: now,
                            ),
                            style: TextStyle(
                              color: FacilityHelpers.statusColor(status),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '어린이체험관 맵 오버뷰',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              const Text(
                '3층/M층 시설 상태를 점(초록/노랑/파랑/회색)으로 표시',
                style: TextStyle(
                  color: Color(0xFF6A6A74),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...floorFilters.map((floor) {
                      final selected = floor == selectedMapFloor;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          showCheckmark: false,
                          selected: selected,
                          label: Text(floor),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF4A4A56),
                            fontWeight: FontWeight.w700,
                          ),
                          selectedColor: const Color(0xFFED9A3A),
                          backgroundColor: const Color(0xFFF0F1F6),
                          side: BorderSide.none,
                          onSelected: (_) => onMapFloorChanged(floor),
                        ),
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: Color(0xFF27334A),
                      ),
                      label: const Text(
                        '탭하기',
                        style: TextStyle(
                          color: Color(0xFF27334A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: const Color(0xFFEAF0FC),
                      side: BorderSide.none,
                      onPressed: () =>
                          _openOverviewMapViewer(context, mapSlots: mapSlots),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 595 / 842,
                  child: _ZoomableFacilityMap(
                    mapSlots: mapSlots,
                    mapNodeByName: mapNodeByName,
                    bufferMin: bufferMin,
                    now: now,
                    onSpotTap: onSpotTap,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  LegendBadge(
                    color: FacilityHelpers.statusColor(
                      FacilityStatus.available,
                    ),
                    label: '즉시 가능 ${countBy(FacilityStatus.available)}',
                  ),
                  LegendBadge(
                    color: FacilityHelpers.statusColor(FacilityStatus.soon),
                    label: '곧 가능 ${countBy(FacilityStatus.soon)}',
                  ),
                  LegendBadge(
                    color: FacilityHelpers.statusColor(FacilityStatus.later),
                    label: '대기 필요 ${countBy(FacilityStatus.later)}',
                  ),
                  LegendBadge(
                    color: FacilityHelpers.statusColor(FacilityStatus.closed),
                    label: '종료 ${countBy(FacilityStatus.closed)}',
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '전체 체험관',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              const Text(
                '3층 / M층 체험관 목록',
                style: TextStyle(
                  color: Color(0xFF6A6A74),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (allSpotsGridSlots.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '표시할 체험관이 없습니다.',
                    style: TextStyle(
                      color: Color(0xFF6E7483),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                GridView.builder(
                  itemCount: allSpotsGridSlots.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.45,
                  ),
                  itemBuilder: (context, index) {
                    final slot = allSpotsGridSlots[index];
                    return InkWell(
                      onTap: () => onSpotTap(slot),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8ECF4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F1F28),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot.floor,
                              style: const TextStyle(
                                color: Color(0xFF707889),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '어린이체험관 맵 시간표',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              const Text(
                '이미지를 누르면 확대/축소 가능한 뷰어가 열립니다',
                style: TextStyle(
                  color: Color(0xFF6A6A74),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openZoomableImageViewer(
                      context,
                      imagePath: 'assets/maps/child_timetable_page2.png',
                      title: '어린이체험관 맵 시간표',
                    ),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/maps/child_timetable_page2.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE7EEF9),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: const Text(
                                '시간표 이미지 로드 실패',
                                style: TextStyle(
                                  color: Color(0xFF5B6375),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC1F2533),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '탭해서 확대',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘 회차표',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              const Text(
                '다음 회차 빠른 시설 12개 중심으로 노출',
                style: TextStyle(
                  color: Color(0xFF6A6A74),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (visibleSlots.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '표시할 체험관이 없습니다.',
                    style: TextStyle(
                      color: Color(0xFF6E7483),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ...visibleSlots.map((entry) {
                  final slot = entry.key;
                  final remainingSlots = entry.value;
                  final status = FacilityHelpers.statusFor(
                    slot: slot,
                    bufferMin: bufferMin,
                    now: now,
                  );
                  final preview = remainingSlots
                      .take(4)
                      .map(FacilityHelpers.formatTimeOfDay)
                      .join(' · ');
                  return InkWell(
                    onTap: () => onSpotTap(slot),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: FacilityHelpers.statusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${slot.name} · ${slot.floor}',
                                  style: const TextStyle(
                                    color: Color(0xFF1F1F28),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  preview.isEmpty ? '회차 정보 없음' : preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF777783),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            FacilityHelpers.statusLabel(
                              slot: slot,
                              status: status,
                              now: now,
                            ),
                            style: TextStyle(
                              color: FacilityHelpers.statusColor(status),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF2FF), Color(0xFFF7FBFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '추가 맵 오버뷰',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              const Text(
                '원하는 맵을 눌러서 크게 보고 확대/축소하세요',
                style: TextStyle(
                  color: Color(0xFF5A6478),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _ExtraMapPreviewTile(
                title: '맵 오버뷰 1',
                imagePath: 'assets/maps/map_1.png',
                onTap: () => _openZoomableImageViewer(
                  context,
                  imagePath: 'assets/maps/map_1.png',
                  title: '추가 맵 오버뷰 1',
                ),
              ),
              const SizedBox(height: 10),
              _ExtraMapPreviewTile(
                title: '맵 오버뷰 2',
                imagePath: 'assets/maps/map_2.png',
                onTap: () => _openZoomableImageViewer(
                  context,
                  imagePath: 'assets/maps/map_2.png',
                  title: '추가 맵 오버뷰 2',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 140),
      ],
    );
  }

  List<FacilitySlot> _buildAllSpotsGridSlots() {
    final facilityIdSet = <String>{};
    final out = <FacilitySlot>[];
    for (final slot in slots) {
      if (!hasSpotData(slot)) continue;
      if (slot.floor != '3층' && slot.floor != 'M층') continue;
      if (facilityIdSet.contains(slot.facilityId)) continue;
      facilityIdSet.add(slot.facilityId);
      out.add(slot);
    }
    out.sort((a, b) {
      final floorCompare = _floorOrder(a.floor).compareTo(_floorOrder(b.floor));
      if (floorCompare != 0) return floorCompare;
      return a.name.compareTo(b.name);
    });
    return out;
  }

  int _floorOrder(String floor) {
    if (floor == '3층') return 0;
    if (floor == 'M층') return 1;
    return 2;
  }

  Future<void> _showBufferInfoDialog(
    BuildContext context, {
    required int bufferMin,
  }) {
    final guide = bufferMin <= 0
        ? '대기 시간을 0분으로 두면 즉시 이용 가능한 체험관을 우선 확인할 수 있어요.'
        : '대기 시간을 $bufferMin분으로 두면, 해당 시간 안에 이용 가능한 체험관까지 함께 확인할 수 있어요.';

    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '대기 시간 안내',
                        style: TextStyle(
                          color: Color(0xFF212534),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  guide,
                  style: const TextStyle(
                    color: Color(0xFF4B5161),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '맵 오버뷰에서 초록(즉시 가능)과 노랑(곧 가능) 영역을 확인해보고, 지금 당장 달려갈 체험관을 선택해보세요.',
                  style: TextStyle(
                    color: Color(0xFF4B5161),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openZoomableImageViewer(
    BuildContext context, {
    required String imagePath,
    required String title,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (context) {
        return _ZoomableImageDialog(imagePath: imagePath, title: title);
      },
    );
  }

  void _openOverviewMapViewer(
    BuildContext context, {
    required List<FacilitySlot> mapSlots,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _OverviewMapDialog(
          mapSlots: mapSlots,
          mapNodeByName: mapNodeByName,
          bufferMin: bufferMin,
          now: now,
        );
      },
    );
  }
}

class _ExtraMapPreviewTile extends StatelessWidget {
  const _ExtraMapPreviewTile({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE7EEF9),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: const Text(
                      '맵 이미지 로드 실패',
                      style: TextStyle(
                        color: Color(0xFF5B6375),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC111722),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC1F2533),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        '탭해서 확대',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomableImageDialog extends StatefulWidget {
  const _ZoomableImageDialog({required this.imagePath, required this.title});

  final String imagePath;
  final String title;

  @override
  State<_ZoomableImageDialog> createState() => _ZoomableImageDialogState();
}

class _ZoomableImageDialogState extends State<_ZoomableImageDialog> {
  static const double _minScale = 1;
  static const double _maxScale = 5;
  static const double _scaleStep = 0.4;

  late final TransformationController _controller;
  double _currentScale = _minScale;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController()..addListener(_onMatrixChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onMatrixChanged)
      ..dispose();
    super.dispose();
  }

  void _onMatrixChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() < 0.001) return;
    setState(() => _currentScale = scale);
  }

  void _zoomBy(double delta, Size viewportSize) {
    final targetScale = (_currentScale + delta)
        .clamp(_minScale, _maxScale)
        .toDouble();
    final currentMatrix = _controller.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if ((targetScale - currentScale).abs() < 0.0001) return;

    final scaleChange = targetScale / currentScale;
    final focalPoint = viewportSize.center(Offset.zero);

    currentMatrix
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
      ..scaleByDouble(scaleChange, scaleChange, 1, 1)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);

    _controller.value = currentMatrix;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: _minScale,
                    maxScale: _maxScale,
                    transformationController: _controller,
                    child: Container(
                      color: const Color(0xFF111722),
                      alignment: Alignment.center,
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              '맵 이미지 로드 실패',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x991F2533),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Material(
                  color: const Color(0x991F2533),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapZoomButton(
                      icon: Icons.add,
                      enabled: _currentScale < _maxScale - 0.01,
                      onTap: () => _zoomBy(_scaleStep, viewportSize),
                    ),
                    const SizedBox(height: 8),
                    _MapZoomButton(
                      icon: Icons.remove,
                      enabled: _currentScale > _minScale + 0.01,
                      onTap: () => _zoomBy(-_scaleStep, viewportSize),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewMapDialog extends StatefulWidget {
  const _OverviewMapDialog({
    required this.mapSlots,
    required this.mapNodeByName,
    required this.bufferMin,
    required this.now,
  });

  final List<FacilitySlot> mapSlots;
  final Map<String, FacilityMapNode> mapNodeByName;
  final int bufferMin;
  final DateTime now;

  @override
  State<_OverviewMapDialog> createState() => _OverviewMapDialogState();
}

class _OverviewMapDialogState extends State<_OverviewMapDialog> {
  static const double _scaleStep = 0.4;
  static const double _mapWidth = 595;
  static const double _mapHeight = 842;

  late final TransformationController _controller;
  double _baseScale = 1;
  double _maxScale = 5;
  double _currentScale = 1;
  Size? _lastViewportSize;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController()..addListener(_onMatrixChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onMatrixChanged)
      ..dispose();
    super.dispose();
  }

  void _onMatrixChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() < 0.001) return;
    setState(() => _currentScale = scale);
  }

  void _zoomBy(double delta, Size viewportSize) {
    final targetScale = (_currentScale + delta)
        .clamp(_baseScale, _maxScale)
        .toDouble();
    final currentMatrix = _controller.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if ((targetScale - currentScale).abs() < 0.0001) return;

    final scaleChange = targetScale / currentScale;
    final focalPoint = viewportSize.center(Offset.zero);

    currentMatrix
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
      ..scaleByDouble(scaleChange, scaleChange, 1, 1)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);

    _controller.value = currentMatrix;
  }

  void _ensureFittedTransform(Size viewportSize) {
    final shouldRecalculate =
        _lastViewportSize == null ||
        (_lastViewportSize!.width - viewportSize.width).abs() > 0.5 ||
        (_lastViewportSize!.height - viewportSize.height).abs() > 0.5;
    if (!shouldRecalculate) return;

    final fitScale = math.min(
      viewportSize.width / _mapWidth,
      viewportSize.height / _mapHeight,
    );
    final dx = (viewportSize.width - (_mapWidth * fitScale)) / 2;
    final dy = (viewportSize.height - (_mapHeight * fitScale)) / 2;

    _baseScale = fitScale;
    _maxScale = fitScale * 5;
    _currentScale = fitScale;
    _lastViewportSize = viewportSize;

    _controller.removeListener(_onMatrixChanged);
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(fitScale, fitScale, 1, 1);
    _controller.addListener(_onMatrixChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            _ensureFittedTransform(viewportSize);
            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    constrained: false,
                    minScale: _baseScale,
                    maxScale: _maxScale,
                    transformationController: _controller,
                    child: SizedBox(
                      width: _mapWidth,
                      height: _mapHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/maps/child_timetable_page1.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          ...widget.mapSlots.map((slot) {
                            final node = widget.mapNodeByName[slot.name];
                            if (node == null) {
                              return const SizedBox.shrink();
                            }
                            final status = FacilityHelpers.statusFor(
                              slot: slot,
                              bufferMin: widget.bufferMin,
                              now: widget.now,
                            );
                            final dotColor = FacilityHelpers.statusColor(
                              status,
                            );
                            return Positioned(
                              left: node.x * _mapWidth - 9,
                              top: node.y * _mapHeight - 9,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: dotColor.withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x991F2533),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '어린이체험관 맵 오버뷰',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Material(
                    color: const Color(0x991F2533),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MapZoomButton(
                        icon: Icons.add,
                        enabled: _currentScale < _maxScale - 0.01,
                        onTap: () => _zoomBy(_scaleStep, viewportSize),
                      ),
                      const SizedBox(height: 8),
                      _MapZoomButton(
                        icon: Icons.remove,
                        enabled: _currentScale > _baseScale + 0.01,
                        onTap: () => _zoomBy(-_scaleStep, viewportSize),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ZoomableFacilityMap extends StatefulWidget {
  const _ZoomableFacilityMap({
    required this.mapSlots,
    required this.mapNodeByName,
    required this.bufferMin,
    required this.now,
    required this.onSpotTap,
  });

  final List<FacilitySlot> mapSlots;
  final Map<String, FacilityMapNode> mapNodeByName;
  final int bufferMin;
  final DateTime now;
  final ValueChanged<FacilitySlot> onSpotTap;

  @override
  State<_ZoomableFacilityMap> createState() => _ZoomableFacilityMapState();
}

class _ZoomableFacilityMapState extends State<_ZoomableFacilityMap> {
  static const double _minScale = 1;
  static const double _maxScale = 4;
  static const double _scaleStep = 0.35;

  late final TransformationController _controller;
  double _currentScale = _minScale;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController()..addListener(_onMatrixChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onMatrixChanged)
      ..dispose();
    super.dispose();
  }

  void _onMatrixChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() < 0.001) return;
    setState(() => _currentScale = scale);
  }

  void _zoomBy(double delta, Size viewportSize) {
    final targetScale = (_currentScale + delta)
        .clamp(_minScale, _maxScale)
        .toDouble();
    final currentMatrix = _controller.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if ((targetScale - currentScale).abs() < 0.0001) return;

    final scaleChange = targetScale / currentScale;
    final focalPoint = viewportSize.center(Offset.zero);

    currentMatrix
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
      ..scaleByDouble(scaleChange, scaleChange, 1, 1)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);

    _controller.value = currentMatrix;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: _minScale,
                maxScale: _maxScale,
                boundaryMargin: EdgeInsets.zero,
                clipBehavior: Clip.hardEdge,
                transformationController: _controller,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/maps/child_timetable_page1.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE7EEF9),
                              alignment: Alignment.center,
                              child: const Text(
                                '맵 이미지 로드 실패',
                                style: TextStyle(
                                  color: Color(0xFF5B6375),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      ...widget.mapSlots.map((slot) {
                        final node = widget.mapNodeByName[slot.name];
                        if (node == null) return const SizedBox.shrink();
                        final status = FacilityHelpers.statusFor(
                          slot: slot,
                          bufferMin: widget.bufferMin,
                          now: widget.now,
                        );
                        final dotColor = FacilityHelpers.statusColor(status);
                        return Positioned(
                          left: node.x * constraints.maxWidth - 7,
                          top: node.y * constraints.maxHeight - 7,
                          child: Tooltip(
                            message:
                                '${slot.name} • ${FacilityHelpers.statusLabel(slot: slot, status: status, now: widget.now)}',
                            child: GestureDetector(
                              onTap: () => widget.onSpotTap(slot),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: dotColor.withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapZoomButton(
                    icon: Icons.add,
                    enabled: _currentScale < _maxScale - 0.01,
                    onTap: () => _zoomBy(_scaleStep, viewportSize),
                  ),
                  const SizedBox(height: 8),
                  _MapZoomButton(
                    icon: Icons.remove,
                    enabled: _currentScale > _minScale + 0.01,
                    onTap: () => _zoomBy(-_scaleStep, viewportSize),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapZoomButton extends StatelessWidget {
  const _MapZoomButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xCC1F2533) : const Color(0x661F2533),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
