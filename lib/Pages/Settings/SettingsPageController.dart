import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../Models/AppVersion.dart';
import '../../Utils/app_settings.dart';
import '../../Utils/formatters.dart';
import '../../Utils/journal_store.dart';
import '../../Utils/photo_store.dart';

/// Controller for the Settings page: language choice, local storage report,
/// the app version line and the destructive "clear all" action.
///
/// It never touches widgets; the page passes in the stores and the callback that
/// empties the journal, so this class can be tested with in-memory doubles.
class SettingsPageController extends ChangeNotifier {
  SettingsPageController({
    required this.settings,
    required this.photos,
    required this.journal,
    required this.clearEntries,
    Future<AppVersion> Function()? loadVersion,
  }) : _loadVersion = loadVersion ?? _readPackageInfo;

  final AppSettings settings;
  final PhotoStore photos;
  final JournalStore journal;

  /// Empties the journal (provided by HomePage, which owns the list controller)
  /// and returns how many entries were removed.
  final Future<int> Function() clearEntries;

  /// Reads the version baked in at build time. Injected in tests; defaults to
  /// the real platform channel.
  final Future<AppVersion> Function() _loadVersion;

  static Future<AppVersion> _readPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return AppVersion(version: info.version, buildNumber: info.buildNumber);
  }

  bool _loading = true;
  String _storageLabel = '0 KB';
  AppVersion _version = AppVersion.unknown;

  bool get isLoading => _loading;

  /// Localised size text is assembled in the page (it needs `l10n`); this is the
  /// raw value, e.g. `12 KB`.
  String get storageValue => _storageLabel;

  /// `1.1.0 (build 2)` when the platform answered, otherwise the em-dash pair.
  AppVersion get version => _version;

  String get localeCode => settings.localeCode;

  Future<void> setLocaleCode(String code) => settings.setLocaleCode(code);

  /// Current page background choice (persisted by [AppSettings]).
  String? get backgroundImage => settings.backgroundImage;

  double get backgroundOpacity => settings.backgroundOpacity;

  Future<void> setBackgroundOpacity(double value) =>
      settings.setBackgroundOpacity(value);

  /// Points the page at [fileName] and deletes the picture it replaces, so a
  /// quick series of picks cannot pile files up in the photo folder.
  Future<void> useBackgroundImage(String? fileName) async {
    final String? previous = settings.backgroundImage;
    await settings.setBackgroundImage(fileName);
    if (previous != null && previous != fileName) {
      await photos.delete(previous);
    }
  }

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

  /// Reads the version once. A platform that cannot answer (tests, unsupported
  /// web hosts) leaves [AppVersion.unknown] on screen instead of throwing.
  Future<void> refreshVersion() async {
    try {
      _version = await _loadVersion();
    } catch (_) {
      _version = AppVersion.unknown;
    }
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
