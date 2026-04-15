import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AppBannerAdType { anchored, inline }

class AppBannerAd extends StatefulWidget {
  const AppBannerAd({
    super.key,
    required this.adUnitId,
    this.type = AppBannerAdType.anchored,
    this.margin = EdgeInsets.zero,
    this.debugLabel,
  });

  final String adUnitId;
  final AppBannerAdType type;
  final EdgeInsetsGeometry margin;
  final String? debugLabel;

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;
  bool _isLoading = false;
  int _lastRequestedWidth = 0;

  String get _logLabel => widget.debugLabel ?? widget.adUnitId;

  @override
  void didUpdateWidget(covariant AppBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adUnitId != widget.adUnitId ||
        oldWidget.type != widget.type) {
      _disposeAd();
      _adSize = null;
      _isLoaded = false;
      _isLoading = false;
      _lastRequestedWidth = 0;
    }
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  Future<void> _loadAd(int width) async {
    if (_isLoading || width <= 0) return;
    _isLoading = true;
    _lastRequestedWidth = width;

    final AdSize? adSize = widget.type == AppBannerAdType.inline
        ? AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(width)
        : await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted) {
      _isLoading = false;
      return;
    }

    if (adSize == null) {
      _isLoading = false;
      return;
    }

    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          final loadedAd = ad as BannerAd;
          if (!mounted) {
            loadedAd.dispose();
            return;
          }
          if (_bannerAd != loadedAd) {
            loadedAd.dispose();
            return;
          }
          final platformSize = await loadedAd.getPlatformAdSize();
          if (!mounted || _bannerAd != loadedAd) return;
          setState(() {
            if (platformSize != null) {
              _adSize = platformSize;
            }
            _isLoaded = true;
            _isLoading = false;
          });
          if (kDebugMode) {
            debugPrint(
              '[AdBanner][$_logLabel] loaded type=${widget.type.name} '
              'requested=${adSize.width}x${adSize.height} '
              'platform=${platformSize?.width}x${platformSize?.height}',
            );
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          if (_bannerAd != ad) return;
          setState(() {
            _bannerAd = null;
            _adSize = null;
            _isLoaded = false;
            _isLoading = false;
          });
          if (kDebugMode) {
            debugPrint(
              '[AdBanner][$_logLabel] failed code=${error.code} '
              'domain=${error.domain} message=${error.message}',
            );
          }
        },
      ),
    );

    setState(() {
      _disposeAd();
      _bannerAd = ad;
      _adSize = adSize;
      _isLoaded = false;
    });
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.toInt()
            : MediaQuery.sizeOf(context).width.toInt();

        if (width > 0 && (_bannerAd == null || _lastRequestedWidth != width)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_isLoading) return;
            if (_bannerAd != null && _lastRequestedWidth == width) return;
            _loadAd(width);
          });
        }

        if (!_isLoaded || _bannerAd == null || _adSize == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: widget.margin,
          alignment: Alignment.center,
          width: _adSize!.width.toDouble(),
          height: widget.type == AppBannerAdType.inline
              ? (_adSize!.height > 0 ? _adSize!.height.toDouble() : 50)
              : _adSize!.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        );
      },
    );
  }
}
