import '../../Models/JournalEntry.dart';

/// Controller for the Detail page.
///
/// Pure presentation logic: the page hands it the entry it received and asks for
/// the strings to show. No widgets, no storage.
class DetailPageController {
  DetailPageController({required this.entry});

  final JournalEntry entry;

  String get label => 'Detail';

  String get title => entry.title.isEmpty ? 'Untitled' : entry.title;

  String get note => entry.note.isEmpty ? 'No note' : entry.note;
}
