/// Session 4 · PART 03 — what `pubspec.yaml` said when the app was built.
///
/// Pure data: no plugin import here, so the model stays testable without a
/// platform channel. `package_info_plus` reads the values; this class carries
/// them to the Settings page.
class AppVersion {
  const AppVersion({required this.version, required this.buildNumber});

  /// `1.1.0` — major.minor.patch.
  final String version;

  /// `2` — the number after the `+`, incremented on every store build.
  final String buildNumber;

  /// Shown before the platform answers, and when it cannot answer at all.
  static const AppVersion unknown = AppVersion(
    version: '—',
    buildNumber: '—',
  );

  @override
  String toString() => 'AppVersion($version+$buildNumber)';
}
