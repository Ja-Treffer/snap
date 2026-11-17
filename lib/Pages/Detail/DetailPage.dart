import 'dart:io';

import 'package:flutter/material.dart';

import '../../Models/JournalEntry.dart';
import '../../Utils/app_scope.dart';
import '../../Utils/app_settings.dart';
import '../../Utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../Add/AddPage.dart';
import 'DetailPageController.dart';

/// Detail page: shows the entry that the List handed over.
///
/// It also reuses [AddPage] as an Edit page; when an edit comes back, the page
/// updates itself and tells the caller through [onUpdated] so the List can stay
/// in sync.
class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.entry, this.onUpdated});

  final JournalEntry entry;

  /// Called with the edited entry; the List uses it to replace its copy.
  final ValueChanged<JournalEntry>? onUpdated;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late JournalEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _edit() async {
    final JournalEntry? updated = await Navigator.of(context).push<JournalEntry>(
      MaterialPageRoute<JournalEntry>(builder: (_) => AddPage(entry: _entry)),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() => _entry = updated);
    widget.onUpdated?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DetailPageController controller = DetailPageController(
      entry: _entry,
      untitledLabel: l10n.entry_untitled,
      emptyNoteLabel: l10n.entry_no_note,
    );
    final String localeCode = AppSettings.codeOf(
      Localizations.localeOf(context),
    );
    final String? photoPath = AppScope.of(context).photos.pathOf(
      _entry.photoPath,
    );

    return Scaffold(
      appBar: AppBar(
        // PART 04: when the native Duo rail carries Back, drop ours so the user
        // does not see two of them.
        automaticallyImplyLeading:
            !(AppScope.maybeOf(context)?.duo?.railActive ?? false),
        title: Text(l10n.detail_title),
        actions: <Widget>[
          TextButton(
            key: const Key('DetailEdit'),
            onPressed: _edit,
            child: Text(l10n.btn_edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          if (photoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(photoPath),
                  key: const Key('detailPhoto'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _photoPlaceholder(theme, l10n),
                ),
              ),
            )
          else
            _photoPlaceholder(theme, l10n),
          const SizedBox(height: 16),
          Text(
            controller.title,
            key: const Key('DetailTitle'),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.entry_created_on(
              formatEntryDate(_entry.createdAt, localeCode),
            ),
            key: const Key('DetailCreatedOn'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            controller.note,
            key: const Key('DetailNote'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextButton(
            key: const Key('DetailBack'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.btn_back),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(ThemeData theme, AppLocalizations l10n) {
    return Container(
      key: const Key('detailPhotoPlaceholder'),
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.photo_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.entry_no_photo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
