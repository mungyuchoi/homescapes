import 'dart:io';

import 'package:flutter/foundation.dart';

class AdUtils {
  AdUtils._();

  static const String androidAppId = 'ca-app-pub-8549606613390169~7296286681';
  static const String iosAppId = 'ca-app-pub-8549606613390169~2495687465';

  static String get communityFeedInlineBannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8549606613390169/6326505317';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8549606613390169/5809825529';
      }
      throw UnsupportedError('Unsupported platform');
    }
    return _testBannerAdUnitId;
  }

  static String? get cardCatalogInlineBannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8549606613390169/5039669336';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8549606613390169/8404199275';
      }
      throw UnsupportedError('Unsupported platform');
    }
    return _testBannerAdUnitId;
  }

  static String get _testBannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    throw UnsupportedError('Unsupported platform');
  }
}
