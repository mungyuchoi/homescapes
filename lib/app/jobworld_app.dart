import 'package:flutter/material.dart';

import '../screens/home_screen.dart';

class JobWorldApp extends StatefulWidget {
  const JobWorldApp({super.key});

  @override
  State<JobWorldApp> createState() => _JobWorldAppState();
}

class _JobWorldAppState extends State<JobWorldApp> {
  static const _primary = Color(0xFFE56702); // Homescapes brand orange
  static const _accent = Color(0xFFFFF400); // Homescapes contrast yellow
  static const _support = Color(0xFF00EFFF); // Homescapes accent cyan
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Homescapes Helper',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF9F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          secondary: _accent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
          toolbarTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
        ),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF18181B),
              displayColor: const Color(0xFF18181B),
            ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121417),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          secondary: _support,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121417),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF2F4F8),
          ),
          toolbarTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF2F4F8),
          ),
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(0xFFF2F4F8),
              displayColor: const Color(0xFFF2F4F8),
            ),
      ),
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) {
          setState(() => _themeMode = mode);
        },
      ),
    );
  }
}
