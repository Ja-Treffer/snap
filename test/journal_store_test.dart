import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:demo_pages/Pages/HomePage/HomePageController.dart';
import 'package:demo_pages/Utils/journal_store.dart';

void main() {
  test('store with a temp directory round-trips entries', () async {
    final Directory dir = await Directory.systemTemp.createTemp('journal_test');
    addTearDown(() => dir.delete(recursive: true));

    final JournalStore store = JournalStore(documentsDirectory: () async => dir);
    expect(await store.exists(), isFalse);
    expect(await store.load(), isEmpty);

    final controller = HomePageController(
      store: store,
      loadDelay: Duration.zero,
    );
    await controller.load();
    expect(controller.count, 3, reason: 'first run seeds samples');
    expect(File('${dir.path}${Platform.pathSeparator}journal.json').existsSync(), isTrue);

    controller.removeEntry(controller.entries.first);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final JournalStore reopened = JournalStore(
      documentsDirectory: () async => dir,
    );
    final List<dynamic> loaded = await reopened.load();
    expect(loaded.length, 2);
  });

  test('store without a platform channel falls back to memory', () async {
    final JournalStore store = JournalStore();
    expect(store.isMemoryMode, isFalse);
    expect(await store.load(), isEmpty);
    expect(store.isMemoryMode, isTrue, reason: 'no path_provider in tests');
  });
}
