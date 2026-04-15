import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/profile/data/repositories/follow_repository.dart';
import '../features/profile/data/models/profile_models.dart';
import '../features/profile/services/profile_service.dart';
import '../utils/user_access_utils.dart';
import '../widgets/common_widgets.dart';
import 'admin_page_screen.dart';
import 'follow_list_screen.dart';
import 'notification_screen.dart';
import 'notice_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isAuthInitializing,
    required this.isAuthLoading,
    required this.authInitError,
    required this.isSignedIn,
    required this.isSettingsOpen,
    required this.onRetryAuth,
    required this.onGoogleLogin,
    required this.onAppleLogin,
    required this.onNaverLogin,
    required this.onKakaoLogin,
    required this.onOpenSettings,
    required this.onCloseSettings,
    required this.onSignOut,
    required this.onWithdraw,
    required this.onSearchTap,
    required this.onMyPostTap,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onNotificationTap,
  });

  final bool isAuthInitializing;
  final bool isAuthLoading;
  final String? authInitError;
  final bool isSignedIn;
  final bool isSettingsOpen;
  final VoidCallback onRetryAuth;
  final VoidCallback onGoogleLogin;
  final VoidCallback onAppleLogin;
  final VoidCallback onNaverLogin;
  final VoidCallback onKakaoLogin;
  final VoidCallback onOpenSettings;
  final VoidCallback onCloseSettings;
  final VoidCallback onSignOut;
  final Future<void> Function() onWithdraw;
  final VoidCallback onSearchTap;
  final Future<void> Function(String postId) onMyPostTap;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onNotificationTap;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final FollowRepository _followRepository = FollowRepository();
  ProfilePageData? _pageData;
  ProfileLoginUiConfig? _loginUiConfig;
  List<ProfileSettingSection> _settingSections = const [];
  bool _isProfileLoading = true;
  String? _loadError;
  int _followerCount = 0;
  int _followingCount = 0;
  List<_MyPostGridItem> _myPosts = const <_MyPostGridItem>[];
  bool _isAdminUser = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSignedIn != widget.isSignedIn ||
        oldWidget.isAuthInitializing != widget.isAuthInitializing) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isProfileLoading = true;
      _loadError = null;
    });

    try {
      final pageData = await _profileService.getProfileData();
      final loginUiConfig = await _profileService.getLoginUiConfig(
        platform: defaultTargetPlatform,
      );
      final settingSections = await _profileService.getSettingSections();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      var followerCount = 0;
      var followingCount = 0;
      var myPosts = <_MyPostGridItem>[];
      var isAdminUser = false;
      if (uid != null) {
        isAdminUser = await UserAccessUtils.isCurrentUserAdmin();
        followerCount = await _followRepository.getFollowerCount(uid);
        followingCount = await _followRepository.getFollowingCount(uid);
        final myPostSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('my_posts')
            .orderBy('createdAt', descending: true)
            .limit(120)
            .get();
        myPosts = myPostSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final isDeleted = (data['isDeleted'] as bool?) ?? false;
              if (isDeleted) return null;
              final thumbnailUrl = (data['thumbnailUrl'] as String? ?? '')
                  .trim();
              final contentText = (data['contentText'] as String? ?? '').trim();
              return _MyPostGridItem(
                postId: doc.id,
                thumbnailUrl: thumbnailUrl,
                contentText: contentText,
              );
            })
            .whereType<_MyPostGridItem>()
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _pageData = pageData;
        _loginUiConfig = loginUiConfig;
        _settingSections = settingSections;
        _followerCount = followerCount;
        _followingCount = followingCount;
        _myPosts = myPosts;
        _isAdminUser = isAdminUser;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProfileLoading = false);
      }
    }
  }

  void _onSettingItemTap(String label) {
    switch (label) {
      case '내 문의 내역':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationScreen.inquiry(),
          ),
        );
        break;
      case '차단 내역 관리':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const _BlockedUsersPage()),
        );
        break;
      case '알림 설정':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationScreen()),
        );
        break;
      case '관리자 페이지':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AdminPageScreen()),
        );
        break;
      case '화면 설정':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _DisplaySettingsPage(
              themeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
            ),
          ),
        );
        break;
      case '공지사항':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const NoticeScreen()));
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label 준비 중입니다.')));
    }
  }

  Future<void> _openProfileEdit() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ProfileEditScreen()),
    );
    if (changed == true && mounted) {
      await _loadProfileData();
      setState(() {});
    }
  }

  Future<void> _openFollowList(int initialTabIndex) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FollowListScreen(uid: uid, initialTabIndex: initialTabIndex),
      ),
    );
    if (mounted) {
      await _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfileLoading) {
      return const SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                '프로필 정보를 불러오는 중입니다.',
                style: TextStyle(
                  color: Color(0xFF7F8493),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null || _pageData == null || _loginUiConfig == null) {
      return SizedBox(
        height: 460,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFCB6B59),
                  size: 34,
                ),
                const SizedBox(height: 10),
                const Text(
                  '프로필 정보를 불러오지 못했습니다.',
                  style: TextStyle(
                    color: Color(0xFF2B2F3D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError ?? '알 수 없는 오류가 발생했습니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A7E8D),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _loadProfileData,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED9A3A),
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.isAuthInitializing) {
      return const SizedBox(
        height: 420,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                '로그인 상태를 확인하는 중입니다.',
                style: TextStyle(
                  color: Color(0xFF7F8493),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.authInitError != null) {
      return SizedBox(
        height: 460,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFCB6B59),
                  size: 34,
                ),
                const SizedBox(height: 10),
                const Text(
                  '로그인 초기화에 실패했습니다.',
                  style: TextStyle(
                    color: Color(0xFF2B2F3D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.authInitError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A7E8D),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: widget.onRetryAuth,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFED9A3A),
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!widget.isSignedIn) {
      return Container(
        color: const Color(0xFFF0F1F5),
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: Column(
          children: [
            const Text(
              '로그인 후\n프로필을 시작하세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 26),
            if (_loginUiConfig!.showGoogleLogin)
              LoginImageButton(
                onTap: widget.isAuthLoading ? null : widget.onGoogleLogin,
                assetPath: Theme.of(context).brightness == Brightness.dark
                    ? 'assets/img/google_login/google_login_dark.png'
                    : 'assets/img/google_login/google_login_light.png',
              ),
            if (_loginUiConfig!.showAppleLogin) ...[
              const SizedBox(height: 12),
              LoginImageButton(
                onTap: widget.isAuthLoading ? null : widget.onAppleLogin,
                assetPath: Theme.of(context).brightness == Brightness.dark
                    ? 'assets/img/apple_login/apple_login_dark.png'
                    : 'assets/img/apple_login/apple_login_light.png',
              ),
            ],
            if (_loginUiConfig!.showNaverLogin) ...[
              const SizedBox(height: 12),
              LoginImageButton(
                onTap: widget.isAuthLoading ? null : widget.onNaverLogin,
                assetPath: Theme.of(context).brightness == Brightness.dark
                    ? 'assets/img/naver_login/NAVER_login_Dark_EN_white_center_H56.png'
                    : 'assets/img/naver_login/NAVER_login_Light_EN_green_center_H56.png',
                width: 208,
                borderRadius: 22,
                imageFit: BoxFit.cover,
              ),
            ],
            if (_loginUiConfig!.showKakaoLogin) ...[
              const SizedBox(height: 12),
              LoginImageButton(
                onTap: widget.isAuthLoading ? null : widget.onKakaoLogin,
                assetPath: 'assets/img/kakao_login/kakao_login.png',
                width: 208,
                borderRadius: 22,
                imageFit: BoxFit.cover,
              ),
            ],
            if (widget.isAuthLoading) ...[
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3E6EE)),
              ),
              child: const Text(
                '로그인하면 프로필, 팔로우, 게시물 관리, 설정 기능을 이용할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7080),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isSettingsOpen) {
      return _ProfileSettingsPage(
        onCloseSettings: widget.onCloseSettings,
        onSignOut: widget.onSignOut,
        onWithdraw: widget.onWithdraw,
        sections: _settingSections,
        versionText: _pageData!.versionText,
        onSettingItemTap: _onSettingItemTap,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        isAdmin: _isAdminUser,
      );
    }

    final currentPhotoUrl = _pageData!.photoUrl.trim();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 220,
          color: const Color(0xFF8EA7C4),
          child: Stack(
            children: [
              Positioned(
                top: 14,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MyTopIcon(
                      icon: Icons.search_rounded,
                      onTap: widget.onSearchTap,
                    ),
                    MyTopIcon(
                      icon: Icons.notifications_none_rounded,
                      onTap: widget.onNotificationTap,
                    ),
                    MyTopIcon(
                      icon: Icons.settings_outlined,
                      onTap: widget.onOpenSettings,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                top: 76,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E8795).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _ProfileAvatar(photoUrl: currentPhotoUrl, size: 58),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _FollowSummaryButton(
                                  label: '팔로워 $_followerCount',
                                  onTap: () => _openFollowList(0),
                                ),
                                const SizedBox(width: 6),
                                _FollowSummaryButton(
                                  label: '팔로잉 $_followingCount',
                                  onTap: () => _openFollowList(1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pageData!.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _openProfileEdit,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFFF0F1F5),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  '작성된 게시물',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1D27),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_myPosts.isEmpty)
          Container(
            width: double.infinity,
            color: const Color(0xFFF0F1F5),
            padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
            child: Column(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 170,
                  color: Color(0xFFB5BAC5),
                ),
                const SizedBox(height: 10),
                Text(
                  _pageData!.noPostText,
                  style: const TextStyle(
                    color: Color(0xFF8F95A3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            color: const Color(0xFFF0F1F5),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myPosts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = _myPosts[index];
                return _MyPostGridTile(
                  item: item,
                  onTap: () => widget.onMyPostTap(item.postId),
                );
              },
            ),
          ),
        const SizedBox(height: 140),
      ],
    );
  }
}

class _MyPostGridItem {
  const _MyPostGridItem({
    required this.postId,
    required this.thumbnailUrl,
    required this.contentText,
  });

  final String postId;
  final String thumbnailUrl;
  final String contentText;
}

class _MyPostGridTile extends StatelessWidget {
  const _MyPostGridTile({required this.item, required this.onTap});

  final _MyPostGridItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = item.thumbnailUrl.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) => _buildTextFallback(),
            ),
          )
        : _buildTextFallback();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  Widget _buildTextFallback() {
    final text = item.contentText.isNotEmpty ? item.contentText : '(내용 없음)';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A5262),
          height: 1.2,
        ),
      ),
    );
  }
}

