import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:demo_pages/Component/JournalCard/JournalCard.dart';
import 'package:demo_pages/Models/JournalEntry.dart';
import 'package:demo_pages/Pages/HomePage/HomePage.dart';
import 'package:demo_pages/Pages/HomePage/HomePageController.dart';
import 'package:demo_pages/Utils/app_settings.dart';
import 'package:demo_pages/Utils/formatters.dart';
import 'package:demo_pages/Utils/journal_store.dart';
import 'package:demo_pages/Utils/photo_store.dart';
import 'package:demo_pages/main.dart';

/// Builds the real app shell around an in-memory journal so the tests never
/// touch the file system, then waits out the fake 300 ms load.
Future<HomePageController> _pumpApp(
  WidgetTester tester, {
  AppSettings? settings,
  JournalStore? journal,
}) async {
  final JournalStore store = journal ?? JournalStore.inMemory();
  final HomePageController controller = HomePageController(
    store: store,
    photos: PhotoStore.inMemory(),
  );
  await tester.pumpWidget(
    DemoApp(
      settings: settings ?? AppSettings(),
      journal: store,
      photos: PhotoStore.inMemory(),
      home: HomePage(controller: controller),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('AC-S3-1 Add page offers camera, gallery and an empty photo slot', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const Key('openAdd')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pickFromGallery')), findsOneWidget);
    expect(find.byKey(const Key('pickFromCamera')), findsOneWidget);
    expect(find.byKey(const Key('addPhotoPlaceholder')), findsOneWidget);
    expect(find.byKey(const Key('removePhoto')), findsNothing);
  });

  testWidgets('AC-S3-2 a card without a photo shows the placeholder square', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byKey(const Key('cardPhotoPlaceholder')), findsNWidgets(3));
    expect(find.byKey(const Key('cardPhoto')), findsNothing);
  });

  testWidgets('AC-S3-3 a card with a photo paints the image', (
    WidgetTester tester,
  ) async {
    final Directory dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp('card-photo'),
    ) as Directory;
    addTearDown(() => dir.delete(recursive: true));

    final File file = File('${dir.path}${Platform.pathSeparator}a.png');
    await tester.runAsync(
      () => file.writeAsBytes(<int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalCard(
            entry: JournalEntry(
              title: 'With photo',
              note: 'has an image',
              createdAt: DateTime(2026, 10, 1),
              photoPath: 'a.png',
            ),
            imagePath: file.path,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('cardPhoto')), findsOneWidget);
    expect(find.byKey(const Key('cardPhotoPlaceholder')), findsNothing);
  });

  testWidgets('AC-S3-4 Detail shows the created date through a placeholder', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Halley cells'));
    await tester.pumpAndSettle();

    final String text = tester
        .widget<Text>(find.byKey(const Key('DetailCreatedOn')))
        .data!;
    expect(text.startsWith('Created on '), isTrue);
    expect(text.contains('2026'), isTrue);
    expect(find.byKey(const Key('detailPhotoPlaceholder')), findsOneWidget);
  });

  testWidgets('AC-S3-5 Settings reports storage and switches to Chinese', (
    WidgetTester tester,
  ) async {
    final AppSettings settings = AppSettings();
    await settings.load();
    await _pumpApp(tester, settings: settings);

    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('storageUsed')), findsOneWidget);
    expect(find.textContaining('KB used'), findsOneWidget);

    await tester.tap(find.byKey(const Key('languageChinese')));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(settings.localeCode, 'zh');
  });

  testWidgets('AC-S3-6 clear all needs two confirmations, then empties list', (
    WidgetTester tester,
  ) async {
    final JournalStore store = JournalStore.inMemory(
      entries: <JournalEntry>[
        JournalEntry(
          title: 'One',
          note: 'first',
          createdAt: DateTime(2026, 10, 1),
        ),
      ],
    );
    await _pumpApp(tester, journal: store);
    expect(find.text('One'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();
    // Session 4 grew the page (Background section), so the destructive button
    // sits below a 600 px viewport. Rather than scroll (which leaves the list
    // mid-fling), give this test a tall window.
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clearAllButton')));
    await tester.pumpAndSettle();

    // First dialog: cancel → nothing changes.
    await tester.tap(find.byKey(const Key('clearCancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clearConfirmDialog')), findsNothing);

    await tester.tap(find.byKey(const Key('clearAllButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clearConfirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clearConfirmAgainDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clearAgainConfirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('0 KB used'), findsOneWidget);

    // The list is tall, so the "Back" text button sits below the fold of the
    // test viewport; the AppBar back arrow does the same job.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emptyList')), findsOneWidget);
  });

  testWidgets('AC-S3-7 the chosen language survives a restart', (
    WidgetTester tester,
  ) async {
    final AppSettings first = AppSettings();
    await first.load();
    await first.setLocaleCode('zh_Hant');
    expect(first.locale?.toLanguageTag(), 'zh-Hant');

    final AppSettings reloaded = AppSettings();
    await reloaded.load();
    expect(reloaded.localeCode, 'zh_Hant');
  });

  test('AC-S3-8 storage text rounds down so a cleared journal reads 0 KB', () {
    expect(formatStorageSize(0), '0 KB');
    expect(formatStorageSize(651), '0 KB');
    expect(formatStorageSize(2048), '2 KB');
    expect(formatStorageSize(3 * 1024 * 1024), '3.0 MB');
  });
}
