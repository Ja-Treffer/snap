import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences that must survive a restart — for now just the language.
///
/// The locale is stored as a plain string (`system`, `en`, `zh`, `zh_Hant`)
/// rather than a serialised `Locale`, so the value stays readable in
/// `shared_preferences` and a future version can migrate it by string compare.
class AppSettings extends ChangeNotifier {
  AppSettings({Future<SharedPreferences> Function()? loadPreferences})
    : _loadPreferences = loadPreferences ?? SharedPreferences.getInstance;

  static const String localeKey = 'app.locale';
  static const String systemCode = 'system';

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

  String get localeCode => _localeCode;

  /// Null means "follow the device"; [MaterialApp] then picks the best match.
  Locale? get locale => _localeFromCode(_localeCode);

  Future<void> load() async {
    try {
      _preferences = await _loadPreferences();
      final String? stored = _preferences?.getString(localeKey);
      if (stored != null && _isKnownCode(stored)) {
        _localeCode = stored;
      }
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
