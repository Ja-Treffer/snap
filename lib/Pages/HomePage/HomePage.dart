import 'dart:async';
import 'package:flutter/material.dart';

import '../../Component/JournalCard/JournalCard.dart';
import '../../Models/JournalEntry.dart';
import '../../Utils/app_settings.dart';
import '../../Utils/formatters.dart';
import '../../l10n/app_localizations.dart';
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
  /// A cancelled form may have copied a photo to storage already, so the list
  /// sweeps orphans right after it closes.
  Future<void> _openAdd() async {
    final JournalEntry? created = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute<JournalEntry>(builder: (_) => const AddPage()),
    );
    if (created != null) {
      _controller.addEntry(created);
    } else {
      unawaited(_controller.purgeOrphanPhotos());
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          entryCount: () => _controller.count,
          onClearAll: _controller.clearAll,
        ),
      ),
    );
  }

  /// Swipe-left deletes, but only after the user confirms it.
  Future<bool> _confirmDelete(JournalEntry entry) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.dialog_delete_title),
          content: Text(l10n.dialog_delete_body(entry.title)),
          actions: <Widget>[
            TextButton(
              key: const Key('deleteCancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.btn_cancel),
            ),
            FilledButton(
              key: const Key('deleteConfirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.btn_delete),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Widget _buildDismissible(JournalEntry entry, String localeCode) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

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
      child: JournalCard(
        entry: entry,
        imagePath: _controller.photoPathOf(entry),
        createdLabel: l10n.entry_created_on(
          formatEntryDate(entry.createdAt, localeCode),
        ),
        onTap: () => _openDetail(entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String localeCode = AppSettings.codeOf(
      Localizations.localeOf(context),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homepage_title),
        leading: IconButton(
          key: const Key('openSettings'),
          tooltip: l10n.btn_settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: _openSettings,
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('openAdd'),
            tooltip: l10n.btn_add_entry,
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
            return Center(
              child: Text(
                l10n.homepage_empty,
                key: const Key('emptyList'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDismissible(entries[index], localeCode),
              );
            },
          );
        },
      ),
    );
  }
}

