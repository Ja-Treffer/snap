import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo_pages/Component/JournalCard/JournalCard.dart';
import 'package:demo_pages/Pages/HomePage/HomePage.dart';
import 'package:demo_pages/Pages/HomePage/HomePageController.dart';
import 'package:demo_pages/Utils/journal_store.dart';
import 'package:demo_pages/main.dart';

/// Home loads its data with a 300ms delay, so every test that expects the list
/// waits for it once.
///
/// The store is injected as [JournalStore.inMemory]: real file I/O never
/// finishes under the widget-test fake clock, which would leave the spinner
/// spinning forever.
Future<void> _pumpApp(WidgetTester tester) async {
  final HomePageController controller = HomePageController(
    store: JournalStore.inMemory(),
    loadDelay: HomePageController.defaultLoadDelay,
  );
  await tester.pumpWidget(DemoApp(home: HomePage(controller: controller)));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AC-1 Home is the List page showing its three dummy entries', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('List'), findsOneWidget);
    expect(find.byType(JournalCard), findsNWidgets(3));
    expect(find.text('Halley cells'), findsOneWidget);
    expect(find.text('Fractions'), findsOneWidget);
    expect(find.text('Water cycle'), findsOneWidget);
  });

  testWidgets('AC-2 the temporary buttons are gone, AppBar carries actions', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byKey(const Key('goDetail')), findsNothing);
    expect(find.byKey(const Key('goAdd')), findsNothing);
    expect(find.byKey(const Key('goSettings')), findsNothing);
    expect(find.byKey(const Key('openAdd')), findsOneWidget);
    expect(find.byKey(const Key('openSettings')), findsOneWidget);
  });

  testWidgets('AC-3 tapping a card opens Detail with that entry', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Fractions'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('DetailTitle')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('DetailTitle'))).data,
      'Fractions',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('DetailNote'))).data,
      'A fraction is part of a whole. One half is written as 1/2.',
    );

    await tester.tap(find.byKey(const Key('DetailBack')));
    await tester.pumpAndSettle();
    expect(find.text('List'), findsOneWidget);
  });

  testWidgets('AC-4 AppBar add button opens AddPage, Back pops', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('openAdd')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('titleField')), findsOneWidget);

    await tester.tap(find.byKey(const Key('AddBack')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('titleField')), findsNothing);
    expect(find.text('List'), findsOneWidget);
  });

  testWidgets('AC-5 AppBar settings button opens SettingsPage, Back pops', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();
    // Session 4 added the About/version block, so Back now sits below the fold
    // on a 600 px test viewport — bring it into view before tapping.
    await tester.scrollUntilVisible(
      find.byKey(const Key('SettingsBack')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('SettingsBack')), findsOneWidget);

    await tester.tap(find.byKey(const Key('SettingsBack')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('SettingsBack')), findsNothing);
    expect(find.text('List'), findsOneWidget);
  });

  testWidgets('AC-6 saving a new entry puts it on top of the list', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('openAdd')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('titleField')), 'Photosynthesis');
    await tester.enterText(find.byKey(const Key('noteField')), 'Leaves make food.');
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Photosynthesis'), findsOneWidget);
    expect(find.byType(JournalCard), findsNWidgets(4));

    final double newTop = tester
        .getTopLeft(find.text('Photosynthesis'))
        .dy;
    final double oldTop = tester.getTopLeft(find.text('Halley cells')).dy;
    expect(newTop, lessThan(oldTop));
  });

  testWidgets('AC-7 a completely empty form is rejected with a dialog', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('openAdd')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emptyEntryDialog')), findsOneWidget);
    expect(find.text('Nothing to save'), findsOneWidget);

    await tester.tap(find.byKey(const Key('emptyEntryOk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emptyEntryDialog')), findsNothing);
    // Still on the Add page (the List route is offstage), nothing was saved.
    expect(find.byKey(const Key('titleField')), findsOneWidget);
  });

  testWidgets('AC-7b a note without a title is saved as Untitled', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('openAdd')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('noteField')),
      'Only a note was typed.',
    );
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Untitled'), findsOneWidget);
    expect(find.text('Only a note was typed.'), findsOneWidget);
    expect(find.byType(JournalCard), findsNWidgets(4));
  });

  testWidgets('AC-8 swipe left + confirm deletes an entry', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.drag(find.text('Water cycle'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deleteConfirm')), findsOneWidget);
    await tester.tap(find.byKey(const Key('deleteConfirm')));
    await tester.pumpAndSettle();

    expect(find.text('Water cycle'), findsNothing);
    expect(find.byType(JournalCard), findsNWidgets(2));
  });

  testWidgets('AC-9 cancelling the delete keeps the entry', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.drag(find.text('Fractions'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteCancel')));
    await tester.pumpAndSettle();

    expect(find.text('Fractions'), findsOneWidget);
    expect(find.byType(JournalCard), findsNWidgets(3));
  });

  testWidgets('AC-10 editing from Detail updates Detail and the List', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Halley cells'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('DetailEdit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('titleField')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('titleField')), 'Halley cells v2');
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('DetailTitle'))).data,
      'Halley cells v2',
    );

    await tester.tap(find.byKey(const Key('DetailBack')));
    await tester.pumpAndSettle();
    expect(find.text('Halley cells v2'), findsOneWidget);
    expect(find.byType(JournalCard), findsNWidgets(3));
  });

  testWidgets('AC-11 loading shows a spinner before the entries arrive', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      DemoApp(
        home: HomePage(
          controller: HomePageController(
            store: JournalStore.inMemory(),
            loadDelay: HomePageController.defaultLoadDelay,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Halley cells'), findsOneWidget);
  });
}
