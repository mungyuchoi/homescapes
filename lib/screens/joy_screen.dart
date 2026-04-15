import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/ad_utils.dart';
import '../widgets/app_banner_ad.dart';
import '../widgets/common_widgets.dart';

const _naverBlogClientId = '4JrNi52IPPJPktn043ei';
const _naverBlogClientSecret = '6wvXKkghV7';
const _naverBlogSearchQuery = '잡월드 어린이 체험관';
const int _naverBlogPageSize = 10;

class JoyScreen extends StatelessWidget {
  const JoyScreen({
    super.key,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: AppTopHeader(
                title: '조이',
                onSearchTap: onSearchTap,
                onNotificationTap: onNotificationTap,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: _JoyTopBanner(isDark: isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242A35)
                      : const Color(0xFFE6EAF2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TabBar(
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFFED9A3A),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? const Color(0xFFD9E0ED)
                      : const Color(0xFF4F5463),
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: '조이 이용 안내'),
                    Tab(text: '블로그 이용 안내'),
                    Tab(text: '수료증 활용 안내'),
                    Tab(text: '흥미유형별 안내'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            _JoyUsageTab(isDark: isDark),
            _JoyBlogGuideTab(isDark: isDark),
            _CertificateGuideTab(isDark: isDark),
            _InterestTypeGuideTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _JoyTopBanner extends StatelessWidget {
  const _JoyTopBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD49D), Color(0xFFFFB95F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x1F000000) : const Color(0x26000000),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            color: Color(0xFF6F4008),
            size: 26,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '체험관 활용팁',
                  style: TextStyle(
                    color: Color(0xFF5A3405),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '조이 사용법부터 수료증, 흥미유형까지 한 번에 확인하세요.',
                  style: TextStyle(
                    color: Color(0xFF75460C),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoyUsageTab extends StatelessWidget {
  const _JoyUsageTab({required this.isDark});

  final bool isDark;

  static const _joyShopImageUrl =
      'https://www.koreajobworld.or.kr/images/childrenec/sub/joyShop_img.png';

  @override
  Widget build(BuildContext context) {
    final isDark = this.isDark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 170),
      children: [
        AppBannerAd(
          adUnitId: AdUtils.joyTabInlineBannerAdUnitId,
          type: AppBannerAdType.inline,
          margin: const EdgeInsets.only(bottom: 12),
          debugLabel: 'joyTabInline',
        ),
        const _GuideSectionTitle(text: '조이(JOY) 이용방법'),
        _GuideCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '조이는 어린이체험관에서 사용하는 화폐입니다.\n'
                'JOB MONEY의 줄임말로, 일을 즐겁게 하자는 의미가 담겨 있어요.',
                style: TextStyle(
                  color: Color(0xFF5F6574),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _JoyMoneyChip(value: '5 JOY', color: Color(0xFFECC88D)),
                  _JoyMoneyChip(value: '10 JOY', color: Color(0xFFD7E0A4)),
                  _JoyMoneyChip(value: '50 JOY', color: Color(0xFFC8DDF2)),
                ],
              ),
              SizedBox(height: 12),
              _GuideBullet(
                text: '발권할 때 안내데스크에서 50조이를 꼭 받아오세요. 조이를 분실하면 재발급되지 않습니다.',
              ),
              SizedBox(height: 6),
              _GuideBullet(text: '체험을 하며 조이를 받기도 하고, 조이를 사용하기도 합니다.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _GuideSectionTitle(text: '조이저축'),
        _GuideCard(
          isDark: isDark,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '은행에서 조이를 저축할 수 있습니다.',
                style: TextStyle(
                  color: Color(0xFF5F6574),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              _GuideTimeRow(
                label: '1부',
                time: '12:30~13:30',
                icon: Icons.savings_outlined,
              ),
              SizedBox(height: 8),
              _GuideTimeRow(
                label: '2부',
                time: '17:30~18:30',
                icon: Icons.account_balance_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _GuideSectionTitle(text: '조이숍'),
        _GuideCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RemoteGuideImage(
                imageUrl: _JoyUsageTab._joyShopImageUrl,
                height: 180,
                fallbackLabel: '조이숍 이미지',
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF5F6574),
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                  children: const [
                    TextSpan(text: '조이숍은 '),
                    TextSpan(
                      text: '조이를 이용해 상품을 구매할 수 있는 쇼핑공간',
                      style: TextStyle(
                        color: Color(0xFFCE7A17),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: '입니다.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _GuideTimeRow(
                label: '1부',
                time: '10:30~13:30',
                icon: Icons.store_mall_directory_outlined,
              ),
              const SizedBox(height: 8),
              const _GuideTimeRow(
                label: '2부',
                time: '15:30~18:30',
                icon: Icons.shopping_bag_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JoyBlogGuideTab extends StatefulWidget {
  const _JoyBlogGuideTab({required this.isDark});

  final bool isDark;

  @override
  State<_JoyBlogGuideTab> createState() => _JoyBlogGuideTabState();
}

class _JoyBlogGuideTabState extends State<_JoyBlogGuideTab> {
  static const int _blogTabIndex = 1;

  TabController? _tabController;
  bool _hasTriggeredAutoLoad = false;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  String? _blogError;
  List<_NaverBlogItem> _blogItems = const [];
  int _nextStart = 1;
  int _totalCount = 0;
  int _lastFetchedCount = 0;

  bool get _hasMore {
    if (_totalCount > 0) {
      return _blogItems.length < _totalCount;
    }
    return _lastFetchedCount >= _naverBlogPageSize;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (_tabController != controller) {
      _tabController?.removeListener(_handleTabSelection);
      _tabController = controller;
      _tabController?.addListener(_handleTabSelection);
    }
    _handleTabSelection();
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    super.dispose();
  }

  void _handleTabSelection() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) {
      return;
    }
    if (controller.index != _blogTabIndex || _hasTriggeredAutoLoad) {
      return;
    }
    _hasTriggeredAutoLoad = true;
    unawaited(_loadInitialBlogs());
  }

  Future<_NaverBlogPage> _fetchBlogsPage({required int start}) async {
    final client = HttpClient();
    try {
      final uri = Uri.https('openapi.naver.com', '/v1/search/blog.json', {
        'query': _naverBlogSearchQuery,
        'display': '$_naverBlogPageSize',
        'sort': 'sim',
        'start': '$start',
      });
      final request = await client.getUrl(uri);
      request.headers.set('X-Naver-Client-Id', _naverBlogClientId);
      request.headers.set('X-Naver-Client-Secret', _naverBlogClientSecret);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('status=${response.statusCode}');
      }

      final payload = jsonDecode(body);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('invalid payload');
      }

      final rawItems = payload['items'];
      if (rawItems is! List) {
        throw const FormatException('invalid items');
      }

      final totalRaw = payload['total'];
      final totalCount = totalRaw is num ? totalRaw.toInt() : 0;

      final parsedItems = <_NaverBlogItem>[];
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final item = _NaverBlogItem.fromJson(Map<String, dynamic>.from(raw));
        if (item.link.isNotEmpty) {
          parsedItems.add(item);
        }
      }

      final fetchedCount = rawItems.length;
      return _NaverBlogPage(
        items: parsedItems,
        totalCount: totalCount,
        fetchedCount: fetchedCount,
        nextStart: start + fetchedCount,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _loadInitialBlogs() async {
    if (_isLoadingInitial) return;
    setState(() {
      _isLoadingInitial = true;
      _blogError = null;
      _blogItems = const [];
      _nextStart = 1;
      _totalCount = 0;
      _lastFetchedCount = 0;
    });

    try {
      final page = await _fetchBlogsPage(start: 1);
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
        _blogError = null;
        _blogItems = page.items;
        _nextStart = page.nextStart;
        _totalCount = page.totalCount;
        _lastFetchedCount = page.fetchedCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
        _blogItems = const [];
        _blogError = '블로그 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  Future<void> _loadMoreBlogs() async {
    if (_isLoadingInitial || _isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _blogError = null;
    });

    try {
      final page = await _fetchBlogsPage(start: _nextStart);
      if (!mounted) return;
      final existingLinks = _blogItems.map((item) => item.link).toSet();
      final appendedItems = page.items
          .where((item) => !existingLinks.contains(item.link))
          .toList();
      setState(() {
        _isLoadingMore = false;
        _blogItems = [..._blogItems, ...appendedItems];
        _nextStart = page.nextStart;
        _totalCount = page.totalCount;
        _lastFetchedCount = page.fetchedCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _blogError = '블로그를 더 불러오지 못했습니다. 다시 시도해 주세요.';
      });
    }
  }

  Future<void> _openBlog(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('외부 브라우저를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 170),
      children: [
        AppBannerAd(
          adUnitId: AdUtils.joyTabInlineBannerAdUnitId,
          type: AppBannerAdType.inline,
          margin: const EdgeInsets.only(bottom: 12),
          debugLabel: 'joyTabInline',
        ),
        const _GuideSectionTitle(text: '블로그 이용 안내'),
        const SizedBox(height: 4),
        if (_isLoadingInitial)
          _GuideCard(
            isDark: isDark,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (!_isLoadingInitial && _blogError != null && _blogItems.isEmpty)
          _GuideCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _blogError!,
                  style: const TextStyle(
                    color: Color(0xFFC5221F),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _loadInitialBlogs,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED9A3A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        if (!_isLoadingInitial && _blogError == null && _blogItems.isEmpty)
          _GuideCard(
            isDark: isDark,
            child: Text(
              '검색 결과가 없습니다.',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFD6DDEA)
                    : const Color(0xFF545C6D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (_blogItems.isNotEmpty) ...[
          ..._blogItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BlogResultCard(
                item: item,
                isDark: isDark,
                onTap: () => _openBlog(item.link),
              ),
            );
          }),
          if (_blogError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                _blogError!,
                style: const TextStyle(
                  color: Color(0xFFC5221F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoadingMore ? null : _loadMoreBlogs,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED9A3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isLoadingMore
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(_isLoadingMore ? '불러오는 중...' : '더보기'),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _NaverBlogPage {
  const _NaverBlogPage({
    required this.items,
    required this.totalCount,
    required this.fetchedCount,
    required this.nextStart,
  });

  final List<_NaverBlogItem> items;
  final int totalCount;
  final int fetchedCount;
  final int nextStart;
}

class _NaverBlogItem {
  const _NaverBlogItem({
    required this.title,
    required this.description,
    required this.link,
    required this.blogName,
    required this.postDate,
  });

  final String title;
  final String description;
  final String link;
  final String blogName;
  final String postDate;

  factory _NaverBlogItem.fromJson(Map<String, dynamic> json) {
    final rawTitle = '${json['title'] ?? ''}';
    final rawDescription = '${json['description'] ?? ''}';
    final rawLink = '${json['link'] ?? json['originallink'] ?? ''}';
    final rawBlogName = '${json['bloggername'] ?? ''}';
    final rawPostDate = '${json['postdate'] ?? ''}';
    return _NaverBlogItem(
      title: _cleanNaverText(rawTitle),
      description: _cleanNaverText(rawDescription),
      link: rawLink.trim(),
      blogName: _cleanNaverText(rawBlogName),
      postDate: _formatNaverPostDate(rawPostDate),
    );
  }
}

class _BlogResultCard extends StatelessWidget {
  const _BlogResultCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final _NaverBlogItem item;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF252C38) : const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFED9A3A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  size: 18,
                  color: Color(0xFFCE7A17),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? '제목 없음' : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF1F4FA)
                            : const Color(0xFF222635),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFC9D1E1)
                              : const Color(0xFF5A6173),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (item.blogName.isNotEmpty ||
                        item.postDate.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${item.blogName}${item.blogName.isNotEmpty && item.postDate.isNotEmpty ? ' · ' : ''}${item.postDate}',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFAAB4C9)
                              : const Color(0xFF727B8F),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.open_in_new_rounded,
                size: 17,
                color: isDark
                    ? const Color(0xFF9BA5BB)
                    : const Color(0xFF8790A3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cleanNaverText(String input) {
  final noTags = input.replaceAll(RegExp(r'<[^>]*>'), '');
  return noTags
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .trim();
}

String _formatNaverPostDate(String value) {
  final text = value.trim();
  if (text.length == 8) {
    final y = text.substring(0, 4);
    final m = text.substring(4, 6);
    final d = text.substring(6, 8);
    return '$y.$m.$d';
  }
  return text;
}

class _CertificateGuideTab extends StatelessWidget {
  const _CertificateGuideTab({required this.isDark});

  final bool isDark;

  static const _certificateFrontImageUrl =
      'https://www.koreajobworld.or.kr/images/childrenec/sub/certificate_card_front.png';
  static const _certificateBackImageUrl =
      'https://www.koreajobworld.or.kr/images/childrenec/sub/certificate_card_back.png';
  static const _villageMapImageUrl =
      'https://www.koreajobworld.or.kr/images/childrenec/sub/certificate_map_20260202.jpg';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 170),
      children: [
        AppBannerAd(
          adUnitId: AdUtils.joyTabInlineBannerAdUnitId,
          type: AppBannerAdType.inline,
          margin: const EdgeInsets.only(bottom: 12),
          debugLabel: 'joyTabInline',
        ),
        const _GuideSectionTitle(text: '수료증 활용 방법'),
        _GuideCard(
          isDark: isDark,
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Color(0xFF5F6574),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: '체험 후 수료증을 모아보세요.\n'),
                TextSpan(
                  text: '총 54개의 수료증',
                  style: TextStyle(
                    color: Color(0xFFCE7A17),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: '을 모아 내로, 미로 직업마을을 완성하면 선물을 드립니다.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _GuideSectionTitle(text: '수료증 소개'),
        _GuideCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _GuideLabel(label: '앞면'),
              SizedBox(height: 8),
              _RemoteGuideImage(
                imageUrl: _certificateFrontImageUrl,
                height: 170,
                fallbackLabel: '수료증 앞면',
              ),
              SizedBox(height: 14),
              _GuideLabel(label: '뒷면'),
              SizedBox(height: 8),
              _RemoteGuideImage(
                imageUrl: _certificateBackImageUrl,
                height: 170,
                fallbackLabel: '수료증 뒷면',
              ),
              SizedBox(height: 10),
              Text(
                '뒷면에는 ① 직업명 ② 직업흥미유형 ③ 체험실명이 표시됩니다.',
                style: TextStyle(
                  color: Color(0xFF5F6574),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _GuideSectionTitle(text: '완성된 직업마을'),
        _GuideCard(
          isDark: isDark,
          child: const _RemoteGuideImage(
            imageUrl: _villageMapImageUrl,
            height: 250,
            fallbackLabel: '완성된 직업마을',
          ),
        ),
      ],
    );
  }
}

class _InterestTypeGuideTab extends StatelessWidget {
  const _InterestTypeGuideTab({required this.isDark});

  final bool isDark;

  static const _types = [
    _InterestTypeData(
      title: '꼼꼼하고 부지런한 어린이',
      typeLabel: '현실형 Realistic type',
      description: '기계나 도구를 잘 다루고 분명하며 당당하게 성실한 자세로 자신의 일을 해요.',
      jobs: [
        '자동차정비원',
        '소방관',
        '전기안전기술자',
        '교통경찰관',
        '제과원',
        '피자요리사',
        '우주비행사',
        '디저트연구원',
        '효과음향사',
        '신발패턴사',
        '클라이밍선수',
        '건설기계조종사',
      ],
      color: Color(0xFF5E9C4C),
      icon: Icons.handyman_rounded,
    ),
    _InterestTypeData(
      title: '호기심이 많은 어린이',
      typeLabel: '탐구형 Investigative type',
      description: '논리적이고 공부에 대한 호기심이 많으며 매우 신중한 성격을 지녀요.',
      jobs: [
        '고생물학자',
        '과학수사요원',
        '업사이클러',
        '로봇개발자',
        '수의사',
        'VR게임개발자',
        '치과의사',
        '외과의사',
        '방송연출가(PD)',
        '드론개발자',
      ],
      color: Color(0xFF3F86C8),
      icon: Icons.science_rounded,
    ),
    _InterestTypeData(
      title: '상상력이 많은 어린이',
      typeLabel: '예술형 Artistic type',
      description: '상상력이 풍부하고 개성이 강하며 새로운 것을 창조하는 데 흥미가 커요.',
      jobs: [
        '북디자이너',
        '바리스타',
        '플로리스트',
        '화가',
        '미용사',
        '네일아티스트',
        '성우',
        '마술사',
        '애니메이터',
        '신발디자이너',
        '반려동물미용사',
        '가상공간디자이너',
        '아이돌가수',
        '안무가',
        '디지털아티스트',
      ],
      color: Color(0xFFD56C7F),
      icon: Icons.palette_rounded,
    ),
    _InterestTypeData(
      title: '남을 돕기 좋아하는 어린이',
      typeLabel: '사회형 Social type',
      description: '다른 사람의 문제를 듣고 이해하고 도와주는 활동에 흥미가 있어요.',
      jobs: ['상점판매원', '사회복지사', '치과위생사', '신생아실간호사', '수술실간호사', '항공구조사', '해상구조사'],
      color: Color(0xFF4D9A95),
      icon: Icons.volunteer_activism_rounded,
    ),
    _InterestTypeData(
      title: '발표하기 좋아하는 어린이',
      typeLabel: '진취형 Enterprising type',
      description: '사람들을 이끄는 통솔력과 설득력이 뛰어나고 열정적이며 외향적이에요.',
      jobs: ['신문기자', '아나운서', '방송기자', '기상캐스터', '자동차경주선수', '프로야구선수', '콘텐츠크리에이터'],
      color: Color(0xFFEB8E38),
      icon: Icons.campaign_rounded,
    ),
    _InterestTypeData(
      title: '공중도덕을 잘 지키는 어린이',
      typeLabel: '관습형 Conventional type',
      description: '빈틈이 없고 정확하고 조심스럽게 일을 하며 꼼꼼하게 일을 챙겨요.',
      jobs: ['택배원', '해상교통관제사'],
      color: Color(0xFF5B8A89),
      icon: Icons.rule_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 170),
      children: [
        AppBannerAd(
          adUnitId: AdUtils.joyTabInlineBannerAdUnitId,
          type: AppBannerAdType.inline,
          margin: const EdgeInsets.only(bottom: 12),
          debugLabel: 'joyTabInline',
        ),
        const _GuideSectionTitle(text: '탐험가이드(직업흥미 유형)'),
        _GuideCard(
          isDark: isDark,
          child: const Text(
            '어린이체험관의 체험실은 홀랜드 박사의 진로발달 및 선택이론을 바탕으로\n'
            '현실형, 탐구형, 예술형, 사회형, 진취형, 관습형의 6가지로 분류됩니다.\n'
            '어떤 활동이 즐거웠는지 물어보고 수료증에서 직업흥미유형을 확인해보세요.',
            style: TextStyle(
              color: Color(0xFF5F6574),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ..._types.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InterestTypeCard(data: type, isDark: isDark),
          ),
        ),
        _GuideCard(
          isDark: isDark,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideBullet(
                text: '어린이가 스스로 자신의 흥미를 발견할 수 있도록 다양한 체험실을 탐색하도록 도와주세요.',
              ),
              SizedBox(height: 8),
              _GuideBullet(
                text: '어떤 체험실이 즐거웠는지 물어보고 어떤 유형인지 함께 확인해보세요.(수료증에서도 확인 가능)',
              ),
              SizedBox(height: 8),
              _GuideBullet(
                text: '정확한 흥미유형 검사는 진로설계관에서 받을 수 있습니다.(초등학교 5학년 이상)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B212B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3342) : const Color(0xFFE5E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x1E000000) : const Color(0x14000000),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GuideSectionTitle extends StatelessWidget {
  const _GuideSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
          color: isDark ? const Color(0xFFF0F3F8) : const Color(0xFF1B1D26),
        ),
      ),
    );
  }
}

class _GuideTimeRow extends StatelessWidget {
  const _GuideTimeRow({
    required this.label,
    required this.time,
    required this.icon,
  });

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D39) : const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7589)),
          const SizedBox(width: 8),
          _GuideLabel(label: label),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              time,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFDCE3F0)
                    : const Color(0xFF2A2D3A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideLabel extends StatelessWidget {
  const _GuideLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFED9A3A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _JoyMoneyChip extends StatelessWidget {
  const _JoyMoneyChip({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF3F3E3B),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  const _GuideBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, size: 6, color: Color(0xFF8790A3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5F6574),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RemoteGuideImage extends StatelessWidget {
  const _RemoteGuideImage({
    required this.imageUrl,
    required this.height,
    required this.fallbackLabel,
  });

  final String imageUrl;
  final double height;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _ImageFallbackBox(
            label: fallbackLabel,
            isDark: isDark,
            height: height,
            showProgress: true,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _ImageFallbackBox(
            label: fallbackLabel,
            isDark: isDark,
            height: height,
          );
        },
      ),
    );
  }
}

class _ImageFallbackBox extends StatelessWidget {
  const _ImageFallbackBox({
    required this.label,
    required this.isDark,
    required this.height,
    this.showProgress = false,
  });

  final String label;
  final bool isDark;
  final double height;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: isDark ? const Color(0xFF2A313D) : const Color(0xFFE9EDF4),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgress) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF8D95A6),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6A7286),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestTypeData {
  const _InterestTypeData({
    required this.title,
    required this.typeLabel,
    required this.description,
    required this.jobs,
    required this.color,
    required this.icon,
  });

  final String title;
  final String typeLabel;
  final String description;
  final List<String> jobs;
  final Color color;
  final IconData icon;
}

class _InterestTypeCard extends StatelessWidget {
  const _InterestTypeCard({required this.data, required this.isDark});

  final _InterestTypeData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? data.color.withValues(alpha: 0.2)
            : data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: data.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF0F3F8)
                            : const Color(0xFF1E202A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.typeLabel,
                      style: TextStyle(
                        color: data.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            style: TextStyle(
              color: isDark ? const Color(0xFFD9DFEA) : const Color(0xFF4C515F),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '체험직업',
            style: TextStyle(
              color: isDark ? const Color(0xFFEAF0FC) : const Color(0xFF2C3040),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: data.jobs.map((job) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2430).withValues(alpha: 0.78)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  job,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE7EDF8)
                        : const Color(0xFF373C4A),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
