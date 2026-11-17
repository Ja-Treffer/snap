import 'dart:async';

import 'package:flutter/material.dart';

import 'Component/BackgroundLayer/BackgroundLayer.dart';
import 'Pages/HomePage/HomePage.dart';
import 'Pages/HomePage/HomePageController.dart';
import 'Utils/app_scope.dart';
import 'Utils/app_settings.dart';
import 'Utils/app_theme.dart';
import 'Utils/duo_layout.dart';
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

  runApp(
    DemoApp(
      settings: settings,
      photos: photos,
      journal: journal,
      // PART 04: real bridge only in the running app; tests pass none and the
      // pages behave exactly like a non-Duo device.
      duo: DuoLayoutController(),
    ),
  );
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
    this.duo,
  });

  final AppSettings? settings;
  final PhotoStore? photos;
  final JournalStore? journal;
  final Widget? home;

  /// Session 4 · PART 04. Null means "no native Duo bridge" (tests, and any
  /// host that does not want the side rail).
  final DuoLayoutController? duo;

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final AppSettings _settings;
  late final PhotoStore _photos;
  late final JournalStore _journal;

  HomePageController? _homeController;
  DuoLayoutController? _duo;

  /// Native rail Back calls `maybePop()` on this navigator.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? AppSettings();
    _photos = widget.photos ?? PhotoStore.inMemory();
    _journal = widget.journal ?? JournalStore.inMemory();
    if (widget.settings == null) {
      unawaited(_settings.load());
    }
    _duo = widget.duo;
    if (_duo != null) {
      unawaited(
        _duo!.start(
          onBack: () => _navigatorKey.currentState?.maybePop(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _duo?.dispose();
    _homeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      photos: _photos,
      journal: _journal,
      duo: _duo,
      child: ListenableBuilder(
        // Rebuild the app when the language changes and when the fold / side
        // rail state changes: both are read all over the tree.
        listenable: Listenable.merge(<Listenable?>[_settings, _duo]),
        builder: (BuildContext context, Widget? _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context).app_title,
            debugShowCheckedModeBanner: false,
            locale: _settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.light(
              transparentScaffold: _settings.backgroundImage != null,
            ),
            // The background picture sits behind the whole app; the scaffold is
            // transparent when one is set (see AppTheme.light).
            builder: (BuildContext context, Widget? child) {
              return BackgroundLayer(
                imagePath: _photos.pathOf(_settings.backgroundImage),
                opacity: _settings.backgroundOpacity,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home:
                widget.home ??
                HomePage(
                  controller: _homeController ??= HomePageController(
                    store: _journal,
                    photos: _photos,
                    settings: _settings,
                  ),
                ),
          );
        },
      ),
    );
  }
}
