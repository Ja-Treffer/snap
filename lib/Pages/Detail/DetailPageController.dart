import '../../Models/JournalEntry.dart';

/// Controller for the Detail page.
///
/// Pure presentation logic: the page hands it the entry it received plus the two
/// fallback labels (they depend on the active language, so they are injected
/// rather than hard-coded here). No widgets, no storage.
class DetailPageController {
  DetailPageController({
    required this.entry,
    required this.untitledLabel,
    required this.emptyNoteLabel,
  });

  final JournalEntry entry;
  final String untitledLabel;
  final String emptyNoteLabel;

  String get title => entry.title.isEmpty ? untitledLabel : entry.title;

  String get note => entry.note.isEmpty ? emptyNoteLabel : entry.note;

  bool get hasPhoto => entry.photoPath != null && entry.photoPath!.isNotEmpty;
}
