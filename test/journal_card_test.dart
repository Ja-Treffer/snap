import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo_pages/Component/JournalCard/JournalCard.dart';
import 'package:demo_pages/Models/JournalEntry.dart';

void main() {
  final JournalEntry entry = JournalEntry(
    title: 'Photosynthesis',
    note: 'Plants turn light into sugar.',
    createdAt: DateTime(2026, 10, 1),
  );

  testWidgets('AC-12 JournalCard renders an entry title and note in a Card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: JournalCard(entry: entry))),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Photosynthesis'), findsOneWidget);
    expect(find.text('Plants turn light into sugar.'), findsOneWidget);
  });

  testWidgets('AC-13 JournalCard forwards taps through onTap', (
    WidgetTester tester,
  ) async {
    int taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalCard(entry: entry, onTap: () => taps++),
        ),
      ),
    );

    await tester.tap(find.text('Photosynthesis'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
