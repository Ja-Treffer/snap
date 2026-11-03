import 'package:flutter/material.dart';

import '../../Component/JournalCard/JournalCard.dart';
import '../../Models/JournalEntry.dart';
import '../Add/AddPage.dart';
import '../Detail/DetailPage.dart';
import '../Settings/SettingsPage.dart';
import 'HomePageController.dart';

/// Home = the List page.
///
/// Shows the entries owned by [HomePageController] as [JournalCard]s. Tapping a
/// card opens the Detail page for that entry; the AppBar carries the real
/// settings (leading) and add (trailing) actions, so no temporary buttons.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.controller});

  /// Optional injected controller (tests use an in-memory store); when null the
  /// page creates its own and loads from disk.
  final HomePageController? controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomePageController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HomePageController();
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _openDetail(JournalEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetailPage(
          entry: entry,
          onUpdated: (JournalEntry updated) =>
              _controller.replaceEntry(entry, updated),
        ),
      ),
    );
  }

  /// Waits for the Add page to hand back a new entry, then puts it on top.
  Future<void> _openAdd() async {
    final JournalEntry? created = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute<JournalEntry>(builder: (_) => const AddPage()),
    );
    if (created != null) {
      _controller.addEntry(created);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  /// Swipe-left deletes, but only after the user confirms it.
  Future<bool> _confirmDelete(JournalEntry entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete this entry?'),
          content: Text('"${entry.title}" will be removed from the list.'),
          actions: <Widget>[
            TextButton(
              key: const Key('deleteCancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('deleteConfirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Widget _buildDismissible(JournalEntry entry) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: ObjectKey(entry),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(entry),
      onDismissed: (_) => _controller.removeEntry(entry),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
      ),
      child: JournalCard(entry: entry, onTap: () => _openDetail(entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_controller.label),
        leading: IconButton(
          key: const Key('openSettings'),
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: _openSettings,
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('openAdd'),
            tooltip: 'Add entry',
            icon: const Icon(Icons.add),
            onPressed: _openAdd,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<JournalEntry> entries = _controller.entries;

          if (entries.isEmpty) {
            return const Center(
              child: Text('No entries yet', key: Key('emptyList')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDismissible(entries[index]),
              );
            },
          );
        },
      ),
    );
  }
}
