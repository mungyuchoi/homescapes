import "dart:convert";
import "dart:math";

import "package:cloud_functions/cloud_functions.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter_web_auth_2/flutter_web_auth_2.dart";

class CustomProviderSignInResult {
  const CustomProviderSignInResult({
    required this.user,
    this.userCredential,
    required this.provider,
    required this.providerUid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  final User user;
  final UserCredential? userCredential;
  final String provider;
  final String providerUid;
  final String displayName;
  final String email;
  final String photoUrl;
}

class SocialCustomAuthService {
  SocialCustomAuthService({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: "asia-northeast3"),
      _auth = auth ?? FirebaseAuth.instance;

  static const String _callbackScheme = "jobworld";
  static const String _naverRedirectUri =
      "https://asia-northeast3-jobworld-e3988.cloudfunctions.net/naverOauthBridge";
  static const String _kakaoRedirectUri =
      "https://asia-northeast3-jobworld-e3988.cloudfunctions.net/kakaoOauthBridge";
  static const String _naverClientId = String.fromEnvironment(
    "NAVER_CLIENT_ID",
  );
  static const String _kakaoRestApiKey = String.fromEnvironment(
    "KAKAO_REST_API_KEY",
  );

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final Random _secureRandom = Random.secure();

  Future<CustomProviderSignInResult> signInWithNaver() async {
    if (_naverClientId.isEmpty) {
      throw StateError("NAVER_CLIENT_ID가 비어 있습니다. --dart-define로 설정해 주세요.");
    }

    final state = _generateState();
    final authorizeUri = Uri.https("nid.naver.com", "/oauth2.0/authorize", {
      "response_type": "code",
      "client_id": _naverClientId,
      "redirect_uri": _naverRedirectUri,
      "state": state,
    });

    final callbackUri = await _startOAuthInBrowser(authorizeUri: authorizeUri);
    final callable = _functions.httpsCallable("createNaverCustomToken");

    return _signInWithCustomToken(
      callbackUri: callbackUri,
      expectedState: state,
      redirectUri: _naverRedirectUri,
      providerFallback: "naver",
      providerLabel: "네이버",
      callable: callable,
    );
  }

  Future<CustomProviderSignInResult> signInWithKakao() async {
    if (_kakaoRestApiKey.isEmpty) {
      throw StateError("KAKAO_REST_API_KEY가 비어 있습니다. --dart-define로 설정해 주세요.");
    }

    final state = _generateState();
    final authorizeUri = Uri.https("kauth.kakao.com", "/oauth/authorize", {
      "response_type": "code",
      "client_id": _kakaoRestApiKey,
      "redirect_uri": _kakaoRedirectUri,
      "state": state,
      "scope": "profile_nickname,profile_image",
    });

    final callbackUri = await _startOAuthInBrowser(authorizeUri: authorizeUri);
    final callable = _functions.httpsCallable("createKakaoCustomToken");

    return _signInWithCustomToken(
      callbackUri: callbackUri,
      expectedState: state,
      redirectUri: _kakaoRedirectUri,
      providerFallback: "kakao",
      providerLabel: "카카오",
      callable: callable,
    );
  }

  Future<void> withdrawCurrentUser() async {
    final callable = _functions.httpsCallable("withdrawAccount");
    await callable.call(<String, dynamic>{});
  }

  Future<Uri> _startOAuthInBrowser({required Uri authorizeUri}) async {
    final callbackUrl = await FlutterWebAuth2.authenticate(
      url: authorizeUri.toString(),
      callbackUrlScheme: _callbackScheme,
    );
    return Uri.parse(callbackUrl);
  }

  Future<CustomProviderSignInResult> _signInWithCustomToken({
    required Uri callbackUri,
    required String expectedState,
    required String redirectUri,
    required String providerFallback,
    required String providerLabel,
    required HttpsCallable callable,
  }) async {
    final oauthError = _readString(callbackUri.queryParameters["error"]);
    if (oauthError.isNotEmpty) {
      final description = _readString(
        callbackUri.queryParameters["error_description"],
      );
      final message = description.isNotEmpty ? description : oauthError;
      throw StateError("$providerLabel OAuth 실패: $message");
    }

    final code = _readString(callbackUri.queryParameters["code"]);
    final returnedState = _readString(callbackUri.queryParameters["state"]);
    if (code.isEmpty) {
      throw StateError("$providerLabel OAuth code를 받지 못했습니다.");
    }
    if (returnedState.isEmpty || returnedState != expectedState) {
      throw StateError("$providerLabel OAuth state 검증에 실패했습니다.");
    }

    final result = await callable.call(<String, dynamic>{
      "code": code,
      "state": returnedState,
      "redirectUri": redirectUri,
    });

    final payload = _toMap(result.data);
    final customToken = _readString(payload["customToken"]);
    if (customToken.isEmpty) {
      throw StateError("$providerLabel custom token을 받지 못했습니다.");
    }

    UserCredential? credential;
    User? signedInUser;
    try {
      credential = await _auth.signInWithCustomToken(customToken);
      signedInUser = credential.user ?? _auth.currentUser;
    } catch (error) {
      if (!_isRecoverablePigeonDecodeError(error)) {
        rethrow;
      }
      signedInUser = await _resolveCurrentUserAfterSignIn();
      if (signedInUser == null) {
        rethrow;
      }
    }

    if (signedInUser == null) {
      throw StateError("$providerLabel 로그인 사용자 정보를 확인하지 못했습니다.");
    }

    final provider = _readString(payload["provider"]);
    return CustomProviderSignInResult(
      user: signedInUser,
      userCredential: credential,
      provider: provider.isNotEmpty ? provider : providerFallback,
      providerUid: _readString(payload["providerUid"]),
      displayName: _readString(payload["displayName"]),
      email: _readString(payload["email"]),
      photoUrl: _readString(payload["photoUrl"]),
    );
  }

  String _generateState() {
    final bytes = List<int>.generate(24, (_) => _secureRandom.nextInt(256));
    return base64UrlEncode(bytes).replaceAll("=", "");
  }

  bool _isRecoverablePigeonDecodeError(Object error) {
    final message = error.toString();
    return message.contains("PigeonUserCredential.decode") ||
        message.contains("PigeonUserDetails?") ||
        message.contains("List<Object?>") ||
        message.contains("is not a subtype of type");
  }

  Future<User?> _resolveCurrentUserAfterSignIn() async {
    User? user = _auth.currentUser;
    if (user != null) return user;

    await Future<void>.delayed(const Duration(milliseconds: 120));
    user = _auth.currentUser;
    if (user != null) return user;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _auth.currentUser;
  }

  String _readString(Object? value) {
    if (value is String) {
      return value.trim();
    }
    return "";
  }

  Map<String, dynamic> _toMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) {
        return MapEntry(key.toString(), item);
      });
    }
    return <String, dynamic>{};
  }
}
