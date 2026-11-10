import 'dart:async';

import 'package:flutter/material.dart';

import 'Pages/HomePage/HomePage.dart';
import 'Pages/HomePage/HomePageController.dart';
import 'Utils/app_scope.dart';
import 'Utils/app_settings.dart';
import 'Utils/journal_store.dart';
import 'Utils/photo_store.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppSettings settings = AppSettings();
  final PhotoStore photos = PhotoStore();
  final JournalStore journal = JournalStore();

  // Both are cheap and must be finished before the first frame: the language
  // decides which strings to paint, and the photo directory must exist before
  // any card tries to resolve a file name to a path.
  await settings.load();
  await photos.ensureReady();

  runApp(DemoApp(settings: settings, photos: photos, journal: journal));
}

/// Root widget: owns the app-wide services and the single home controller.
///
/// Tests pass their own in-memory stores and, when they only exercise one page,
/// a [home] widget; nothing here touches the file system unless the real stores
/// were handed in by [main].
class DemoApp extends StatefulWidget {
  const DemoApp({
    super.key,
    this.settings,
    this.photos,
    this.journal,
    this.home,
  });

  final AppSettings? settings;
  final PhotoStore? photos;
  final JournalStore? journal;
  final Widget? home;

  static const Color seedColor = Color(0xFF2E6F95);

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final AppSettings _settings;
  late final PhotoStore _photos;
  late final JournalStore _journal;

  HomePageController? _homeController;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? AppSettings();
    _photos = widget.photos ?? PhotoStore.inMemory();
    _journal = widget.journal ?? JournalStore.inMemory();
    if (widget.settings == null) {
      unawaited(_settings.load());
    }
  }

  @override
  void dispose() {
    _homeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      photos: _photos,
      journal: _journal,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (BuildContext context, Widget? _) {
          return MaterialApp(
            title: 'EduSnap',
            debugShowCheckedModeBanner: false,
            locale: _settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: DemoApp.seedColor),
            ),
            home:
                widget.home ??
                HomePage(
                  controller: _homeController ??= HomePageController(
                    store: _journal,
                    photos: _photos,
                  ),
                ),
          );
        },
      ),
    );
  }
}
