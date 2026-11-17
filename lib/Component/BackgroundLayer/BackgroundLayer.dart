import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Paints the page background picture chosen in Settings, behind everything.
///
/// The app's scaffold is transparent while a picture is set (see
/// `AppTheme.light(transparentScaffold: true)`), so the picture shows through
/// the gaps between cards and behind the list. `dart:io` is unavailable on the
/// web, so there the picture is skipped rather than crashing.
class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({
    super.key,
    required this.imagePath,
    required this.opacity,
    required this.child,
  });

  /// Absolute path, already resolved by `PhotoStore.pathOf`.
  final String? imagePath;

  /// 0…1; the slider clamps before it gets here, the clamp is belt and braces.
  final double opacity;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? path = imagePath;
    if (path == null || path.isEmpty || kIsWeb) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.file(
          File(path),
          key: const Key('backgroundImage'),
          fit: BoxFit.cover,
          opacity: AlwaysStoppedAnimation<double>(opacity.clamp(0.0, 1.0)),
          // A deleted / unreadable file must not take the app down.
          errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
              const SizedBox.shrink(),
        ),
        child,
      ],
    );
  }
}
