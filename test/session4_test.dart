import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itchi_flutter_duo_layout/itchi_flutter_duo_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demo_pages/Component/BackgroundLayer/BackgroundLayer.dart';
import 'package:demo_pages/Models/AppVersion.dart';
import 'package:demo_pages/Pages/HomePage/HomePageController.dart';
import 'package:demo_pages/Pages/Settings/SettingsPage.dart';
import 'package:demo_pages/Pages/Settings/SettingsPageController.dart';
import 'package:demo_pages/Utils/app_settings.dart';
import 'package:demo_pages/Utils/app_theme.dart';
import 'package:demo_pages/Utils/duo_layout.dart';
import 'package:demo_pages/Utils/journal_store.dart';
import 'package:demo_pages/Utils/photo_store.dart';
import 'package:demo_pages/main.dart';

/// Stands in for the platform channel: no plugin, no iOS, fully scripted.
class _FakeDuoBridge implements DuoBridge {
  _FakeDuoBridge({
    this.status = ItchiSideBackStatus.unsupportedPlatform,
    this.throws = false,
  });

  final ItchiSideBackStatus status;
  final bool throws;

  final StreamController<void> backCalls = StreamController<void>.broadcast();
  final StreamController<DuoFoldSnapshot> foldEvents =
      StreamController<DuoFoldSnapshot>.broadcast();

  bool visible = false;

  @override
  Future<ItchiSideBackStatus> setSideBackVisible(bool value) async {
    if (throws) {
      throw StateError('channel missing');
    }
    visible = value;
    return status;
  }

  @override
  Stream<void> get onBack => backCalls.stream;

  @override
  Stream<DuoFoldSnapshot> get foldSnapshots => foldEvents.stream;
}

DuoFoldSnapshot _fullyOpenSnapshot() => DuoFoldSnapshot.fromMessage(
  <String, Object?>{
    'version': 1,
    'availability': 'available',
    'pose': 'fullyOpen',
    'hingeStatus': 'fullyOpen',
    'angleDegrees': 180.0,
    'windowWidth': 900.0,
    'windowHeight': 700.0,
    'spansBothPanes': true,
  },
);

