import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Stores the photos that belong to journal entries.
///
/// Why a copy instead of keeping the picker's path: the camera and the gallery
/// hand back files in a cache directory the OS is free to empty at any time, so
/// the entry would lose its photo after a while. Copies live in
/// `<documents>/photos/` and only the **file name** is stored on the entry —
/// absolute paths change on reinstall and would all break at once.
class PhotoStore {
  PhotoStore({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory,
      _memoryOnly = false;

  /// No disk at all — used by widget tests and by any platform where the
  /// documents directory cannot be resolved.
  PhotoStore.inMemory()
    : _documentsDirectory = _unavailable,
      _memoryOnly = true;

  static Future<Directory> _unavailable() =>
      Future<Directory>.error(UnsupportedError('in-memory photo store'));

  static const String folderName = 'photos';

  final Future<Directory> Function() _documentsDirectory;
  final bool _memoryOnly;

  Directory? _root;
  int _sequence = 0;

  /// Resolves (and creates) the photos directory once, at startup, so that
  /// widgets can turn a file name into a path synchronously while painting.
  Future<void> ensureReady() async {
    if (_memoryOnly || _root != null) {
      return;
    }
    try {
      final Directory documents = await _documentsDirectory();
      final Directory directory = Directory(
        '${documents.path}${Platform.pathSeparator}$folderName',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      _root = directory;
    } catch (_) {
      _root = null;
    }
  }

  /// Absolute path for a stored file name; null when the store is not ready.
  String? pathOf(String? fileName) {
    final Directory? root = _root;
    if (root == null || fileName == null || fileName.isEmpty) {
      return null;
    }
    return '${root.path}${Platform.pathSeparator}$fileName';
  }

  Future<File?> fileOf(String? fileName) async {
    final String? path = pathOf(fileName);
    if (path == null) {
      return null;
    }
    final File file = File(path);
    return await file.exists() ? file : null;
  }

  /// Copies [sourcePath] into the photos directory and returns the new file
  /// name, which is what the model stores.
  Future<String?> import(String sourcePath) async {
    final Directory? root = _root;
    if (root == null) {
      return null;
    }
    try {
      final String stamp = DateTime.now()
          .millisecondsSinceEpoch
          .toRadixString(36);
      final String name = 'p-$stamp-${_sequence++}.jpg';
      await File(
        sourcePath,
      ).copy('${root.path}${Platform.pathSeparator}$name');
      return name;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String? fileName) async {
    final String? path = pathOf(fileName);
    if (path == null) {
      return;
    }
    // Windows keeps a just-painted image open for a moment, so one retry is
    // enough in practice; anything still locked is collected at next launch by
    // [deleteUnreferenced].
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final File file = File(path);
        if (!await file.exists()) {
          return;
        }
        await file.delete();
        return;
      } catch (_) {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
    }
  }

  Future<void> clearAll() async {
    final Directory? root = _root;
    if (root == null) {
      return;
    }
    try {
      await for (final FileSystemEntity entity in root.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Best effort: the Settings page only reports a size.
    }
  }

  /// Deletes every stored photo whose file name is not in [keep].
  ///
  /// Runs once per launch: a photo can become orphaned when the user picks an
  /// image and then abandons the form, or when the app is killed between
  /// import and save. Returns how many files were removed.
  Future<int> deleteUnreferenced(Set<String> keep) async {
    final Directory? root = _root;
    if (root == null) {
      return 0;
    }
    int removed = 0;
    try {
      await for (final FileSystemEntity entity in root.list()) {
        if (entity is! File) {
          continue;
        }
        final String name = entity.path
            .split(Platform.pathSeparator)
            .last;
        if (keep.contains(name)) {
          continue;
        }
        try {
          await entity.delete();
          removed += 1;
        } catch (_) {
          // Locked file: leave it for the next launch.
        }
      }
    } catch (_) {
      // Unreadable directory: nothing to reconcile this time.
    }
    return removed;
  }

  /// Total size of every stored photo, in bytes.
  Future<int> usedBytes() async {
    final Directory? root = _root;
    if (root == null) {
      return 0;
    }
    int total = 0;
    try {
      await for (final FileSystemEntity entity in root.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {
      // Unreadable directory counts as empty rather than crashing Settings.
    }
    return total;
  }
}
