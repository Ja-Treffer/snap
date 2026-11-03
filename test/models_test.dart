import 'package:flutter_test/flutter_test.dart';

import 'package:demo_pages/Models/JournalEntry.dart';

void main() {
  final DateTime created = DateTime(2026, 11, 3, 18, 30);

  test('AC-14 JournalEntry holds title / note / createdAt', () {
    final JournalEntry entry = JournalEntry(
      title: 'Morning walk',
      note: 'Riverside park, cold air.',
      createdAt: created,
    );

    expect(entry.title, 'Morning walk');
    expect(entry.note, 'Riverside park, cold air.');
    expect(entry.createdAt, created);
  });

  test('AC-15 constructor takes required named parameters', () {
    expect(
      () => JournalEntry(title: 'x', note: 'y', createdAt: DateTime(2026)),
      returnsNormally,
    );
  });

  test('AC-16 copyWith replaces title and note but keeps createdAt', () {
    final JournalEntry entry = JournalEntry(
      title: 'Before',
      note: 'Old note',
      createdAt: created,
    );

    final JournalEntry updated = entry.copyWith(title: 'After', note: 'New note');

    expect(updated.title, 'After');
    expect(updated.note, 'New note');
    expect(updated.createdAt, created);
    expect(entry.title, 'Before', reason: 'the original must stay immutable');
  });
}
