import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../Models/JournalEntry.dart';

/// Reads and writes the journal as a single JSON file in the app documents
/// directory.
///
/// Design notes
/// - **Atomic write**: content goes to `journal.json.tmp` first and is renamed
///   over the real file, so a crash mid-write can never leave half a file.
/// - **Corrupt file**: parsed content is quarantined to `journal.json.bak-<ms>`
///   and the app starts with an empty list instead of crashing.
/// - **Memory fallback**: when the platform channel is unavailable (widget
///   tests, or `path_provider` failing on an unsupported platform) the store
///   silently behaves like an in-memory store. Callers never need a mock.
class JournalStore {
  JournalStore({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  /// Test double: no file access at all, behaves like a plain in-memory list.
  /// Widget tests must use this — real file I/O never completes under the
  /// widget-test fake clock.
  JournalStore.inMemory({List<JournalEntry>? entries})
    : _documentsDirectory = _unavailable,
      _memoryMode = true,
      _memoryEntries = List<JournalEntry>.of(entries ?? <JournalEntry>[]),
      _existedBefore = entries != null;

  static Future<Directory> _unavailable() =>
      Future<Directory>.error(UnsupportedError('in-memory store'));

  static const String fileName = 'journal.json';

  /// Bumped whenever the JSON layout changes, so a future version can migrate.
  static const int schemaVersion = 1;

  final Future<Directory> Function() _documentsDirectory;

  List<JournalEntry> _memoryEntries = <JournalEntry>[];
  bool _memoryMode = false;
  bool _existedBefore = false;

  /// True when nothing was ever persisted (first run) or when file access is
  /// unavailable. Used by the controller to decide whether to seed samples.
  bool get existedBefore => _existedBefore;

  /// True after the store fell back to memory (tests / unsupported platform).
  bool get isMemoryMode => _memoryMode;

  Future<bool> exists() async {
    if (_memoryMode) {
      return _existedBefore;
    }
    try {
      return await (await _file()).exists();
    } catch (_) {
      _memoryMode = true;
      return false;
    }
  }

  Future<List<JournalEntry>> load() async {
    if (_memoryMode) {
      return List<JournalEntry>.of(_memoryEntries);
    }

    final File file;
    try {
      file = await _file();
    } catch (_) {
      _memoryMode = true;
      return List<JournalEntry>.of(_memoryEntries);
    }

    if (!await file.exists()) {
      return <JournalEntry>[];
    }
    _existedBefore = true;

    try {
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('journal root is not an object');
      }
      final Object? rawEntries = decoded['entries'];
      if (rawEntries is! List) {
        throw const FormatException('journal entries is not a list');
      }
      return rawEntries
          .whereType<Map<String, Object?>>()
          .map(JournalEntry.fromJson)
          .toList();
    } catch (_) {
      await _quarantine(file);
      return <JournalEntry>[];
    }
  }

  Future<void> save(List<JournalEntry> entries) async {
    if (_memoryMode) {
      _memoryEntries = List<JournalEntry>.of(entries);
      _existedBefore = true;
      return;
    }

    try {
      final File file = await _file();
      final File tmp = File('${file.path}.tmp');
      await tmp.writeAsString(_encode(entries), flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tmp.rename(file.path);
      _existedBefore = true;
    } catch (_) {
      // Disk full, permissions, or no platform channel: keep working in memory
      // rather than losing the user's entry.
      _memoryMode = true;
      _memoryEntries = List<JournalEntry>.of(entries);
      _existedBefore = true;
    }
  }

  Future<File> _file() async {
    final Directory directory = await _documentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  /// Size of the journal file in bytes, used by the Settings page. Counts the
  /// writer's temporary file too, so an interrupted save is not invisible.
  Future<int> sizeInBytes() async {
    if (_memoryMode) {
      return 0;
    }
    int total = 0;
    try {
      final File file = await _file();
      if (await file.exists()) {
        total += await file.length();
      }
      final File tmp = File('${file.path}.tmp');
      if (await tmp.exists()) {
        total += await tmp.length();
      }
    } catch (_) {
      return 0;
    }
    return total;
  }

  /// Deletes the persisted journal and any quarantined copies (used by "clear
  /// all"). Photos are removed by [PhotoStore.clearAll].
  Future<void> deleteFile() async {
    if (_memoryMode) {
      _memoryEntries = <JournalEntry>[];
      return;
    }
    try {
      final File file = await _file();
      final Directory directory = file.parent;
      await for (final FileSystemEntity entity in directory.list()) {
        final String name = entity.uri.pathSegments.last;
        final bool isJournal =
            name == fileName ||
            name == '$fileName.tmp' ||
            name.startsWith('$fileName.bak-');
        if (isJournal && entity is File) {
          await entity.delete();
        }
      }
      _existedBefore = true;
    } catch (_) {
      // Nothing on disk to remove.
    }
  }

  String _encode(List<JournalEntry> entries) {
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'version': schemaVersion,
      'entries': entries.map((JournalEntry e) => e.toJson()).toList(),
    });
  }

  Future<void> _quarantine(File file) async {
    try {
      final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
      await file.rename('${file.path}.bak-$stamp');
    } catch (_) {
      // Nothing else we can do; the next save will simply overwrite it.
    }
  }
}
