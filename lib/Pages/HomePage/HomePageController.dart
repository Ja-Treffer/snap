import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../Models/JournalEntry.dart';
import '../../Utils/app_settings.dart';
import '../../Utils/journal_store.dart';
import '../../Utils/photo_store.dart';

/// Controller for the List page (HomePage).
///
/// Owns the entries and the loading flag; the page only observes and paints.
/// Persistence and photo files are delegated to [JournalStore] / [PhotoStore] —
/// this class never touches the file system directly.
class HomePageController extends ChangeNotifier {
  HomePageController({
    JournalStore? store,
    PhotoStore? photos,
    this.settings,
    this.loadDelay = defaultLoadDelay,
  }) : _store = store ?? JournalStore(),
       _photos = photos ?? PhotoStore();

  static const Duration defaultLoadDelay = Duration(milliseconds: 300);

  /// Injected so tests can shorten or skip the fake loading delay.
  final Duration loadDelay;

  /// Only needed so the orphan sweep knows the background picture is in use.
  final AppSettings? settings;

  final JournalStore _store;
  final PhotoStore _photos;
  final List<JournalEntry> _entries = <JournalEntry>[];

  bool _loading = false;

  bool get isLoading => _loading;

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

  /// Absolute path for an entry's photo, or null when it has none. Synchronous
  /// because [PhotoStore.ensureReady] ran at startup.
  String? photoPathOf(JournalEntry entry) => _photos.pathOf(entry.photoPath);

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

    // Photos whose entry is gone (user abandoned the form, or the app was
    // killed between import and save) would otherwise sit in storage forever.
    unawaited(purgeOrphanPhotos());

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
  /// The replaced photo file is deleted so edited-out images do not pile up.
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
    if (oldEntry.photoPath != null && oldEntry.photoPath != updated.photoPath) {
      unawaited(_photos.delete(oldEntry.photoPath));
    }
    return true;
  }

  bool removeEntry(JournalEntry entry) {
    final bool removed = _entries.remove(entry);
    if (removed) {
      notifyListeners();
      unawaited(_persist());
      unawaited(_photos.delete(entry.photoPath));
    }
    return removed;
  }

  /// Empties the list, deletes every photo and the journal file. Returns the
  /// number of entries that were removed so Settings can report it.
  Future<int> clearAll() async {
    final int removed = _entries.length;
    _entries.clear();
    notifyListeners();
    await _photos.clearAll();
    await _store.deleteFile();
    return removed;
  }

  Future<void> _persist() => _store.save(_entries);

  /// Deletes every stored photo that no current entry references. Called after
  /// loading, and whenever the Add form is closed without saving, so an
  /// abandoned pick cannot accumulate. Returns how many files were removed.
  Future<int> purgeOrphanPhotos() {
    return _photos.deleteUnreferenced(<String>{
      for (final JournalEntry entry in _entries)
        if (entry.photoPath case final String name) name,
      // The page background lives in the same folder and must survive.
      if (settings?.backgroundImage case final String background) background,
    });
  }
}
