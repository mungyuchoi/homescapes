import 'package:flutter/widgets.dart';

class ProfileIconAssets {
  ProfileIconAssets._();

  static const String gray = 'assets/img/icon/gray_icon.png';

  static const List<String> presets = [
    'assets/img/icon/blue_icon.png',
    'assets/img/icon/green_icon.png',
    'assets/img/icon/navy_icon.png',
    'assets/img/icon/orange_icon.png',
    'assets/img/icon/purple_icon.png',
    'assets/img/icon/red_icon.png',
    'assets/img/icon/yellow_icon.png',
  ];

  static const Map<String, String> legacyRemoteUrlToAsset = {
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fblue_icon.png?alt=media&token=75bb29df-3779-4e07-8352-600911555f2f':
        'assets/img/icon/blue_icon.png',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fgreen_icon.png?alt=media&token=e15b38e6-931e-4a5f-b165-d6a4cfa3be5f':
        'assets/img/icon/green_icon.png',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fnavy_icon.png?alt=media&token=2082a62e-a2a4-4692-a9d1-f72236f72169':
        'assets/img/icon/navy_icon.png',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Forange_icon.png?alt=media&token=2157e85e-c5e9-483c-b88f-45fd056ca91d':
        'assets/img/icon/orange_icon.png',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fpurple_icon.png?alt=media&token=2aa260ef-7d66-40a4-baf7-9bea7156f90b':
        'assets/img/icon/purple_icon.png',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fred_icon.png?alt=media&token=c3cb763c-0004-4591-a3e5-afd8ec05f0c8':
        'assets/img/icon/red_icon.png',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fyellow_icon.png?alt=media&token=bec70c50-efbc-4171-9205-5269f14370de':
        'assets/img/icon/yellow_icon.png',
  };

  static String normalize(String? value) {
    final trimmed = value?.trim() ?? '';
    return legacyRemoteUrlToAsset[trimmed] ?? trimmed;
  }

  static bool isPreset(String? value) {
    return presets.contains(normalize(value));
  }

  static ImageProvider<Object>? imageProvider(String? value) {
    final normalized = normalize(value);
    if (normalized.startsWith('assets/')) {
      return AssetImage(normalized);
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    return null;
  }
}
