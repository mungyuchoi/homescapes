import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../models/app_models.dart';

class SpotFirestoreDataSource {
  SpotFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, SpotDoc>> fetchSpotsCollection() async {
    final spotsByLookup = <String, SpotDoc>{};

    // 1) Primary: collection('spots') where each document is one spot.
    try {
      final snapshot = await _firestore.collection('spots').get();
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final parsed = _parseSpot(doc.data(), docId: doc.id);
          if (parsed != null) {
            _registerLookups(spotsByLookup, parsed);
          }
        }
        if (spotsByLookup.isNotEmpty) {
          return spotsByLookup;
        }
      }
    } catch (_) {
      // Fallback below.
    }

    // 2) Fallback: meta/spot_detail document holding { spots: [...] }.
    try {
      final snapshot = await _firestore
          .collection('meta')
          .doc('spot_detail')
          .get();
      final data = snapshot.data();
      final rawSpots = data?['spots'];
      if (rawSpots is List) {
        for (final raw in rawSpots) {
          if (raw is Map<String, dynamic>) {
            final parsed = _parseSpot(raw);
            if (parsed != null) {
              _registerLookups(spotsByLookup, parsed);
            }
          }
        }
      }
    } catch (_) {
      // Seed fallback happens at repository layer.
    }

    return spotsByLookup;
  }

  Future<DayFacilitySlotsDoc> fetchTodaySlotsDoc({DateTime? now}) async {
    final baseNow = now ?? DateTime.now();
    final id = _dayId(baseNow);

    // 1) Primary: days/{dayId}/facilitySlots/*
    try {
      final snap = await _firestore
          .collection('days')
          .doc(id)
          .collection('facilitySlots')
          .get();
      if (snap.docs.isNotEmpty) {
        final docs = <String, FacilitySlotsDoc>{};
        for (final doc in snap.docs) {
          final parsed = _parseFacilitySlotsDoc(doc.id, doc.data());
          if (parsed != null) {
            docs[parsed.facilityId] = parsed;
          }
        }
        if (docs.isNotEmpty) {
          return DayFacilitySlotsDoc(dayId: id, facilitySlots: docs);
        }
      }
    } catch (_) {
      // Fallback below.
    }

    // 2) Fallback: build from spots timetable sessions.
    final spots = await fetchSpotsCollection();
    if (spots.isEmpty) {
      return DayFacilitySlotsDoc(dayId: id, facilitySlots: const {});
    }

    final docs = <String, FacilitySlotsDoc>{};
    final dedup = <String>{};
    for (final spot in spots.values) {
      if (!dedup.add(spot.spotId)) continue;
      final source = await _spotDocById(spot.spotId);
      final slotTimes = _slotsFromSpotDoc(source);
      docs[spot.spotId] = FacilitySlotsDoc(
        facilityId: spot.spotId,
        facilityName: spot.title,
        floor: spot.floor,
        slots: slotTimes,
      );
    }
    return DayFacilitySlotsDoc(dayId: id, facilitySlots: docs);
  }

  Future<List<FacilityMapNode>> fetchMapNodes() async {
    // 1) Primary: collection('mapNodes')
    try {
      final snap = await _firestore.collection('mapNodes').get();
      if (snap.docs.isNotEmpty) {
        final out = <FacilityMapNode>[];
        for (final doc in snap.docs) {
          final parsed = _parseMapNode(doc.data());
          if (parsed != null) out.add(parsed);
        }
        if (out.isNotEmpty) return out;
      }
    } catch (_) {
      // Fallback below.
    }

    // 2) No fallback to spots.map.coords.
    // spots.map coords may be based on a different source image than the
    // map overview (child_timetable_page1), which causes misplaced dots.
    return const [];
  }

  void _registerLookups(Map<String, SpotDoc> target, SpotDoc spot) {
    target[spot.spotId] = spot;
    target[_toFacilityId(spot.title)] = spot;
    target[_normalizeName(spot.title)] = spot;
  }

  SpotDoc? _parseSpot(Map<String, dynamic> data, {String? docId}) {
    final title = _string(data['name']).isNotEmpty
        ? _string(data['name'])
        : _string(data['title']);
    if (title.isEmpty) return null;

    final spotId = _string(data['spotId']).isNotEmpty
        ? _string(data['spotId'])
        : (docId ?? _toFacilityId(title));

    final experience = _map(data['experience']);
    final joy = _map(experience['joy']);

    final rawImages = _stringList(data['images']);
    final fallbackImage = _string(data['imageUrl']);
    final gallery = rawImages.isNotEmpty
        ? rawImages
        : (fallbackImage.isNotEmpty ? [fallbackImage] : const <String>[]);

    final jobs = _jobs(data['jobs']);

    final floorRaw = _string(data['floor']);
    final floorLabel = switch (floorRaw) {
      '3F' => '3층',
      'M' => 'M층',
      _ => floorRaw,
    };

    final interestLabel = _string(experience['interestTypeLabel']).isNotEmpty
        ? _string(experience['interestTypeLabel'])
        : _string(data['aptType']);

    final joyLabel = _string(joy['label']).isNotEmpty
        ? _string(joy['label'])
        : _string(data['joyReward']);

    final ageLabel = _string(experience['ageConditionLabel']).isNotEmpty
        ? _string(experience['ageConditionLabel'])
        : _string(data['ageRule']);

    final defaultOfficialUrl =
        'https://www.koreajobworld.or.kr/exrPreview/exrPreViewList.do?site=1&floor=1&exhpCd=33&portalMenuNo=158';

    return SpotDoc(
      spotId: spotId,
      title: title,
      floor: floorLabel,
      durationMin: _int(
        experience['durationMinutes'],
        fallback: _int(data['durationMin'], fallback: 30),
      ),
      aptType: interestLabel.isNotEmpty ? interestLabel : '흥미유형 확인필요',
      joyReward: joyLabel.isNotEmpty ? joyLabel : '조이 확인필요',
      ageRule: ageLabel.isNotEmpty ? ageLabel : '연령 기준 확인필요',
      description: _string(data['description']).isNotEmpty
          ? _string(data['description'])
          : '공식 체험관 정보를 준비중입니다.',
      imageUrl: gallery.isNotEmpty ? gallery.first : '',
      imageUrls: gallery,
      officialUrl: _string(data['officialUrl']).isNotEmpty
          ? _string(data['officialUrl'])
          : defaultOfficialUrl,
      jobs: jobs,
      jobDescription: jobs.isNotEmpty
          ? jobs.map((job) => '${job.name}: ${job.description}').join('\n')
          : (_string(data['jobDescription']).isNotEmpty
                ? _string(data['jobDescription'])
                : '체험 직무 설명을 준비중입니다.'),
      sourcePath: _string(data['sourcePath']).isNotEmpty
          ? _string(data['sourcePath'])
          : 'spots/$spotId',
    );
  }

  List<SpotJob> _jobs(dynamic value) {
    if (value is! List) return const [];
    final out = <SpotJob>[];
    for (final item in value) {
      if (item is! Map) continue;
      final job = item.cast<String, dynamic>();
      final name = _string(job['name']);
      if (name.isEmpty) continue;
      out.add(
        SpotJob(
          name: name,
          description: _string(job['description']),
          detailUrl: _string(job['detailUrl']),
        ),
      );
    }
    return out;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return const {};
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => _string(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  int _int(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is double) return value.round();
    final parsed = int.tryParse(_string(value));
    return parsed ?? fallback;
  }

  String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _toFacilityId(String name) {
    final codepoints = name.runes
        .map((rune) => rune.toRadixString(16))
        .join('_');
    return 'f_$codepoints';
  }

  String _normalizeName(String name) {
    return name.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  Future<Map<String, dynamic>> _spotDocById(String spotId) async {
    try {
      final doc = await _firestore.collection('spots').doc(spotId).get();
      return doc.data() ?? const {};
    } catch (_) {
      return const {};
    }
  }

  FacilitySlotsDoc? _parseFacilitySlotsDoc(
    String docId,
    Map<String, dynamic> data,
  ) {
    final name = _string(data['facilityName']).isNotEmpty
        ? _string(data['facilityName'])
        : _string(data['name']);
    final id = _string(data['facilityId']).isNotEmpty
        ? _string(data['facilityId'])
        : docId;
    if (name.isEmpty) return null;

    final floor = _string(data['floor']).isNotEmpty
        ? _string(data['floor'])
        : '3층';
    final slots =
        _parseSlotTimes(data['slots']) +
        _parseSlotTimes(data['times']) +
        _parseSlotTimes(data['startTimes']);
    final dedupSlots = _dedupAndSortSlots(slots);

    return FacilitySlotsDoc(
      facilityId: id,
      facilityName: name,
      floor: floor,
      slots: dedupSlots,
    );
  }

  List<TimeOfDay> _slotsFromSpotDoc(Map<String, dynamic> data) {
    final timetable = _map(data['timetable']);
    final sessions = timetable['sessions'];
    if (sessions is! List) return const [];
    final slots = <TimeOfDay>[];
    for (final raw in sessions) {
      if (raw is! Map) continue;
      final session = raw.cast<String, dynamic>();
      slots.addAll(_parseSlotTimes(session['slots']));
    }
    return _dedupAndSortSlots(slots);
  }

  List<TimeOfDay> _parseSlotTimes(dynamic value) {
    if (value is! List) return const [];
    final out = <TimeOfDay>[];
    for (final raw in value) {
      if (raw is Timestamp) {
        final dt = raw.toDate();
        out.add(TimeOfDay(hour: dt.hour, minute: dt.minute));
        continue;
      }
      if (raw is DateTime) {
        out.add(TimeOfDay(hour: raw.hour, minute: raw.minute));
        continue;
      }
      final s = _string(raw);
      if (s.isEmpty) continue;
      final start = s.split('~').first.trim();
      final parsed = _parseHHmm(start);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  List<TimeOfDay> _dedupAndSortSlots(List<TimeOfDay> slots) {
    final byKey = <String, TimeOfDay>{};
    for (final slot in slots) {
      final key =
          '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
      byKey[key] = slot;
    }
    final out = byKey.values.toList();
    out.sort((a, b) {
      final ah = a.hour * 60 + a.minute;
      final bh = b.hour * 60 + b.minute;
      return ah.compareTo(bh);
    });
    return out;
  }

  TimeOfDay? _parseHHmm(String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  FacilityMapNode? _parseMapNode(Map<String, dynamic> data) {
    final name = _string(data['name']);
    final floor = _string(data['floor']);
    final x = _double(data['x']);
    final y = _double(data['y']);
    if (name.isEmpty || floor.isEmpty) return null;
    return FacilityMapNode(
      name: name,
      floor: floor,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
    );
  }

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_string(value)) ?? 0.0;
  }

  String _dayId(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
