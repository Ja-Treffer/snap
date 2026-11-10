import 'package:flutter/foundation.dart';

import '../../Utils/app_settings.dart';
import '../../Utils/formatters.dart';
import '../../Utils/journal_store.dart';
import '../../Utils/photo_store.dart';

/// Controller for the Settings page: language choice, local storage report and
/// the destructive "clear all" action.
///
/// It never touches widgets; the page passes in the stores and the callback that
/// empties the journal, so this class can be tested with in-memory doubles.
class SettingsPageController extends ChangeNotifier {
  SettingsPageController({
    required this.settings,
    required this.photos,
    required this.journal,
    required this.clearEntries,
  });

  final AppSettings settings;
  final PhotoStore photos;
  final JournalStore journal;

  /// Empties the journal (provided by HomePage, which owns the list controller)
  /// and returns how many entries were removed.
  final Future<int> Function() clearEntries;

  bool _loading = true;
  String _storageLabel = '0 KB';

  bool get isLoading => _loading;

  /// Localised size text is assembled in the page (it needs `l10n`); this is the
  /// raw value, e.g. `12 KB`.
  String get storageValue => _storageLabel;

  String get localeCode => settings.localeCode;

  Future<void> setLocaleCode(String code) => settings.setLocaleCode(code);

  /// Journal file + every stored photo.
  Future<void> refreshStorage() async {
    _loading = true;
    notifyListeners();
    try {
      final int bytes =
          await journal.sizeInBytes() + await photos.usedBytes();
      _storageLabel = formatStorageSize(bytes);
    } catch (_) {
      _storageLabel = formatStorageSize(0);
    }
    _loading = false;
    notifyListeners();
  }

  /// Wipes entries, photos and the journal file, then re-reads the size so the
  /// page can show 0 KB immediately.
  Future<int> clearAll() async {
    final int removed = await clearEntries();
    await refreshStorage();
    return removed;
  }

  @override
  void dispose() {
    // Settings is an app-wide object owned by DemoApp; do not dispose it here.
    super.dispose();
  }
}
