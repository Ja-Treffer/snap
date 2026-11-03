import 'package:flutter/material.dart';

import 'Pages/HomePage/HomePage.dart';

void main() {
  runApp(const DemoApp());
}

/// Root widget. Keeps the theme in one place so every page looks the same.
///
/// [home] is only for tests: they pass a HomePage built with an in-memory
/// controller so nothing touches the file system.
class DemoApp extends StatelessWidget {
  const DemoApp({super.key, this.home});

  final Widget? home;

  static const Color seedColor = Color(0xFF2E6F95);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      ),
      home: home ?? const HomePage(),
    );
  }
}
