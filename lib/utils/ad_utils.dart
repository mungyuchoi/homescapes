import 'dart:io';

import 'package:flutter/foundation.dart';

class AdUtils {
  AdUtils._();

  static const String androidAppId = 'ca-app-pub-8549606613390169~4069191492';
  static const String iosAppId = 'ca-app-pub-8549606613390169~6485473407';

  static String get communityFeedInlineBannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8549606613390169/8200366980';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8549606613390169/5142600019';
      }
      throw UnsupportedError('Unsupported platform');
    }
    return _testBannerAdUnitId;
  }

  static String get spotTopAnchoredBannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8549606613390169/3251292633';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8549606613390169/8796776125';
      }
      throw UnsupportedError('Unsupported platform');
    }
    return _testBannerAdUnitId;
  }

  static String get joyTabInlineBannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8549606613390169/6862875796';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8549606613390169/4348393092';
      }
      throw UnsupportedError('Unsupported platform');
    }
    return _testBannerAdUnitId;
  }

  static String get searchResultsInlineMidBannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-8549606613390169/1109857798';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-8549606613390169/1642697494';
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
