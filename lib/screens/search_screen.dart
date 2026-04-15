import 'dart:async';

import 'package:flutter/material.dart';

import '../features/search/data/models/search_models.dart';
import '../features/search/services/search_service.dart';
import '../features/spot/data/repositories/spot_repository.dart';
import '../features/spot/services/spot_service.dart';
import '../models/app_models.dart';
import '../utils/ad_utils.dart';
import '../utils/facility_helpers.dart';
import '../widgets/app_banner_ad.dart';
import 'spot_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const int _searchBufferMin = 10;

  final SearchService _searchService = SearchService();
  final SpotService _spotService = SpotService(
    repository: const SpotRepositoryImpl(),
  );
  final TextEditingController _controller = TextEditingController();

  List<String> _results = const [];
  List<String> _popularKeywords = const [];
  List<String> _recent = const [];
  Map<String, SpotDoc> _spotsCollection = const {};
  DayFacilitySlotsDoc _todaySlotsDoc = const DayFacilitySlotsDoc(
    dayId: '',
    facilitySlots: {},
  );
  bool _isLoading = true;
  String? _loadError;
  String _query = '';
  int _searchRequestToken = 0;
  static const Color _searchPrimaryColor = Color(0xFFED9A3A);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final cached = await _searchService.getCachedSearchData();
      if (!mounted) return;
      setState(() {
        _applySearchData(cached);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }

    unawaited(_loadSpotDataInBackground());
    unawaited(_refreshSearchDataFromRemote());
  }

  Future<void> _refreshSearchDataFromRemote() async {
    try {
      final data = await _searchService.getSearchData();
      if (!mounted) return;
      setState(() {
        _applySearchData(data);
        _loadError = null;
        _isLoading = false;
      });

      if (_query.trim().isNotEmpty) {
        await _onQueryChanged(_query);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSpotDataInBackground() async {
    final spotsFuture = _spotService.getSpotsCollection();
    final slotsFuture = _spotService.getTodaySlotsDoc(now: DateTime.now());

    Map<String, SpotDoc>? spots;
    DayFacilitySlotsDoc? todaySlotsDoc;
    try {
      spots = await spotsFuture;
    } catch (_) {
      // Spot 데이터 로드 실패 시에도 검색 화면은 유지한다.
    }
    try {
      todaySlotsDoc = await slotsFuture;
    } catch (_) {
      // 슬롯 데이터 로드 실패 시에도 검색 화면은 유지한다.
    }

    if (!mounted) return;
    if (spots == null && todaySlotsDoc == null) return;
    setState(() {
      if (spots != null) {
        _spotsCollection = spots;
      }
      if (todaySlotsDoc != null) {
        _todaySlotsDoc = todaySlotsDoc;
      }
    });
  }

  void _applySearchData(SearchData data) {
    _popularKeywords = data.popularKeywords.take(5).toList(growable: false);
    _recent = data.recentKeywords;
    if (_query.trim().isEmpty) {
      _results = _popularKeywords;
    }
  }

  Future<void> _refreshSearchData() async {
    try {
      final data = await _searchService.getSearchData();
      if (!mounted) return;
      setState(() {
        _applySearchData(data);
      });
    } catch (_) {
      // 조회 실패는 검색 동작 자체를 막지 않는다.
    }
  }

  Future<void> _onQueryChanged(String query) async {
    final requestToken = ++_searchRequestToken;
    setState(() => _query = query);
    if (query.trim().isEmpty) {
      setState(() => _results = _popularKeywords);
      return;
    }

    try {
      final results = await _searchService.search(query);
      if (!mounted || requestToken != _searchRequestToken) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted || requestToken != _searchRequestToken) return;
      setState(() => _results = const []);
    }
  }

  Future<void> _onSearchSubmitted([String? rawQuery]) async {
    final keyword = (rawQuery ?? _controller.text).trim();
    if (keyword.isEmpty) return;

    _controller.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    await _onQueryChanged(keyword);

    try {
      await _searchService.trackSearchKeyword(keyword);
    } catch (_) {
      // 카운트 저장 실패는 검색 흐름을 막지 않는다.
    }

    await _refreshSearchData();

    final matchedSpot = _findSpotByKeyword(keyword);
    if (matchedSpot == null || !mounted) return;
    await _openSpotDetail(matchedSpot);
  }

  SpotDoc? _findSpotByKeyword(String keyword) {
    final normalizedKeyword = _normalizeKeyword(keyword);
    if (normalizedKeyword.isEmpty) return null;

    final direct = _spotsCollection[normalizedKeyword];
    if (direct != null &&
        _normalizeKeyword(direct.title) == normalizedKeyword) {
      return direct;
    }

    final seenSpotIds = <String>{};
    for (final spot in _spotsCollection.values) {
      if (!seenSpotIds.add(spot.spotId)) continue;
      if (_normalizeKeyword(spot.title) == normalizedKeyword) {
        return spot;
      }
    }
    return null;
  }

  FacilitySlotsDoc? _findSlotDocForSpot(SpotDoc spot) {
    final direct = _todaySlotsDoc.facilitySlots[spot.spotId];
    if (direct != null) return direct;

    final targetName = _normalizeKeyword(spot.title);
    for (final slotDoc in _todaySlotsDoc.facilitySlots.values) {
      if (_normalizeKeyword(slotDoc.facilityName) == targetName) {
        return slotDoc;
      }
    }
    return null;
  }

  Future<void> _openSpotDetail(SpotDoc spot) {
    final now = DateTime.now();
    final slotDoc = _findSlotDocForSpot(spot);
    final daySlots = slotDoc?.slots ?? const <TimeOfDay>[];
    final slot = FacilitySlot(
      facilityId: slotDoc?.facilityId ?? spot.spotId,
      name: slotDoc?.facilityName ?? spot.title,
      floor: slotDoc?.floor ?? spot.floor,
      daySlots: daySlots,
      nextStart: FacilityHelpers.findNextStart(slotTimes: daySlots, now: now),
    );

    final status = FacilityHelpers.statusFor(
      slot: slot,
      bufferMin: _searchBufferMin,
      now: now,
    );
    final remaining = FacilityHelpers.remainingSlots(slot: slot, now: now);

    return showSpotDetailBottomSheet(
      context: context,
      spot: spot,
      slot: slot,
      status: status,
      remaining: remaining,
      now: now,
      dayId: _todaySlotsDoc.dayId,
    );
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  Future<void> _removeKeywordFromVisibleResults(String keyword) async {
    final normalized = _normalizeKeyword(keyword);
    if (normalized.isEmpty) return;

    setState(() {
      _results = _results
          .where((item) => _normalizeKeyword(item) != normalized)
          .toList(growable: false);
      _recent = _recent
          .where((item) => _normalizeKeyword(item) != normalized)
          .toList(growable: false);
    });

    try {
      await _searchService.removeRecentKeyword(keyword);
    } catch (_) {
      // 최근 검색어 동기화 실패는 화면 동작을 막지 않는다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D27),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '체험관 또는 키워드 검색',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: _searchPrimaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _searchPrimaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _searchPrimaryColor,
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _searchPrimaryColor,
                      ),
                      suffixIcon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: _searchPrimaryColor,
                      ),
                    ),
                    onSubmitted: (value) => _onSearchSubmitted(value),
                    onChanged: _onQueryChanged,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _onSearchSubmitted(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _searchPrimaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('검색'),
                    ),
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      _loadError!,
                      style: const TextStyle(color: Color(0xFF8F95A3)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_query.isEmpty && _recent.isNotEmpty) ...[
                    const Text(
                      '최근 검색어',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recent
                          .map(
                            (keyword) => ActionChip(
                              label: Text(keyword),
                              onPressed: () => _onSearchSubmitted(keyword),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_query.trim().isEmpty) ...[
                    AppBannerAd(
                      adUnitId: AdUtils.searchResultsInlineMidBannerAdUnitId,
                      type: AppBannerAdType.inline,
                      margin: const EdgeInsets.only(bottom: 12),
                      debugLabel: 'searchResultsInlineMid',
                    ),
                  ],
                  Text(
                    _query.trim().isEmpty ? '인기 검색어' : '검색 결과',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  if (_results.isEmpty)
                    const Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(
                        color: Color(0xFF9AA1AF),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else ...[
                    for (var index = 0; index < _results.length; index++)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          _query.trim().isEmpty
                              ? Icons.trending_up_rounded
                              : Icons.search_rounded,
                        ),
                        title: Text(_results[index]),
                        trailing: _query.trim().isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF9AA1AF),
                                ),
                                tooltip: '삭제',
                                onPressed: () async {
                                  await _removeKeywordFromVisibleResults(
                                    _results[index],
                                  );
                                },
                              )
                            : null,
                        onTap: () => _onSearchSubmitted(_results[index]),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}