class _FollowSummaryButton extends StatelessWidget {
  const _FollowSummaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.size});

  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFCFD6E0),
      ),
      child: ClipOval(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    if (photoUrl.startsWith('assets/')) {
      return Image.asset(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const Icon(Icons.smart_toy_rounded, color: Color(0xFF8D95A3));
  }
}

class _ProfileSettingsPage extends StatelessWidget {
  const _ProfileSettingsPage({
    required this.onCloseSettings,
    required this.onSignOut,
    required this.onWithdraw,
    required this.sections,
    required this.versionText,
    required this.onSettingItemTap,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.isAdmin,
  });

  final VoidCallback onCloseSettings;
  final VoidCallback onSignOut;
  final Future<void> Function() onWithdraw;
  final List<ProfileSettingSection> sections;
  final String versionText;
  final ValueChanged<String> onSettingItemTap;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onCloseSettings,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? const Color(0xFFF1F3F8) : null,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '설정',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFF1F3F8) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isAdmin)
          _ProfileSettingSection(
            items: const [(Icons.admin_panel_settings_outlined, '관리자 페이지')],
            onItemTap: onSettingItemTap,
          ),
        if (isAdmin) const SizedBox(height: 10),
        ...sections.map(
          (section) => _ProfileSettingSection(
            items: section.items,
            onItemTap: onSettingItemTap,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async => onSignOut(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22262E) : const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              '로그아웃',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFE9EDF4)
                    : const Color(0xFF1D212C),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '버전',
          style: TextStyle(
            color: isDark ? const Color(0xFFB5BECE) : const Color(0xFF7E8492),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          versionText,
          style: TextStyle(
            color: isDark ? const Color(0xFFC6CEDD) : const Color(0xFF7E8492),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async => onWithdraw(),
          child: Text(
            '탈퇴하기',
            style: TextStyle(
              color: isDark ? const Color(0xFFE39A9E) : const Color(0xFFCB6B59),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 140),
      ],
    );
  }
}

