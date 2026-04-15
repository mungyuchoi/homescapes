import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/bottom_sheet_ad_model.dart';

class BottomSheetAdSheetResult {
  const BottomSheetAdSheetResult._({required this.hideToday, this.tappedAd});

  const BottomSheetAdSheetResult.close() : this._(hideToday: false);

  const BottomSheetAdSheetResult.hideToday() : this._(hideToday: true);

  const BottomSheetAdSheetResult.openLink(BottomSheetAdModel ad)
    : this._(hideToday: false, tappedAd: ad);

  final bool hideToday;
  final BottomSheetAdModel? tappedAd;
}

class BottomSheetAdWidget extends StatefulWidget {
  const BottomSheetAdWidget({super.key, required this.ads});

  final List<BottomSheetAdModel> ads;

  @override
  State<BottomSheetAdWidget> createState() => _BottomSheetAdWidgetState();
}

class _BottomSheetAdWidgetState extends State<BottomSheetAdWidget> {
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    if (widget.ads.length <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentIndex = (_currentIndex + 1) % widget.ads.length;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1B1E24) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF4A4F5A)
                    : const Color(0xFFD6DAE2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 248,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.ads.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final ad = widget.ads[index];
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                        ).pop(BottomSheetAdSheetResult.openLink(ad)),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF272C34)
                                : const Color(0xFFF2F5FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ad.imageUrl.isEmpty
                              ? const Center(
                                  child: Icon(Icons.image_outlined, size: 44),
                                )
                              : Image.network(
                                  ad.imageUrl,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 44,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        right: 24,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.ads.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.ads[_currentIndex].title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: isDarkMode
                      ? const Color(0xFFF3F5F9)
                      : const Color(0xFF181D29),
                ),
              ),
            ),
            if (widget.ads.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.ads.length, (index) {
                  final selected = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 16 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFED9A3A)
                          : const Color(0xFFB9C0CE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const BottomSheetAdSheetResult.hideToday()),
                      child: const Text('오늘 하루 보지 않기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const BottomSheetAdSheetResult.close()),
                      child: const Text('닫기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
