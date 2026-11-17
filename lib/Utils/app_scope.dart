import 'package:flutter/widgets.dart';

import 'app_settings.dart';
import 'duo_layout.dart';
import 'journal_store.dart';
import 'photo_store.dart';

/// Hands the app-wide services down the widget tree.
///
/// Pages read it once in `build` (`AppScope.of(context)`) instead of receiving
/// four constructor arguments each; controllers keep taking them as plain
/// constructor parameters, so they stay testable without a BuildContext.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.photos,
    required this.journal,
    this.duo,
    required super.child,
  });

  final AppSettings settings;
  final PhotoStore photos;
  final JournalStore journal;

  /// Session 4 · PART 04. Optional so existing tests can keep building a scope
  /// without a platform bridge; pages fall back to "no side rail" when absent.
  final DuoLayoutController? duo;

  static AppScope of(BuildContext context) {
    final AppScope? scope = maybeOf(context);
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!;
  }

  static AppScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>();
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return settings != oldWidget.settings ||
        photos != oldWidget.photos ||
        journal != oldWidget.journal ||
        duo != oldWidget.duo;
  }
}
