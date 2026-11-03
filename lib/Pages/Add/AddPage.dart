import 'package:flutter/material.dart';

import '../../Models/JournalEntry.dart';
import 'AddPageController.dart';

/// Add page — and, reused, the Edit page.
///
/// Collects a title (optional) and a note (optional). Only a completely empty
/// form is rejected; a note without a title is saved as "Untitled". Nothing is
/// stored here: on save the page pops the resulting [JournalEntry] back to the
/// caller.
class AddPage extends StatefulWidget {
  const AddPage({super.key, this.entry});

  /// When non-null the form is prefilled and the page behaves as Edit.
  final JournalEntry? entry;

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  late final AddPageController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = AddPageController(entry: widget.entry);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showEmptyEntry() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: const Key('emptyEntryDialog'),
          title: const Text('Nothing to save'),
          content: const Text('Add a title or a note first.'),
          actions: <Widget>[
            TextButton(
              key: const Key('emptyEntryOk'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    if (_controller.isBlank) {
      await _showEmptyEntry();
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(_controller.buildEntry());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_controller.label)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            TextFormField(
              key: const Key('titleField'),
              controller: _controller.titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Required',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('noteField'),
              controller: _controller.noteController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('saveButton'),
              onPressed: _save,
              child: Text(_controller.saveLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('AddBack'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
