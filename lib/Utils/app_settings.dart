import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences that must survive a restart — language, background image
/// and its opacity.
///
/// The locale is stored as a plain string (`system`, `en`, `zh`, `zh_Hant`)
/// rather than a serialised `Locale`, so the value stays readable in
/// `shared_preferences` and a future version can migrate it by string compare.
/// The background picture is stored as a **file name** inside `PhotoStore`
/// (`<documents>/photos/`) for the same reason as entry photos: absolute paths
/// change on reinstall.
class AppSettings extends ChangeNotifier {
  AppSettings({Future<SharedPreferences> Function()? loadPreferences})
    : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static const String localeKey = 'app.locale';
  static const String backgroundImageKey = 'app.backgroundImage';
  static const String backgroundOpacityKey = 'app.backgroundOpacity';
  static const String systemCode = 'system';

  /// Opacity the page background starts with, and the allowed range.
  static const double defaultBackgroundOpacity = 0.35;
  static const double minBackgroundOpacity = 0.05;
  static const double maxBackgroundOpacity = 1.0;

  static const Locale english = Locale('en');
  static const Locale chineseSimplified = Locale('zh');
  static const Locale chineseTraditional = Locale('zh', 'Hant');

  /// Order matters: the first entry is the fallback when the device language is
  /// not supported.
  static const List<Locale> supportedLocales = <Locale>[
    english,
    chineseSimplified,
    chineseTraditional,
  ];

  final Future<SharedPreferences> Function() _loadPreferences;

  SharedPreferences? _preferences;
  String _localeCode = systemCode;
  String? _backgroundImage;
  double _backgroundOpacity = defaultBackgroundOpacity;

  String get localeCode => _localeCode;

  /// File name of the chosen page background, or null for a plain page.
  String? get backgroundImage => _backgroundImage;

  /// How strongly the background picture shows through, clamped to
  /// [minBackgroundOpacity]..[maxBackgroundOpacity].
  double get backgroundOpacity => _backgroundOpacity;

  /// Null means "follow the device"; [MaterialApp] then picks the best match.
  Locale? get locale => _localeFromCode(_localeCode);

  Future<void> load() async {
    try {
      _preferences = await _loadPreferences();
      final String? stored = _preferences?.getString(localeKey);
      if (stored != null && _isKnownCode(stored)) {
        _localeCode = stored;
      }
      final String? image = _preferences?.getString(backgroundImageKey);
      _backgroundImage = (image == null || image.isEmpty) ? null : image;
      _backgroundOpacity = _clampOpacity(
        _preferences?.getDouble(backgroundOpacityKey) ?? defaultBackgroundOpacity,
      );
    } catch (_) {
      // No plugin (widget tests, unsupported platform): stay on "system".
      _preferences = null;
    }
  }

  Future<void> setLocaleCode(String code) async {
    if (!_isKnownCode(code) || code == _localeCode) {
      return;
    }
    _localeCode = code;
    notifyListeners();
    try {
      await _preferences?.setString(localeKey, code);
    } catch (_) {
      // Preference not persisted; the choice still applies for this run.
    }
  }

  /// Points the page background at a file already copied into the photo store.
  /// Passing null removes it and restores the plain palette colour.
  Future<void> setBackgroundImage(String? fileName) async {
    final String? next = (fileName == null || fileName.isEmpty)
        ? null
        : fileName;
    if (next == _backgroundImage) {
      return;
    }
    _backgroundImage = next;
    notifyListeners();
    try {
      if (next == null) {
        await _preferences?.remove(backgroundImageKey);
      } else {
        await _preferences?.setString(backgroundImageKey, next);
      }
    } catch (_) {
      // Nothing to persist into; the UI already updated.
    }
  }

  /// Live slider updates: notify on every step, persist on each one too (the
  /// write is a single double, cheap enough not to need debouncing).
  Future<void> setBackgroundOpacity(double value) async {
    final double next = _clampOpacity(value);
    if (next == _backgroundOpacity) {
      return;
    }
    _backgroundOpacity = next;
    notifyListeners();
    try {
      await _preferences?.setDouble(backgroundOpacityKey, next);
    } catch (_) {
      // Best effort.
    }
  }

  static double _clampOpacity(double value) {
    if (!value.isFinite) {
      return defaultBackgroundOpacity;
    }
    return value.clamp(minBackgroundOpacity, maxBackgroundOpacity);
  }

  static bool _isKnownCode(String code) {
    return code == systemCode ||
        code == 'en' ||
        code == 'zh' ||
        code == 'zh_Hant';
  }

  static Locale? _localeFromCode(String code) {
    switch (code) {
      case 'en':
        return english;
      case 'zh':
        return chineseSimplified;
      case 'zh_Hant':
        return chineseTraditional;
      default:
        return null;
    }
  }

  /// Label key for the settings picker; the page translates it.
  static String codeOf(Locale locale) {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ? 'zh_Hant' : 'zh';
    }
    return locale.languageCode;
  }
}
