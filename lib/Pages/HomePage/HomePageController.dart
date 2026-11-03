import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../Models/JournalEntry.dart';
import '../../Utils/journal_store.dart';

/// Controller for the List page (HomePage).
///
/// Owns the entries and the loading flag; the page only observes and paints.
/// Persistence is delegated to [JournalStore] — this class never touches files,
/// and the page never touches this class's storage.
class HomePageController extends ChangeNotifier {
  HomePageController({JournalStore? store, this.loadDelay = defaultLoadDelay})
    : _store = store ?? JournalStore();

  static const Duration defaultLoadDelay = Duration(milliseconds: 300);

  /// Injected so tests can shorten or skip the fake loading delay.
  final Duration loadDelay;

  final JournalStore _store;
  final List<JournalEntry> _entries = <JournalEntry>[];

  bool _loading = false;

  bool get isLoading => _loading;

  String get label => 'List';

  /// Read-only view; callers cannot mutate the list behind the controller's back.
  List<JournalEntry> get entries => List<JournalEntry>.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  int get count => _entries.length;

  /// Samples only for the very first run, so the list is never empty on a fresh
  /// install. They are saved immediately, which makes the next launch keep them.
  static List<JournalEntry> sampleEntries() {
    return <JournalEntry>[
      JournalEntry(
        title: 'Halley cells',
        note: 'The cell wall keeps the shape. Chloroplasts handle photosynthesis.',
        createdAt: DateTime(2026, 10, 1),
      ),
      JournalEntry(
        title: 'Fractions',
        note: 'A fraction is part of a whole. One half is written as 1/2.',
        createdAt: DateTime(2026, 10, 8),
      ),
      JournalEntry(
        title: 'Water cycle',
        note: 'Water evaporates, condenses into clouds, then falls as rain.',
        createdAt: DateTime(2026, 10, 15),
      ),
    ];
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    await Future<void>.delayed(loadDelay);

    final bool existedBefore = await _store.exists();
    final List<JournalEntry> stored = await _store.load();

    _entries
      ..clear()
      ..addAll(stored);

    if (!existedBefore) {
      _entries.addAll(sampleEntries());
      await _store.save(_entries);
    }

    _loading = false;
    notifyListeners();
  }

  /// New entries always go on top, which is what the Add flow expects.
  void addEntry(JournalEntry entry) {
    _entries.insert(0, entry);
    notifyListeners();
    unawaited(_persist());
  }

  /// Replaces [oldEntry] by identity; used after the Detail page edits it.
  bool replaceEntry(JournalEntry oldEntry, JournalEntry updated) {
    final int index = _entries.indexWhere(
      (JournalEntry item) => identical(item, oldEntry),
    );
    if (index < 0) {
      return false;
    }
    _entries[index] = updated;
    notifyListeners();
    unawaited(_persist());
    return true;
  }

  bool removeEntry(JournalEntry entry) {
    final bool removed = _entries.remove(entry);
    if (removed) {
      notifyListeners();
      unawaited(_persist());
    }
    return removed;
  }

  Future<void> _persist() => _store.save(_entries);
}
