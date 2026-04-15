import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

import '../features/ads/data/models/bottom_sheet_ad_model.dart';
import '../features/ads/data/repositories/bottom_sheet_ad_repository.dart';
import '../features/ads/presentation/widgets/bottom_sheet_ad_widget.dart';
import '../features/ads/utils/bottom_sheet_ad_storage.dart';
import '../features/auth/services/social_custom_auth_service.dart';
import '../features/dialog_ads/data/models/dialog_ad_model.dart';
import '../features/dialog_ads/data/repositories/dialog_ad_repository.dart';
import '../features/dialog_ads/presentation/widgets/dialog_ad_widget.dart';
import '../features/dialog_ads/utils/dialog_ad_storage.dart';
import '../models/app_models.dart';
import '../utils/facility_helpers.dart';
import '../utils/user_access_utils.dart';
import '../widgets/common_widgets.dart';
import 'feed_detail_screen.dart';
import 'feed_screen.dart';
import 'joy_screen.dart';
import 'profile_screen.dart';
import 'post_create_screen.dart';
import 'search_screen.dart';
import 'spot_detail_screen.dart';
import 'notification_screen.dart';
import 'spot_screen.dart';
import 'user_screen.dart';
import '../features/community/data/repositories/community_repository.dart';
import '../features/community/data/repositories/community_like_repository.dart';
import '../features/community/services/community_service.dart';
import '../features/spot/data/repositories/spot_repository.dart';
import '../features/spot/services/spot_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _allCategory = '전체';
  static const Set<String> _postNotificationTypes = <String>{
    'COMMUNITY_POST_COMMENT',
    'COMMUNITY_COMMENT_REPLY',
    'COMMUNITY_POST_LIKE',
    'COMMUNITY_FOLLOWING_POST',
  };
  static const List<String> _defaultProfileIconAssets = [
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fblue_icon.png?alt=media&token=75bb29df-3779-4e07-8352-600911555f2f',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fgreen_icon.png?alt=media&token=e15b38e6-931e-4a5f-b165-d6a4cfa3be5f',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fnavy_icon.png?alt=media&token=2082a62e-a2a4-4692-a9d1-f72236f72169',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Forange_icon.png?alt=media&token=2157e85e-c5e9-483c-b88f-45fd056ca91d',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fpurple_icon.png?alt=media&token=2aa260ef-7d66-40a4-baf7-9bea7156f90b',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fred_icon.png?alt=media&token=c3cb763c-0004-4591-a3e5-afd8ec05f0c8',
    'https://firebasestorage.googleapis.com/v0/b/jobworld-e3988.firebasestorage.app/o/icon%2Fyellow_icon.png?alt=media&token=bec70c50-efbc-4171-9205-5269f14370de',
  ];
  static const List<String> _positiveAdjectives = [
    '멋진',
    '힘쌘',
    '용감한',
    '밝은',
    '친절한',
    '튼튼한',
    '슬기로운',
    '든든한',
    '재빠른',
    '창의적인',
    '반짝이는',
    '당찬',
    '유쾌한',
    '상냥한',
    '기특한',
    '씩씩한',
    '유능한',
    '똑똑한',
    '꿈꾸는',
    '열정적인',
  ];
  static const List<String> _kidExperienceJobs = [
    '소방수',
    '경찰관',
    '의사',
    '간호사',
    '요리사',
    '제빵사',
    '파일럿',
    '기장',
    '기관사',
    '건축가',
    '과학자',
    '연구원',
    '방송인',
    '기상캐스터',
    '승무원',
    '정비사',
    '판사',
    '검사',
    '기자',
    '디자이너',
  ];

  final List<String> _categories = const [
    _allCategory,
    '자유',
    '궁금해요',
    '오늘의 루트',
    '꿀팁',
  ];

  final SpotService _spotService = SpotService(
    repository: SpotRepositoryImpl(),
  );
  Map<String, SpotDoc> _spotsCollection = const {};
  DayFacilitySlotsDoc _todaySlotsDoc = const DayFacilitySlotsDoc(
    dayId: '',
    facilitySlots: {},
  );
  final CommunityService _communityService = CommunityService(
    repository: CommunityRepositoryImpl(),
  );
  final CommunityLikeRepository _communityLikeRepository =
      CommunityLikeRepository();
  final SocialCustomAuthService _socialCustomAuthService =
      SocialCustomAuthService();
  List<CommunityPost> _postsCollection = const [];
  final Map<String, bool> _postLikedByMe = {};
  final Map<String, int> _postLikeCounts = {};
  bool _isCommunityLoading = true;
  String? _communityLoadError;

  List<FacilityMapNode> _mapNodes = const [];
  Map<String, FacilityMapNode> _mapNodeByName = const {};
  bool _isSpotLoading = true;
  String? _spotLoadError;

  String _selectedCategory = _allCategory;
  int _selectedBottomTab = 0;
  int _profileRefreshTick = 0;
  int _bufferMin = 10;
  String _selectedMapFloor = '전체';
  bool _isMySettingsOpen = false;
  bool _isAuthInitializing = true;
  bool _isAuthLoading = false;
  String? _authInitError;
  String? _lastGoogleSignInError;
  DateTime? _lastBackPressedAt;
  bool _hasShownDialogAd = false;
  bool _hasShownBottomSheetAd = false;

  FirebaseAuth? _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;

  Future<void> _handleBackPressed() async {
    final pressedAt = DateTime.now();
    final canExit =
        _lastBackPressedAt != null &&
        pressedAt.difference(_lastBackPressedAt!) <= const Duration(seconds: 2);

    if (canExit) {
      await SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = pressedAt;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('한 번 더 뒤로가기를 누르면 종료됩니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logAuth(String message) {
    debugPrint('[AUTH_DEBUG] $message');
  }

  String _generateTemporaryDisplayName(String uid) {
    final random = Random(uid.hashCode);
    final adjective =
        _positiveAdjectives[random.nextInt(_positiveAdjectives.length)];
    final job = _kidExperienceJobs[random.nextInt(_kidExperienceJobs.length)];
    return '$adjective$job';
  }

  bool _isProviderPlaceholderName(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized == '네이버사용자' ||
        normalized == '카카오사용자' ||
        normalized == 'naver user' ||
        normalized == 'kakao user';
  }

  String _resolveDefaultPhotoUrl(String uid) {
    final random = Random(uid.hashCode);
    return _defaultProfileIconAssets[random.nextInt(
      _defaultProfileIconAssets.length,
    )];
  }

  Future<void> _ensureUserDisplayName(
    User? user, {
    String? fallbackDisplayName,
  }) async {
    if (user == null) return;
    final isCustomProviderUid = user.uid.contains(':');
    if (isCustomProviderUid) return;
    final currentName = user.displayName?.trim() ?? '';
    if (currentName.isNotEmpty) return;

    final preferredName = fallbackDisplayName?.trim() ?? '';
    final generated = preferredName.isNotEmpty
        ? preferredName
        : _generateTemporaryDisplayName(user.uid);
    try {
      await user.updateDisplayName(generated);
      await user.reload();
      _logAuth('Generated displayName applied: $generated');
    } catch (e) {
      _logAuth('displayName update skipped');
    }
  }

  Future<void> _upsertUserDocument(
    User? user, {
    String? providerId,
    String? providerUid,
    String? displayNameOverride,
    String? emailOverride,
    String? photoUrlOverride,
  }) async {
    if (user == null) return;
    final uid = user.uid;
    final ref = _firestore.collection('users').doc(uid);
    final snapshot = await ref.get();
    final existing = snapshot.data();
    final existingName = (existing?['displayName'] as String?)?.trim() ?? '';
    final existingEmail = (existing?['email'] as String?)?.trim() ?? '';
    final existingPhotoUrl = (existing?['photoURL'] as String?)?.trim() ?? '';
    final overrideName = displayNameOverride?.trim() ?? '';
    final overrideEmail = emailOverride?.trim() ?? '';
    final overridePhotoUrl = photoUrlOverride?.trim() ?? '';
    final providerPhotoUrl = user.photoURL?.trim() ?? '';
    final providerFromFirebase = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'unknown';
    final resolvedProviderId = (providerId?.trim().isNotEmpty ?? false)
        ? providerId!.trim()
        : providerFromFirebase;
    final normalizedProviderId = resolvedProviderId.toLowerCase();
    final forceGeneratedNameForProvider =
        normalizedProviderId == 'naver' || normalizedProviderId == 'kakao';
    final resolvedProviderUid = providerUid?.trim() ?? '';
    final generatedName = _generateTemporaryDisplayName(uid);
    final isExistingPlaceholder = _isProviderPlaceholderName(existingName);
    final isOverridePlaceholder = _isProviderPlaceholderName(overrideName);
    final hasUsableOverrideName =
        !forceGeneratedNameForProvider &&
        overrideName.isNotEmpty &&
        !isOverridePlaceholder;
    final resolvedName = (!isExistingPlaceholder && existingName.isNotEmpty)
        ? existingName
        : (hasUsableOverrideName ? overrideName : generatedName);
    final resolvedPhotoUrl = existingPhotoUrl.isNotEmpty
        ? existingPhotoUrl
        : (overridePhotoUrl.isNotEmpty
              ? overridePhotoUrl
              : (providerPhotoUrl.isNotEmpty
                    ? providerPhotoUrl
                    : _resolveDefaultPhotoUrl(uid)));
    final hasRoles = existing?['roles'] != null;
    final resolvedEmail = overrideEmail.isNotEmpty
        ? overrideEmail
        : (user.email?.trim() ?? existingEmail);

    if (!snapshot.exists) {
      await ref.set({
        'uid': uid,
        'email': resolvedEmail,
        'displayName': resolvedName,
        'photoURL': resolvedPhotoUrl,
        'provider': resolvedProviderId,
        if (resolvedProviderUid.isNotEmpty) 'providerUid': resolvedProviderUid,
        'roles': const ['user'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'email': resolvedEmail,
        'photoURL': resolvedPhotoUrl,
        'provider': resolvedProviderId,
        if (resolvedProviderUid.isNotEmpty) 'providerUid': resolvedProviderUid,
        'lastLoginAt': FieldValue.serverTimestamp(),
        if (existingName.isEmpty ||
            isExistingPlaceholder ||
            hasUsableOverrideName)
          'displayName': resolvedName,
        if (!hasRoles) 'roles': const ['user'],
      }, SetOptions(merge: true));
    }

    if (((snapshot.exists && existingName.isEmpty) ||
            !snapshot.exists ||
            (user.displayName?.trim() ?? '').isEmpty) &&
        resolvedName.isNotEmpty &&
        !uid.contains(':')) {
      try {
        await user.updateDisplayName(resolvedName);
        await user.reload();
      } catch (e) {
        _logAuth('Auth profile sync skipped');
      }
    }
  }

  Future<void> _updateFcmTokenForSignedInUser() async {
    final user = _auth?.currentUser;
    if (user == null) {
      _logAuth('Skip fcmToken update: user is not signed in');
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      final normalizedToken = token?.trim() ?? '';
      if (normalizedToken.isEmpty) {
        _logAuth('Skip fcmToken update: token is empty');
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': normalizedToken,
      }, SetOptions(merge: true));
      _logAuth('Updated fcmToken for uid=${user.uid}');
    } catch (e) {
      _logAuth('Failed to update fcmToken: $e');
    }
  }

  List<CommunityPost> get _filteredPosts {
    if (_selectedCategory == _allCategory) return _postsCollection;
    return _postsCollection
        .where((post) => post.category == _selectedCategory)
        .toList();
  }

  String _normalizeSpotKey(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  SpotDoc? _findSpotBySlot(FacilitySlot slot) {
    final direct = _spotsCollection[slot.facilityId];
    if (direct != null) return direct;

    final normalizedByName = _spotsCollection[_normalizeSpotKey(slot.name)];
    if (normalizedByName != null) return normalizedByName;

    for (final candidate in _spotsCollection.values) {
      if (_normalizeSpotKey(candidate.title) == _normalizeSpotKey(slot.name)) {
        return candidate;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initializeNotificationRouting();
    _initializeAuth();
    _loadSpotData();
    _loadCommunityData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showStartupPromotions());
    });
  }

  @override
  void dispose() {
    _onMessageOpenedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSpotData() async {
    setState(() {
      _isSpotLoading = true;
      _spotLoadError = null;
    });

    try {
      final spots = await _spotService.getSpotsCollection();
      final todaySlotsDoc = await _spotService.getTodaySlotsDoc(
        now: DateTime.now(),
      );
      final mapNodes = await _spotService.getMapNodes();
      if (!mounted) return;
      setState(() {
        _spotsCollection = spots;
        _todaySlotsDoc = todaySlotsDoc;
        _mapNodes = mapNodes;
        _mapNodeByName = {for (final node in _mapNodes) node.name: node};
      });
    } catch (e) {
      _logAuth('Spot data load failed: $e');
      if (!mounted) return;
      setState(() {
        _spotLoadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSpotLoading = false;
        });
      }
    }
  }

  Widget _buildSpotBody({
    required DateTime now,
    required List<FacilitySlot> slots,
  }) {
    if (_isSpotLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_spotLoadError != null) {
      return RefreshIndicator(
        onRefresh: _loadSpotData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Center(
              child: Text(
                '체험관 데이터를 불러오지 못했습니다.',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3342),
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _spotLoadError!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A8190)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadSpotData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SpotScreen(
      now: now,
      dayId: _todaySlotsDoc.dayId,
      slots: slots,
      bufferMin: _bufferMin,
      selectedMapFloor: _selectedMapFloor,
      mapNodeByName: _mapNodeByName,
      onBufferChanged: (value) {
        setState(() => _bufferMin = value);
      },
      onMapFloorChanged: (floor) {
        setState(() => _selectedMapFloor = floor);
      },
      onSpotTap: (slot) => _openSpotDetail(slot, now),
      onSearchTap: _openSearch,
      onNotificationTap: _openNotification,
      hasSpotData: (slot) => _findSpotBySlot(slot) != null,
    );
  }

  Future<void> _loadCommunityData() async {
    setState(() {
      _isCommunityLoading = true;
      _communityLoadError = null;
    });

    final uid = _auth?.currentUser?.uid ?? 'guest_demo';
    try {
      final cachedPosts = await _communityService.getCachedPosts(
        now: DateTime.now(),
        uid: uid,
      );
      if (cachedPosts.isNotEmpty) {
        await _applyCommunityPosts(cachedPosts);
      }

      final posts = await _communityService.getPosts(
        now: DateTime.now(),
        uid: uid,
      );
      await _applyCommunityPosts(posts);
    } catch (e, stack) {
      _logAuth('Community load failed: $e');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
      if (!mounted) return;
      setState(() {
        _communityLoadError = e.toString();
        _isCommunityLoading = false;
      });
    }
  }

  Map<String, String> _normalizeNotificationPayload(
    Map<String, dynamic> source,
  ) {
    final normalized = <String, String>{};
    for (final entry in source.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      final value = entry.value;
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      normalized[key] = text;
    }
    return normalized;
  }

  Future<void> _initializeNotificationRouting() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      _logAuth('Notification permission request failed: $e');
    }

    _onMessageOpenedSubscription?.cancel();
    _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      unawaited(_handleRemoteMessageOpen(message));
    });

    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        unawaited(_handleRemoteMessageOpen(initialMessage));
      }
    } catch (e) {
      _logAuth('getInitialMessage failed: $e');
    }
  }

  Future<void> _handleRemoteMessageOpen(RemoteMessage message) async {
    final payload = _normalizeNotificationPayload(message.data);
    if (payload.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_handleNotificationPayload(payload));
    });
  }

  Future<void> _handleNotificationPayload(Map<String, String> payload) async {
    if (!mounted) return;

    final type = (payload['type'] ?? '').trim();
    final postId = (payload['postId'] ?? '').trim();
    final actorUid = (payload['actorUid'] ?? '').trim();
    final feedbackId = (payload['feedbackId'] ?? '').trim();

    if (_postNotificationTypes.contains(type) && postId.isNotEmpty) {
      await _openMyPostDetail(postId);
      return;
    }

    if (type == 'USER_FOLLOWED' && actorUid.isNotEmpty) {
      await _openUserScreen(actorUid);
      return;
    }

    if (type == 'FEEDBACK_UPDATED' || feedbackId.isNotEmpty) {
      await _openNotificationScreen(initialTabIndex: 1);
      return;
    }

    if (postId.isNotEmpty) {
      await _openMyPostDetail(postId);
      return;
    }

    if (actorUid.isNotEmpty) {
      await _openUserScreen(actorUid);
      return;
    }

    await _openNotificationScreen();
  }

  Future<void> _initializeAuth() async {
    _logAuth('initializeAuth start');
    setState(() {
      _isAuthInitializing = true;
      _authInitError = null;
    });

    if (!mounted) return;
    try {
      _auth = FirebaseAuth.instance;
      _googleSignIn ??= GoogleSignIn();
      _logAuth('FirebaseAuth instance: ${_auth?.app.name}');
      final signedIn = await _googleSignIn?.isSignedIn();
      _logAuth('GoogleSignIn isSignedIn: $signedIn');
      unawaited(_updateFcmTokenForSignedInUser());
      final currentUser = _auth?.currentUser;
      if (currentUser != null) {
        await _upsertUserDocument(currentUser);
      }
    } catch (e) {
      _logAuth('initializeAuth fail: $e');
      if (!mounted) return;
      setState(() {
        _authInitError = e.toString();
      });
    }

    setState(() {
      _isAuthInitializing = false;
    });
  }

  Future<void> _signInWithGoogle() async {
    if (_isAuthLoading) return;
    setState(() => _isAuthLoading = true);
    _lastGoogleSignInError = null;
    _logAuth('Google login start');
    try {
      final auth = _auth;
      final googleSignIn = _googleSignIn;
      if (auth == null || googleSignIn == null) {
        _logAuth('Google login blocked: auth or googleSignIn is null');
        throw Exception('인증 객체 초기화가 안 되어 있습니다. 앱을 다시 시작해 주세요.');
      }

      _logAuth('Calling GoogleSignIn.signIn()');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _logAuth('GoogleSignIn.signIn() returned null (user cancelled)');
        throw Exception('사용자가 Google 로그인 선택을 취소했습니다.');
      }

      _logAuth('Google user email: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      _logAuth(
        'GoogleAuth tokens: accessToken=${googleAuth.accessToken == null ? null : 'present'}, idToken=${googleAuth.idToken == null ? null : 'present'}',
      );
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      _logAuth('Firebase credential created. signInWithCredential()');
      final userCredential = await auth.signInWithCredential(credential);
      await _ensureUserDisplayName(userCredential.user);
      await _upsertUserDocument(userCredential.user);
      unawaited(_updateFcmTokenForSignedInUser());
      _logAuth('Google login success');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google 로그인 성공')));
    } on FirebaseAuthException catch (e, stack) {
      _lastGoogleSignInError =
          'FirebaseAuthException code=${e.code} message=${e.message}';
      _logAuth(
        'Google login FirebaseAuthException: code=${e.code}, message=${e.message}, stack=$stack',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google 로그인 실패(Firebase): ${e.code} / ${e.message ?? e.toString()}',
          ),
        ),
      );
      if (kDebugMode) debugPrint(stack.toString());
    } catch (e, stack) {
      final auth = _auth;
      final hasPigeonCastError =
          e.toString().contains('PigeonUserDetails') &&
          e.toString().contains('List<Object?>');
      if (hasPigeonCastError && auth?.currentUser != null) {
        final recoveredUser = auth!.currentUser;
        _logAuth('Recovered from firebase_auth cast error: $e');
        try {
          await _ensureUserDisplayName(recoveredUser);
          await _upsertUserDocument(recoveredUser);
          unawaited(_updateFcmTokenForSignedInUser());
        } catch (persistError) {
          _logAuth(
            'Post-login persistence failed after recovery: $persistError',
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google 로그인 성공')));
        return;
      }
      _lastGoogleSignInError = e.toString();
      _logAuth('Google login Exception: $e, stack=$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 로그인 실패: $_lastGoogleSignInError')),
      );
      if (kDebugMode) debugPrint(stack.toString());
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (_isAuthLoading) return;
    setState(() => _isAuthLoading = true);
    _logAuth('Apple login start');
    try {
      final auth = _auth;
      if (auth == null) {
        _logAuth('Apple login blocked: auth is null');
        throw Exception('인증 객체 초기화가 안 되어 있습니다. 앱을 다시 시작해 주세요.');
      }
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      final userCredential = await auth.signInWithProvider(provider);
      await _ensureUserDisplayName(userCredential.user);
      await _upsertUserDocument(userCredential.user);
      unawaited(_updateFcmTokenForSignedInUser());
      _logAuth('Apple login success');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Apple 로그인 성공')));
    } on FirebaseAuthException catch (e, stack) {
      _logAuth(
        'Apple login FirebaseAuthException: code=${e.code}, message=${e.message}, stack=$stack',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Apple 로그인 실패(Firebase): ${e.code} / ${e.message ?? e.toString()}',
          ),
        ),
      );
      if (kDebugMode) debugPrint(stack.toString());
    } catch (e) {
      _logAuth('Apple login Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Apple 로그인 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  Future<void> _signInWithNaver() async {
    if (_isAuthLoading) return;
    setState(() => _isAuthLoading = true);
    _logAuth('Naver login start');
    try {
      final result = await _socialCustomAuthService.signInWithNaver();
      await _ensureUserDisplayName(
        result.user,
        fallbackDisplayName: result.displayName,
      );
      await _upsertUserDocument(
        result.user,
        providerId: result.provider,
        providerUid: result.providerUid,
        displayNameOverride: result.displayName,
        emailOverride: result.email,
        photoUrlOverride: result.photoUrl,
      );
      unawaited(_updateFcmTokenForSignedInUser());
      _logAuth('Naver login success');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('네이버 로그인 성공')));
    } on FirebaseFunctionsException catch (e, stack) {
      _logAuth(
        'Naver login FirebaseFunctionsException: code=${e.code}, message=${e.message}, stack=$stack',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('네이버 로그인 실패(Functions): ${e.message ?? e.code}'),
        ),
      );
      if (kDebugMode) debugPrint(stack.toString());
    } catch (e, stack) {
      _logAuth('Naver login Exception: $e, stack=$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('네이버 로그인 실패: $e')));
      if (kDebugMode) debugPrint(stack.toString());
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  Future<void> _signInWithKakao() async {
    if (_isAuthLoading) return;
    setState(() => _isAuthLoading = true);
    _logAuth('Kakao login start');
    try {
      final result = await _socialCustomAuthService.signInWithKakao();
      await _ensureUserDisplayName(
        result.user,
        fallbackDisplayName: result.displayName,
      );
      await _upsertUserDocument(
        result.user,
        providerId: result.provider,
        providerUid: result.providerUid,
        displayNameOverride: result.displayName,
        emailOverride: result.email,
        photoUrlOverride: result.photoUrl,
      );
      unawaited(_updateFcmTokenForSignedInUser());
      _logAuth('Kakao login success');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카카오 로그인 성공')));
    } on FirebaseFunctionsException catch (e, stack) {
      _logAuth(
        'Kakao login FirebaseFunctionsException: code=${e.code}, message=${e.message}, stack=$stack',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카카오 로그인 실패(Functions): ${e.message ?? e.code}'),
        ),
      );
      if (kDebugMode) debugPrint(stack.toString());
    } catch (e, stack) {
      _logAuth('Kakao login Exception: $e, stack=$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카카오 로그인 실패: $e')));
      if (kDebugMode) debugPrint(stack.toString());
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _googleSignIn?.signOut();
    } catch (_) {}
    await _auth?.signOut();
    if (!mounted) return;
    setState(() => _isMySettingsOpen = false);
  }

  Future<void> _withdrawAccount() async {
    final auth = _auth;
    if (auth == null) return;

    final uid = auth.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _isMySettingsOpen = false);
      return;
    }

    try {
      await _socialCustomAuthService.withdrawCurrentUser();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('회원 탈퇴 처리 중 서버 오류가 발생했습니다: ${e.message ?? e.code}'),
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('회원 탈퇴 처리 중 오류가 발생했습니다: $e')));
      return;
    }

    try {
      await _googleSignIn?.signOut();
    } catch (_) {}

    try {
      await _auth?.signOut();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')));
    }

    if (!mounted) return;
    setState(() => _isMySettingsOpen = false);
  }

  void _openSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
  }

  Future<void> _openNotificationScreen({int initialTabIndex = 0}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationScreen(
          initialTabIndex: initialTabIndex,
          onOpenPayload: _handleNotificationPayload,
        ),
      ),
    );
  }

  void _openNotification() {
    unawaited(_openNotificationScreen());
  }

  Future<void> _openFeedDetail(CommunityPost post) {
    final spotOptions = _spotsCollection.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return Navigator.of(context)
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => FeedDetailScreen(
              post: post,
              categories: _postCategories,
              spotOptions: spotOptions,
              todaySlotsDoc: _todaySlotsDoc,
            ),
          ),
        )
        .then((updated) {
          if (updated == true) {
            unawaited(_loadCommunityData());
            if (!mounted || _selectedBottomTab != 3) return;
            setState(() {
              _profileRefreshTick++;
            });
          }
        });
  }

  Future<void> _openMyPostDetail(String postId) async {
    final normalizedPostId = postId.trim();
    if (normalizedPostId.isEmpty) return;

    CommunityPost? selectedPost;
    for (final post in _postsCollection) {
      if (post.postId == normalizedPostId) {
        selectedPost = post;
        break;
      }
    }

    if (selectedPost == null) {
      try {
        selectedPost = await _communityService.getPostById(
          postId: normalizedPostId,
          now: DateTime.now(),
          uid: _auth?.currentUser?.uid ?? 'guest_demo',
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('게시글을 불러오지 못했습니다: $e')));
        return;
      }
    }

    if (!mounted) return;
    if (selectedPost == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글을 찾을 수 없습니다.')));
      return;
    }

    await _openFeedDetail(selectedPost);
  }

  bool _isPostLikedByMe(String postId) {
    return _postLikedByMe[postId] ?? false;
  }

  int _postLikeCount(String postId, int fallback) {
    return _postLikeCounts[postId] ?? fallback;
  }

  Future<Map<String, bool>> _fetchLikeStatuses(
    List<CommunityPost> posts,
  ) async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null || posts.isEmpty) {
      return {for (final post in posts) post.postId: false};
    }

    final entries = await Future.wait(
      posts.map(
        (post) async => MapEntry(
          post.postId,
          await _communityLikeRepository.isLiked(postId: post.postId, uid: uid),
        ),
      ),
    );
    return Map<String, bool>.fromEntries(entries);
  }

  Future<void> _applyCommunityPosts(List<CommunityPost> posts) async {
    final likeMap = await _fetchLikeStatuses(posts);
    final likeCountMap = <String, int>{
      for (final post in posts) post.postId: post.likes,
    };
    if (!mounted) return;
    setState(() {
      _postsCollection = posts;
      _postLikedByMe
        ..clear()
        ..addAll(likeMap);
      _postLikeCounts
        ..clear()
        ..addAll(likeCountMap);
      _isCommunityLoading = false;
    });
  }

  Future<void> _togglePostLike(CommunityPost post) async {
    final uid = _auth?.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    final isRestricted = await UserAccessUtils.isCurrentUserRestricted();
    if (isRestricted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이용금지된 회원입니다. 관리자에게 문의하세요.')),
      );
      return;
    }

    final currentLiked = _postLikedByMe[post.postId] ?? false;
    final currentCount = _postLikeCounts[post.postId] ?? post.likes;
    setState(() {
      _postLikedByMe[post.postId] = !currentLiked;
      _postLikeCounts[post.postId] = !currentLiked
          ? currentCount + 1
          : (currentCount > 0 ? currentCount - 1 : 0);
    });

    try {
      final isLiked = await _communityLikeRepository.toggleLike(
        postId: post.postId,
        uid: uid,
      );
      if (!mounted) return;
      setState(() {
        _postLikedByMe[post.postId] = isLiked;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postLikedByMe[post.postId] = currentLiked;
        _postLikeCounts[post.postId] = currentCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('좋아요 처리 실패: $e')));
    }
  }

  List<String> get _postCategories {
    return _categories.where((category) => category != _allCategory).toList();
  }

  IconData _postCategoryIcon(String category) {
    switch (category) {
      case '자유':
        return Icons.chat_bubble_outline_rounded;
      case '궁금해요':
        return Icons.help_outline_rounded;
      case '오늘의 루트':
        return Icons.route_rounded;
      case '꿀팁':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  Future<String?> _openPostCategorySheet() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final categories = _postCategories;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F5F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9CDD6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 14),
                ...categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).pop(category),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E5EC)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _postCategoryIcon(category),
                              color: const Color(0xFF4D5360),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: Color(0xFF1F2430),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreatePostFlow() async {
    if (_auth?.currentUser == null) {
      setState(() {
        _selectedBottomTab = 3;
        _isMySettingsOpen = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 먼저 해주세요.')));
      return;
    }
    final isRestricted = await UserAccessUtils.isCurrentUserRestricted();
    if (isRestricted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이용금지된 회원입니다. 관리자에게 문의하세요.')),
      );
      return;
    }

    final selectedCategory = await _openPostCategorySheet();
    if (selectedCategory == null || !mounted) return;

    final spotOptions = _spotsCollection.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    final createdPost = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute<CommunityPost>(
        builder: (_) => PostCreateScreen(
          initialCategory: selectedCategory,
          categories: _postCategories,
          spotOptions: spotOptions,
          todaySlotsDoc: _todaySlotsDoc,
        ),
      ),
    );

    if (!mounted || createdPost == null) return;
    setState(() {
      _selectedBottomTab = 0;
      _isMySettingsOpen = false;
      _postLikedByMe[createdPost.postId] = false;
      _postLikeCounts[createdPost.postId] = createdPost.likes;
      _postsCollection = [
        createdPost,
        ..._postsCollection.where((post) => post.postId != createdPost.postId),
      ];
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('게시글이 작성되었습니다.')));
    unawaited(_loadCommunityData());
  }

  Future<void> _openUserScreen(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UserScreen(uid: normalizedUid)),
    );
  }

  Future<void> _openRouteSpotDetail(TodayRootItem routeItem) async {
    final now = DateTime.now();
    final slot = _resolveFacilitySlotFromRoute(routeItem, now);
    await _openSpotDetail(slot, now);
  }

  FacilitySlot _resolveFacilitySlotFromRoute(
    TodayRootItem routeItem,
    DateTime now,
  ) {
    final normalizedSpotId = routeItem.spotId.trim();
    final normalizedSpotName = _normalizeSpotKey(routeItem.spotName);
    for (final doc in _todaySlotsDoc.facilitySlots.values) {
      final byId =
          normalizedSpotId.isNotEmpty &&
          doc.facilityId.trim() == normalizedSpotId;
      final byName =
          normalizedSpotName.isNotEmpty &&
          _normalizeSpotKey(doc.facilityName) == normalizedSpotName;
      if (!byId && !byName) continue;
      return FacilitySlot(
        facilityId: doc.facilityId,
        name: doc.facilityName,
        floor: doc.floor,
        daySlots: doc.slots,
        nextStart: FacilityHelpers.findNextStart(
          slotTimes: doc.slots,
          now: now,
        ),
      );
    }

    final fallbackSpot =
        _spotsCollection[normalizedSpotId] ??
        _spotsCollection[_normalizeSpotKey(routeItem.spotName)];
    if (fallbackSpot != null) {
      return FacilitySlot(
        facilityId: fallbackSpot.spotId,
        name: fallbackSpot.title,
        floor: fallbackSpot.floor,
        daySlots: const [],
        nextStart: null,
      );
    }

    final fallbackName = routeItem.spotName.trim().isNotEmpty
        ? routeItem.spotName.trim()
        : '체험관';
    final fallbackId = routeItem.spotId.trim().isNotEmpty
        ? routeItem.spotId.trim()
        : fallbackName;
    return FacilitySlot(
      facilityId: fallbackId,
      name: fallbackName,
      floor: '',
      daySlots: const [],
      nextStart: null,
    );
  }

  Future<void> _openSpotDetail(FacilitySlot slot, DateTime now) {
    final spot =
        _findSpotBySlot(slot) ??
        SpotDoc(
          spotId: slot.facilityId,
          title: slot.name,
          floor: slot.floor,
          durationMin: 30,
          aptType: '흥미유형 확인필요',
          joyReward: '조이 확인필요',
          ageRule: '연령 기준 확인필요',
          description: '공식 체험관 정보를 준비중입니다.',
          imageUrl: '',
          officialUrl:
              'https://www.koreajobworld.or.kr/exrPreview/exrPreViewList.do?site=1&floor=1&exhpCd=33&portalMenuNo=158',
        );

    final status = FacilityHelpers.statusFor(
      slot: slot,
      bufferMin: _bufferMin,
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

  Future<void> _showBottomSheetAds() async {
    if (!mounted || _hasShownBottomSheetAd) return;
    _hasShownBottomSheetAd = true;

    try {
      final repository = BottomSheetAdRepository();
      final ads = await repository.getValidAds();
      if (!mounted || ads.isEmpty) return;

      final visibleAds = <BottomSheetAdModel>[];
      for (final ad in ads) {
        final hidden = await BottomSheetAdStorage.isAdHiddenToday(ad.adId);
        if (!hidden) {
          visibleAds.add(ad);
        }
      }
      if (!mounted || visibleAds.isEmpty) return;

      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      final result = await showModalBottomSheet<BottomSheetAdSheetResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BottomSheetAdWidget(ads: visibleAds),
      );
      if (!mounted || result == null) return;

      if (result.hideToday) {
        for (final ad in visibleAds) {
          await BottomSheetAdStorage.hideAdForToday(ad.adId);
        }
        return;
      }

      final tappedAd = result.tappedAd;
      if (tappedAd != null) {
        await _handleBottomSheetAdTap(tappedAd);
      }
    } catch (e) {
      debugPrint('[HomeScreen] bottom sheet ad error: $e');
    }
  }

  Future<void> _showStartupPromotions() async {
    final shownDialogAd = await _showDialogAds();
    if (shownDialogAd) return;
    await _showBottomSheetAds();
  }

  Future<bool> _showDialogAds() async {
    if (!mounted || _hasShownDialogAd) return false;
    _hasShownDialogAd = true;

    try {
      final repository = DialogAdRepository();
      final ads = await repository.getValidAds();
      if (!mounted || ads.isEmpty) return false;

      DialogAdModel? selectedAd;
      for (final ad in ads) {
        if (!ad.hasBodyContent) continue;
        final hidden = await DialogAdStorage.isAdHiddenToday(ad.adId);
        if (hidden) continue;
        selectedAd = ad;
        break;
      }
      if (!mounted || selectedAd == null) return false;

      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted) return false;

      final result = await showDialog<DialogAdResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => DialogAdWidget(ad: selectedAd!),
      );
      if (!mounted || result == null) return true;

      if (result.hideToday) {
        await DialogAdStorage.hideAdForToday(selectedAd.adId);
      }
      if (result.openLink) {
        await _handleDialogAdTap(selectedAd);
      }
      return true;
    } catch (e) {
      debugPrint('[HomeScreen] dialog ad error: $e');
      return false;
    }
  }

  Future<void> _handleDialogAdTap(DialogAdModel ad) async {
    final linkValue = ad.linkValue.trim();
    if (linkValue.isEmpty || ad.linkType == DialogAdLinkType.none) return;

    if (ad.linkType == DialogAdLinkType.web) {
      try {
        var url = linkValue;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        final uri = Uri.tryParse(url);
        if (uri == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('링크 형식이 올바르지 않습니다.')));
          return;
        }
        final canOpen = await canLaunchUrl(uri);
        if (!canOpen) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
          return;
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
      }
      return;
    }

    if (ad.linkType == DialogAdLinkType.deeplink &&
        linkValue.startsWith('spot:')) {
      final spotId = linkValue.substring(5).trim();
      if (spotId.isNotEmpty) {
        await _openSpotByIdFromAd(spotId);
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('지원하지 않는 딥링크입니다.')));
  }

  Future<void> _handleBottomSheetAdTap(BottomSheetAdModel ad) async {
    final linkValue = ad.linkValue.trim();
    if (linkValue.isEmpty) return;

    if (ad.linkType == BottomSheetAdLinkType.web) {
      try {
        var url = linkValue;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        final uri = Uri.tryParse(url);
        if (uri == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('링크 형식이 올바르지 않습니다.')));
          return;
        }
        final canOpen = await canLaunchUrl(uri);
        if (!canOpen) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
          return;
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
      }
      return;
    }

    if (linkValue.startsWith('spot:')) {
      final spotId = linkValue.substring(5).trim();
      if (spotId.isNotEmpty) {
        await _openSpotByIdFromAd(spotId);
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('지원하지 않는 딥링크입니다.')));
  }

  Future<void> _openSpotByIdFromAd(String spotId) async {
    final normalizedSpotId = spotId.trim();
    if (normalizedSpotId.isEmpty) return;

    final now = DateTime.now();
    for (final doc in _todaySlotsDoc.facilitySlots.values) {
      if (doc.facilityId.trim() != normalizedSpotId) continue;
      final slot = FacilitySlot(
        facilityId: doc.facilityId,
        name: doc.facilityName,
        floor: doc.floor,
        daySlots: doc.slots,
        nextStart: FacilityHelpers.findNextStart(
          slotTimes: doc.slots,
          now: now,
        ),
      );
      await _openSpotDetail(slot, now);
      return;
    }

    SpotDoc? spot = _spotsCollection[normalizedSpotId];
    if (spot == null) {
      for (final candidate in _spotsCollection.values) {
        if (candidate.spotId == normalizedSpotId) {
          spot = candidate;
          break;
        }
      }
    }
    final fallbackSlot = FacilitySlot(
      facilityId: normalizedSpotId,
      name: spot?.title ?? normalizedSpotId,
      floor: spot?.floor ?? '',
      daySlots: const [],
      nextStart: null,
    );
    await _openSpotDetail(fallbackSlot, now);
  }

  Widget _buildCommunityBody() {
    if (_isCommunityLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_communityLoadError != null) {
      return RefreshIndicator(
        color: const Color(0xFFED9A3A),
        onRefresh: _loadCommunityData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            AppTopHeader(
              title: '커뮤니티',
              onSearchTap: _openSearch,
              onNotificationTap: _openNotification,
            ),
            const SizedBox(height: 8),
            const Text(
              '커뮤니티 데이터를 불러오지 못했습니다.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3342),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _communityLoadError!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A8190)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadCommunityData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFED9A3A),
      onRefresh: _loadCommunityData,
      child: FeedScreen(
        categories: _categories,
        selectedCategory: _selectedCategory,
        posts: _filteredPosts,
        onLikeTap: _togglePostLike,
        isLikedByMe: _isPostLikedByMe,
        likeCountByPostId: _postLikeCount,
        onCategorySelected: (category) {
          setState(() => _selectedCategory = category);
        },
        onSearchTap: _openSearch,
        onNotificationTap: _openNotification,
        onPostTap: _openFeedDetail,
        onAuthorTap: (post) => _openUserScreen(post.uid),
        onRouteItemTap: _openRouteSpotDetail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final slots = FacilityHelpers.buildCurrentSlots(
      todaySlotsDoc: _todaySlotsDoc,
      now: now,
    );
    Widget body;
    switch (_selectedBottomTab) {
      case 0:
        body = _buildCommunityBody();
        break;
      case 1:
        body = _buildSpotBody(now: now, slots: slots);
        break;
      case 2:
        body = JoyScreen(
          onSearchTap: _openSearch,
          onNotificationTap: _openNotification,
        );
        break;
      case 3:
      default:
        body = ProfileScreen(
          key: ValueKey<int>(_profileRefreshTick),
          isAuthInitializing: _isAuthInitializing,
          isAuthLoading: _isAuthLoading,
          authInitError: _authInitError,
          isSignedIn: _auth?.currentUser != null,
          isSettingsOpen: _isMySettingsOpen,
          onRetryAuth: _initializeAuth,
          onGoogleLogin: _signInWithGoogle,
          onAppleLogin: _signInWithApple,
          onNaverLogin: _signInWithNaver,
          onKakaoLogin: _signInWithKakao,
          onOpenSettings: () => setState(() => _isMySettingsOpen = true),
          onCloseSettings: () => setState(() => _isMySettingsOpen = false),
          onSignOut: _signOut,
          onWithdraw: _withdrawAccount,
          onSearchTap: _openSearch,
          onNotificationTap: _openNotification,
          onMyPostTap: _openMyPostDetail,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: FloatingBottomNav(
                          selectedIndex: _selectedBottomTab,
                          onSelect: (index) {
                            setState(() {
                              _selectedBottomTab = index;
                              if (index != 3) {
                                _isMySettingsOpen = false;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: _openCreatePostFlow,
                      backgroundColor: const Color(0xFFED9A3A),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.add, size: 34),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