SettingsPageController _settingsController({
  Future<AppVersion> Function()? loadVersion,
}) {
  return SettingsPageController(
    settings: AppSettings(),
    photos: PhotoStore.inMemory(),
    journal: JournalStore.inMemory(),
    clearEntries: () async => 0,
    loadVersion: loadVersion,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('AC-S4-01 the theme carries the deck palette', () {
    final ColorScheme scheme = AppTheme.light().colorScheme;
    expect(scheme.primary, AppTheme.primary);
    expect(scheme.secondary, AppTheme.secondary);
    expect(scheme.tertiary, AppTheme.accent);
    expect(scheme.surface, AppTheme.background);
    expect(AppTheme.primary, const Color(0xFF025928));
    expect(AppTheme.secondary, const Color(0xFFF25D27));
    expect(AppTheme.accent, const Color(0xFFD9653B));
    expect(AppTheme.surface, const Color(0xFFF2B29B));
    expect(AppTheme.background, const Color(0xFFF2F2F2));
  });

  test('AC-S4-02 the AppBar sits on the primary colour', () {
    final ThemeData theme = AppTheme.light();
    expect(theme.appBarTheme.backgroundColor, AppTheme.primary);
    expect(theme.appBarTheme.foregroundColor, Colors.white);
    expect(theme.scaffoldBackgroundColor, AppTheme.background);
  });

  test('AC-S4-03 version comes from the build, not from disk', () async {
    final SettingsPageController controller = _settingsController(
      loadVersion: () async =>
          const AppVersion(version: '1.1.0', buildNumber: '2'),
    );
    await controller.refreshVersion();
    expect(controller.version.version, '1.1.0');
    expect(controller.version.buildNumber, '2');
    controller.dispose();
  });

  test('AC-S4-04 a failing channel degrades to unknown, never throws', () async {
    final SettingsPageController controller = _settingsController(
      loadVersion: () async => throw StateError('no platform channel'),
    );
    await controller.refreshVersion();
    expect(controller.version, AppVersion.unknown);
    controller.dispose();
  });

  testWidgets('AC-S4-05 Settings paints version and build number', (
    WidgetTester tester,
  ) async {
    final HomePageController home = HomePageController(
      store: JournalStore.inMemory(),
      photos: PhotoStore.inMemory(),
    );
    final SettingsPageController settings = _settingsController(
      loadVersion: () async =>
          const AppVersion(version: '1.1.0', buildNumber: '2'),
    );

    await tester.pumpWidget(
      DemoApp(
        settings: AppSettings(),
        journal: JournalStore.inMemory(),
        photos: PhotoStore.inMemory(),
        home: SettingsPage(
          entryCount: () => 0,
          controller: settings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('appVersion')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Version 1.1.0 (build 2)'), findsOneWidget);
    home.dispose();
    settings.dispose();
  });

  test('AC-S4-06 non-iOS keeps the rail off and the app usable', () async {
    final _FakeDuoBridge bridge = _FakeDuoBridge();
    final DuoLayoutController duo = DuoLayoutController(bridge: bridge);

    await duo.start();
    expect(duo.railActive, isFalse);
    expect(bridge.visible, isTrue, reason: 'the call is still attempted');
    expect(duo.fold, isNull);

    await duo.stop();
    expect(bridge.visible, isFalse);
  });

  test('AC-S4-07 a missing channel degrades like a non-Duo device', () async {
    final DuoLayoutController duo = DuoLayoutController(
      bridge: _FakeDuoBridge(throws: true),
    );
    await duo.start();
    expect(duo.railActive, isFalse);
    await duo.stop();
  });

  test('AC-S4-08 an available rail reports active and forwards Back', () async {
    final _FakeDuoBridge bridge = _FakeDuoBridge(
      status: ItchiSideBackStatus.available,
    );
    final DuoLayoutController duo = DuoLayoutController(bridge: bridge);

    int backs = 0;
    await duo.start(onBack: () => backs++);
    expect(duo.railActive, isTrue);

    bridge.backCalls.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(backs, 1);

    await duo.stop();
    expect(duo.railActive, isFalse);
  });

  test('AC-S4-09 the fold stream decides two panes', () async {
    final _FakeDuoBridge bridge = _FakeDuoBridge(
      status: ItchiSideBackStatus.available,
    );
    final DuoLayoutController duo = DuoLayoutController(bridge: bridge);
    await duo.start();

    expect(duo.wantsTwoPanes(const Size(400, 800)), isFalse);

    bridge.foldEvents.add(_fullyOpenSnapshot());
    await Future<void>.delayed(Duration.zero);

    expect(duo.fold?.isAvailable, isTrue);
    expect(duo.wantsTwoPanes(const Size(900, 700)), isTrue);
    expect(
      duo.wantsTwoPanes(const Size(400, 800)),
      isFalse,
      reason: 'a narrow window stays single pane even when fully open',
    );

    await duo.stop();
  });

  test('AC-S4-11 the background picture and its opacity survive a restart', () async {
    final AppSettings settings = AppSettings();
    await settings.load();
    expect(settings.backgroundImage, isNull);
    expect(settings.backgroundOpacity, AppSettings.defaultBackgroundOpacity);

    await settings.setBackgroundImage('p-bg.jpg');
    await settings.setBackgroundOpacity(0.6);

    final AppSettings rehydrated = AppSettings();
    await rehydrated.load();
    expect(rehydrated.backgroundImage, 'p-bg.jpg');
    expect(rehydrated.backgroundOpacity, closeTo(0.6, 1e-9));

    await rehydrated.setBackgroundImage(null);
    final AppSettings cleared = AppSettings();
    await cleared.load();
    expect(cleared.backgroundImage, isNull);
  });

  test('AC-S4-12 opacity is clamped to the slider range', () async {
    final AppSettings settings = AppSettings();
    await settings.load();

    await settings.setBackgroundOpacity(5.0);
    expect(settings.backgroundOpacity, AppSettings.maxBackgroundOpacity);

    await settings.setBackgroundOpacity(-1.0);
    expect(settings.backgroundOpacity, AppSettings.minBackgroundOpacity);
  });

  testWidgets('AC-S4-13 no picture means no extra layer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BackgroundLayer(
          imagePath: null,
          opacity: 0.5,
          child: Text('page'),
        ),
      ),
    );
    expect(find.byKey(const Key('backgroundImage')), findsNothing);
    expect(find.text('page'), findsOneWidget);
  });

  test('AC-S4-10 without a hinge a large window still splits', () async {
    final DuoLayoutController duo = DuoLayoutController(
      bridge: _FakeDuoBridge(),
    );
    await duo.start();
    expect(duo.wantsTwoPanes(const Size(900, 700)), isTrue);
    expect(duo.wantsTwoPanes(const Size(500, 900)), isFalse);
    await duo.stop();
  });
}