class _ProfileSettingSection extends StatelessWidget {
  const _ProfileSettingSection({required this.items, required this.onItemTap});

  final List<(IconData, String)> items;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2229) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: items
            .map(
              (item) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                leading: Icon(
                  item.$1,
                  color: isDark
                      ? const Color(0xFF9EA7B8)
                      : const Color(0xFFAEB4C0),
                ),
                title: Text(
                  item.$2,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFE9EDF4)
                        : const Color(0xFF1D212C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => onItemTap(item.$2),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BlockedUsersPage extends StatefulWidget {
  const _BlockedUsersPage();

  @override
  State<_BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<_BlockedUsersPage> {
  final Set<String> _processingUids = <String>{};
  List<_BlockedUserListItem> _items = const <_BlockedUserListItem>[];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _items = const <_BlockedUserListItem>[];
        _isLoading = false;
        _loadError = '로그인 후 이용해주세요.';
      });
      return;
    }

    try {
      final blockedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('blocked_users')
          .orderBy('updatedAt', descending: true)
          .get();

      final resolved = <_BlockedUserListItem>[];
      for (final doc in blockedSnapshot.docs) {
        final data = doc.data();
        final blockedUid = (data['blockedUid'] as String? ?? doc.id).trim();
        if (blockedUid.isEmpty) continue;

        var displayName = (data['blockedAuthor'] as String? ?? '').trim();
        var photoUrl = '';
        var subtitle = '';

        try {
          final userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(blockedUid)
              .get();
          final userData = userSnapshot.data();
          if (userData != null) {
            final firestoreName = (userData['displayName'] as String? ?? '')
                .trim();
            final firestorePhoto = (userData['photoURL'] as String? ?? '')
                .trim();
            final firestorePhotoLegacy = (userData['photoUrl'] as String? ?? '')
                .trim();
            final bio = (userData['bio'] as String? ?? '').trim();
            final statusMessage = (userData['statusMessage'] as String? ?? '')
                .trim();
            final description = (userData['description'] as String? ?? '')
                .trim();

            if (firestoreName.isNotEmpty) displayName = firestoreName;
            if (firestorePhoto.isNotEmpty) {
              photoUrl = firestorePhoto;
            } else if (firestorePhotoLegacy.isNotEmpty) {
              photoUrl = firestorePhotoLegacy;
            }
            if (bio.isNotEmpty) {
              subtitle = bio;
            } else if (statusMessage.isNotEmpty) {
              subtitle = statusMessage;
            } else if (description.isNotEmpty) {
              subtitle = description;
            }
          }
        } catch (_) {}

        resolved.add(
          _BlockedUserListItem(
            uid: blockedUid,
            displayName: displayName.isNotEmpty ? displayName : blockedUid,
            subtitle: subtitle.isNotEmpty ? subtitle : '차단된 사용자',
            photoUrl: photoUrl,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _items = resolved;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const <_BlockedUserListItem>[];
        _isLoading = false;
        _loadError = '차단 내역을 불러오지 못했습니다: $e';
      });
    }
  }

  Future<void> _unblockUser(_BlockedUserListItem item) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    if (_processingUids.contains(item.uid)) return;

    setState(() => _processingUids.add(item.uid));
    try {
      final blockedCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('blocked_users');

      await blockedCollection.doc(item.uid).delete();
      final legacySnapshot = await blockedCollection
          .where('blockedUid', isEqualTo: item.uid)
          .get();
      for (final doc in legacySnapshot.docs) {
        if (doc.id == item.uid) continue;
        await doc.reference.delete();
      }

      if (!mounted) return;
      setState(() {
        _items = _items.where((entry) => entry.uid != item.uid).toList();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('차단 해제되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('차단 해제 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _processingUids.remove(item.uid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F3F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          '차단 내역 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFED9A3A)),
            )
          : RefreshIndicator(
              color: const Color(0xFFED9A3A),
              onRefresh: _loadBlockedUsers,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (_loadError != null) ...[
                    Text(
                      _loadError!,
                      style: const TextStyle(
                        color: Color(0xFF7A8190),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '차단된 사용자가 없습니다.',
                        style: TextStyle(
                          color: Color(0xFF7A8190),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    ..._items.map((item) {
                      final processing = _processingUids.contains(item.uid);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            _BlockedUserAvatar(photoUrl: item.photoUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1F2430),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF8A91A1),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: processing
                                  ? null
                                  : () => _unblockUser(item),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFED9A3A),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(92, 40),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                processing ? '처리중' : '차단 해제',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _BlockedUserAvatar extends StatelessWidget {
  const _BlockedUserAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFD1D7E1),
      backgroundImage:
          (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))
          ? NetworkImage(photoUrl)
          : null,
      child: (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))
          ? null
          : const Icon(Icons.person_rounded, color: Color(0xFF7E8798)),
    );
  }
}

class _BlockedUserListItem {
  const _BlockedUserListItem({
    required this.uid,
    required this.displayName,
    required this.subtitle,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String subtitle;
  final String photoUrl;
}

class _DisplaySettingsPage extends StatefulWidget {
  const _DisplaySettingsPage({
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<_DisplaySettingsPage> createState() => _DisplaySettingsPageState();
}

class _DisplaySettingsPageState extends State<_DisplaySettingsPage> {
  late ThemeMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.themeMode;
  }

  void _selectMode(ThemeMode mode) {
    setState(() => _selectedMode = mode);
    widget.onThemeModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF121417) : const Color(0xFFEAEFF4);
    final cardBg = isDark ? const Color(0xFF1D222A) : Colors.white;
    final titleColor = isDark
        ? const Color(0xFFF1F3F8)
        : const Color(0xFF171A21);
    final subtitleColor = isDark
        ? const Color(0xFFA8B1C2)
        : const Color(0xFF8B93A2);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor),
        ),
        title: Text(
          '화면 설정',
          style: TextStyle(
            color: titleColor,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeModeTile(
                title: '시스템 모드',
                subtitle: '기기 설정을 따라 자동으로 변경돼요',
                selected: _selectedMode == ThemeMode.system,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                onTap: () => _selectMode(ThemeMode.system),
              ),
              _ThemeModeTile(
                title: '라이트 모드',
                selected: _selectedMode == ThemeMode.light,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                onTap: () => _selectMode(ThemeMode.light),
              ),
              _ThemeModeTile(
                title: '다크 모드',
                selected: _selectedMode == ThemeMode.dark,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                onTap: () => _selectMode(ThemeMode.dark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.title,
    required this.selected,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: Color(0xFFED9A3A),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
