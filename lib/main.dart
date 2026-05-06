import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';

import 'app/jobworld_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppBootstrap());
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  Object? _startupError;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    setState(() {
      _startupError = null;
      _isReady = false;
    });

    try {
      await _initializeFirebase();
      unawaited(_initializeMobileAds());
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app startup',
          context: ErrorDescription('while initializing Firebase'),
        ),
      );
      if (!mounted) return;
      setState(() => _startupError = error);
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        rethrow;
      }
    }
  }

  Future<void> _initializeMobileAds() async {
    try {
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'app startup',
          context: ErrorDescription('while initializing Google Mobile Ads'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return const JobWorldApp();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '꿈의카드',
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF9F2),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _startupError == null
                  ? const _StartupLoadingView()
                  : _StartupErrorView(
                      error: _startupError!,
                      onRetry: () => unawaited(_initialize()),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupLoadingView extends StatelessWidget {
  const _StartupLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            color: Color(0xFFED9A3A),
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: 18),
        Text(
          '꿈의카드',
          style: TextStyle(
            color: Color(0xFF181A21),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFED9A3A),
          size: 42,
        ),
        const SizedBox(height: 14),
        const Text(
          '앱을 시작하지 못했습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF181A21),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF6F7480),
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFED9A3A),
            foregroundColor: Colors.white,
          ),
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}
