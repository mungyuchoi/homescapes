import 'package:flutter/material.dart';

class ProfileLoginUiConfig {
  const ProfileLoginUiConfig({
    required this.showGoogleLogin,
    required this.showAppleLogin,
    required this.showNaverLogin,
    required this.showKakaoLogin,
    required this.loginDescription,
  });

  final bool showGoogleLogin;
  final bool showAppleLogin;
  final bool showNaverLogin;
  final bool showKakaoLogin;
  final String loginDescription;
}

class ProfilePageData {
  const ProfilePageData({
    required this.followerText,
    required this.userName,
    required this.photoUrl,
    required this.noPostText,
    required this.versionText,
  });

  final String followerText;
  final String userName;
  final String photoUrl;
  final String noPostText;
  final String versionText;
}

class ProfileSettingSection {
  const ProfileSettingSection({required this.title, required this.items});

  final String title;
  final List<(IconData, String)> items;
}
