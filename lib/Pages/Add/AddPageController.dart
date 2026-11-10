import 'package:flutter/material.dart';

import '../../Models/JournalEntry.dart';

/// Controller for the Add / Edit page.
///
/// Owns the two text controllers and the chosen photo file name, and knows how
/// to turn them into a [JournalEntry]. The list itself is never stored here —
/// the page pops the new entry back to whoever opened it. Platform work (camera,
/// permissions, copying the file) stays in the page: a controller must not need
/// a BuildContext.
class AddPageController {
  AddPageController({this.entry})
    : titleController = TextEditingController(text: entry?.title ?? ''),
      noteController = TextEditingController(text: entry?.note ?? ''),
      photoFileName = entry?.photoPath;

  /// Non-null when the page is reused as an Edit page.
  final JournalEntry? entry;

  final TextEditingController titleController;
  final TextEditingController noteController;

  /// File name inside the app's photos directory (not an absolute path).
  String? photoFileName;

  bool get isEditing => entry != null;

  bool get hasPhoto => photoFileName != null && photoFileName!.isNotEmpty;

  String get title => titleController.text.trim();

  String get note => noteController.text.trim();

  bool get hasTitle => title.isNotEmpty;

  bool get hasNote => note.isNotEmpty;

  /// Nothing typed at all and no photo. A note without a title is fine (it is
  /// stored under the localised "Untitled"); only an empty form is rejected.
  bool get isBlank => !hasTitle && !hasNote && !hasPhoto;

  void setPhoto(String? fileName) {
    photoFileName = (fileName == null || fileName.isEmpty) ? null : fileName;
  }

  void clearPhoto() {
    photoFileName = null;
  }

  /// Builds the entry the page should pop. Editing keeps the original
  /// [JournalEntry.createdAt]; the photo is rebuilt from scratch so removing it
  /// works (a `copyWith` with a null argument would mean "keep").
  JournalEntry buildEntry({required String untitledLabel}) {
    final String resolvedTitle = hasTitle ? title : untitledLabel;
    final JournalEntry? current = entry;
    return JournalEntry(
      title: resolvedTitle,
      note: note,
      createdAt: current?.createdAt ?? DateTime.now(),
      photoPath: photoFileName,
    );
  }

  void dispose() {
    titleController.dispose();
    noteController.dispose();
  }
}
