import 'package:flutter/material.dart';

/// Session 4 · PART 02 — the workshop palette, defined once.
///
/// Rule that goes with it: screens never write `Color(0x…)`. They read
/// `Theme.of(context).colorScheme`, so changing a value here repaints the whole
/// app. The five hex values are the ones on the course deck.
class AppTheme {
  const AppTheme._();

  /// Deck name: Primary. Drives the scheme, the AppBar and the main button.
  static const Color primary = Color(0xFF025928);

  /// Deck name: Secondary. Kept for accents that must stand apart from primary.
  static const Color secondary = Color(0xFFF25D27);

  /// Deck name: Accent. Material 3 has no `accent`, so it lands on `tertiary`.
  static const Color accent = Color(0xFFD9653B);

  /// Deck name: Surface. Used for cards and other raised containers.
  static const Color surface = Color(0xFFF2B29B);

  /// Deck name: Background. Page and scaffold background, and the default
  /// unless the user picked another tint in Settings.
  static const Color background = Color(0xFFF2F2F2);

  /// [pageBackground] overrides only the page/scaffold colour (Settings →
  /// Background); every other value stays on the deck palette.
  ///
  /// With a background picture the scaffold must be transparent so the picture
  /// shows in the gaps between cards; without one the deck's [background] is
  /// painted as usual.
  static ThemeData light({bool transparentScaffold = false}) {
    final Color bg = transparentScaffold
        ? const Color(0x00000000)
        : background;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: const Color(0xFF3F1B0C),
      tertiary: accent,
      onTertiary: Colors.white,
      surface: bg,
      onSurface: const Color(0xFF1F1F1F),
      surfaceContainerHighest: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(color: surface),
    );
  }
}
