/// One journal entry.
///
/// Model layer only: no widgets, no navigation, no file access. Serialisation
/// lives here because the shape of the JSON *is* the shape of the model —
/// converting it anywhere else would duplicate the field list.
class JournalEntry {
  const JournalEntry({
    required this.title,
    required this.note,
    required this.createdAt,
    this.photoPath,
  });

  final String title;
  final String note;
  final DateTime createdAt;

  /// File name inside the app's photos directory; null for text-only entries.
  /// Never an absolute path — the sandbox path changes after reinstall/upgrade.
  final String? photoPath;

  /// Returns a copy with the given fields replaced; [createdAt] never changes so
  /// editing an entry keeps its original date.
  JournalEntry copyWith({String? title, String? note, String? photoPath}) {
    return JournalEntry(
      title: title ?? this.title,
      note: note ?? this.note,
      createdAt: createdAt,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  /// ISO-8601 string is the only reversible date format; `toString()` is not.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      if (photoPath != null) 'photoPath': photoPath,
    };
  }

  /// Tolerant on purpose: a hand-edited or half-written record must not crash
  /// the whole list, so missing fields fall back to safe values.
  factory JournalEntry.fromJson(Map<String, Object?> json) {
    final Object? rawDate = json['createdAt'];
    return JournalEntry(
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: rawDate is String
          ? DateTime.tryParse(rawDate) ?? DateTime.now()
          : DateTime.now(),
      photoPath: json['photoPath'] as String?,
    );
  }
}
