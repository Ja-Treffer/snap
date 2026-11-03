import 'package:flutter/material.dart';

import '../../Models/JournalEntry.dart';

/// Controller for the Add / Edit page.
///
/// Owns the two text controllers and knows how to turn them into a
/// [JournalEntry]. The list itself is never stored here — the page pops the new
/// entry back to whoever opened it.
class AddPageController {
  AddPageController({this.entry})
    : titleController = TextEditingController(text: entry?.title ?? ''),
      noteController = TextEditingController(text: entry?.note ?? '');

  /// Non-null when the page is reused as an Edit page.
  final JournalEntry? entry;

  final TextEditingController titleController;
  final TextEditingController noteController;

  bool get isEditing => entry != null;

  String get label => isEditing ? 'Edit' : 'Add';

  String get saveLabel => isEditing ? 'Update' : 'Save';

  String get title => titleController.text.trim();

  String get note => noteController.text.trim();

  bool get hasTitle => title.isNotEmpty;

  bool get hasNote => note.isNotEmpty;

  /// Nothing typed at all. A note without a title is fine (it gets stored as
  /// "Untitled"); only a completely empty form is rejected.
  bool get isBlank => !hasTitle && !hasNote;

  /// Fallback used when the note carries the content but no title was typed.
  /// Stored as a literal for now; the i18n pass (M5) will move it into ARB.
  static const String untitled = 'Untitled';

  /// Builds the entry the page should pop. Keeps the original [JournalEntry.createdAt]
  /// when editing.
  JournalEntry buildEntry() {
    final String resolvedTitle = hasTitle ? title : untitled;
    final JournalEntry? current = entry;
    if (current != null) {
      return current.copyWith(title: resolvedTitle, note: note);
    }
    return JournalEntry(
      title: resolvedTitle,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  void dispose() {
    titleController.dispose();
    noteController.dispose();
  }
}
