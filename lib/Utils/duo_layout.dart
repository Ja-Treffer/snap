import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:itchi_flutter_duo_layout/itchi_flutter_duo_layout.dart';

/// Session 4 · PART 04 — the native iPhone Duo bridge.
///
/// Only this file imports the plugin. Everything else talks to
/// [DuoLayoutController], which keeps three promises the course makes:
///
/// 1. the native side-rail Back can be turned on, and the caller is told whether
///    the platform honoured it ([DuoLayoutController.railActive]);
/// 2. the fold stream is followed, so the UI can switch between one pane and
///    two ([DuoLayoutController.wantsTwoPanes]);
/// 3. on any non-iOS platform every call degrades to "not available" instead of
///    throwing — Android, Web and Windows keep working unchanged.
///
/// [DuoBridge] exists so tests can feed a fake without a platform channel.

/// Thin seam over the plugin's static API.
abstract class DuoBridge {
  Future<ItchiSideBackStatus> setSideBackVisible(bool visible);
  Stream<void> get onBack;
  Stream<DuoFoldSnapshot> get foldSnapshots;
}

/// The real plugin. iOS answers `available`; every other platform answers
/// `unsupportedPlatform` and no stream events arrive.
class PlatformDuoBridge implements DuoBridge {
  const PlatformDuoBridge();

  @override
  Future<ItchiSideBackStatus> setSideBackVisible(bool visible) =>
      ItchiDuoSideBack.setVisible(visible);

  @override
  Stream<void> get onBack => ItchiDuoSideBack.onBack;

  @override
  Stream<DuoFoldSnapshot> get foldSnapshots => ItchiDuoFold.snapshots;
}

class DuoLayoutController extends ChangeNotifier {
  DuoLayoutController({DuoBridge? bridge})
    : _bridge = bridge ?? const PlatformDuoBridge();

  final DuoBridge _bridge;

  StreamSubscription<void>? _backSub;
  StreamSubscription<DuoFoldSnapshot>? _foldSub;

  bool _railActive = false;
  DuoFoldSnapshot? _fold;

  /// True only when the native rail actually carries the Back control, i.e. the
  /// platform said `available`. Pages hide their own AppBar leading while it is.
  bool get railActive => _railActive;

  /// Latest hinge reading; null until the first event (or forever on non-iOS).
  DuoFoldSnapshot? get fold => _fold;

  /// Two panes only when the hinge says the window spans both halves *and* the
  /// viewport is wide enough to be readable. Without a hinge, a large window
  /// (tablet, desktop, resized web) falls back to the same size test.
  bool wantsTwoPanes(Size window) {
    final DuoFoldSnapshot? snap = _fold;
    final double short = math.min(window.width, window.height);
    final double long = math.max(window.width, window.height);
    if (snap != null && snap.isAvailable) {
      return snap.wantsTwoPanes && short >= 600;
    }
    return short >= 600 && long >= 640;
  }

  /// Asks for the side-rail Back, then follows the fold stream.
  ///
  /// [onBack] is invoked when the user taps the native Back. It is wired to the
  /// root navigator by `DemoApp`.
  Future<void> start({VoidCallback? onBack}) async {
    try {
      final ItchiSideBackStatus status = await _bridge.setSideBackVisible(true);
      _railActive = status == ItchiSideBackStatus.available;
    } catch (_) {
      // Missing plugin / channel error: behave exactly like a non-Duo device.
      _railActive = false;
    }

    if (_railActive) {
      _backSub = _bridge.onBack.listen((_) => onBack?.call());
    }

    _foldSub = _bridge.foldSnapshots.listen(
      (DuoFoldSnapshot snapshot) {
        _fold = snapshot;
        notifyListeners();
      },
      onError: (Object _) {
        // A broken fold channel must not take the page down.
      },
    );

    notifyListeners();
  }

  /// Hands the rail back and stops listening. Called from `dispose`.
  Future<void> stop() async {
    await _backSub?.cancel();
    _backSub = null;
    await _foldSub?.cancel();
    _foldSub = null;
    try {
      await _bridge.setSideBackVisible(false);
    } catch (_) {
      // Nothing to clean up on a platform without the plugin.
    }
    if (_railActive) {
      _railActive = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}
