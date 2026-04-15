import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/profile_models.dart';

class ProfileSeedDataSource {
  const ProfileSeedDataSource();

  Future<ProfilePageData> fetchProfileData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final user = FirebaseAuth.instance.currentUser;
    final authName = (user?.displayName ?? '').trim();
    final authPhoto = (user?.photoURL ?? '').trim();
    String firestoreName = '';
    String firestorePhoto = '';
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      firestoreName = (snapshot.data()?['displayName'] as String? ?? '').trim();
      firestorePhoto = (snapshot.data()?['photoURL'] as String? ?? '').trim();
    }
    final userName = firestoreName.isNotEmpty
        ? firestoreName
        : (authName.isNotEmpty ? authName : 'AJGWESWLHM_172');
    final photoUrl = firestorePhoto.isNotEmpty ? firestorePhoto : authPhoto;
    final versionText = packageInfo.version;

    return ProfilePageData(
      followerText: '팔로워 0 · 팔로잉 0',
      userName: userName,
      photoUrl: photoUrl,
      noPostText: '아직 작성된 게시물이 없어요',
      versionText: versionText,
    );
  }

  Future<ProfileLoginUiConfig> fetchLoginUiConfig({
    required TargetPlatform platform,
  }) async {
    final supportsSocialLogin =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    final showGoogleLogin = supportsSocialLogin;
    final showAppleLogin = platform == TargetPlatform.iOS;
    final showNaverLogin = supportsSocialLogin;
    final showKakaoLogin = supportsSocialLogin;

    return ProfileLoginUiConfig(
      showGoogleLogin: showGoogleLogin,
      showAppleLogin: showAppleLogin,
      showNaverLogin: showNaverLogin,
      showKakaoLogin: showKakaoLogin,
      loginDescription:
          'Android: Google + Naver + Kakao\niPhone: Google + Apple + Naver + Kakao',
    );
  }

  Future<List<ProfileSettingSection>> fetchSettingSections() async {
    return const [
      ProfileSettingSection(
        title: '기본',
        items: [
          (Icons.sms_outlined, '내 문의 내역'),
          (Icons.person_off_outlined, '차단 내역 관리'),
        ],
      ),
      ProfileSettingSection(
        title: '설정',
        items: [
          (Icons.notifications_none_rounded, '알림 설정'),
          (Icons.assignment_outlined, '서비스 이용 동의'),
          (Icons.lightbulb_outline_rounded, '화면 설정'),
        ],
      ),
      ProfileSettingSection(
        title: '기타',
        items: [
          (Icons.campaign_outlined, '공지사항'),
          (Icons.call_outlined, '고객센터'),
          (Icons.assignment_outlined, '이용약관'),
        ],
      ),
    ];
  }
}
