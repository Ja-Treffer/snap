import 'package:flutter/material.dart';

import '../../Models/JournalEntry.dart';
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
    final DetailPageController controller = DetailPageController(entry: _entry);

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.label),
        actions: <Widget>[
          TextButton(
            key: const Key('DetailEdit'),
            onPressed: _edit,
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Text(
            controller.title,
            key: const Key('DetailTitle'),
            style: theme.textTheme.headlineSmall,
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
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
