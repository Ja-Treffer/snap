import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../Models/JournalEntry.dart';
import '../../Utils/app_scope.dart';
import '../../Utils/photo_store.dart';
import '../../l10n/app_localizations.dart';
import 'AddPageController.dart';

/// Add page — and, reused, the Edit page.
///
/// Collects a title (optional), a note (optional) and one photo (optional).
/// Only a completely empty form is rejected. Nothing is stored here: on save the
/// page pops the resulting [JournalEntry] back to the caller, and the photo file
/// name it carries is already a copy inside the app's documents directory.
class AddPage extends StatefulWidget {
  const AddPage({super.key, this.entry, this.imagePicker});

  /// When non-null the form is prefilled and the page behaves as Edit.
  final JournalEntry? entry;

  /// Injected only by tests; the real page uses [ImagePicker].
  final ImagePicker? imagePicker;

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  late final AddPageController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _defaultPicker = ImagePicker();

  ImagePicker get _picker => widget.imagePicker ?? _defaultPicker;

  /// Photos this page wrote to disk but has not handed back yet. Whatever is
  /// still in here when the page closes without saving is deleted, so picking
  /// an image and then pressing Back does not leave a file behind.
  final Set<String> _uncommitted = <String>{};

  PhotoStore? _photos;

  static const double _previewHeight = 180;

  @override
  void initState() {
    super.initState();
    _controller = AddPageController(entry: widget.entry);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photos ??= AppScope.of(context).photos;
  }

  @override
  void dispose() {
    final PhotoStore? photos = _photos;
    if (photos != null) {
      for (final String name in _uncommitted) {
        unawaited(photos.delete(name));
      }
    }
    _controller.dispose();
    super.dispose();
  }

  /// Asks for the permission that belongs to the chosen source, then opens the
  /// picker. Denied → dialog with a shortcut to the system settings; the user
  /// can still save the entry without a photo.
  Future<void> _pickPhoto(ImageSource source) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Permission permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    PermissionStatus status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
    }
    if (!mounted) {
      return;
    }
    if (!status.isGranted) {
      await _showPermissionDialog(l10n);
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) {
        return;
      }
      final String? stored = await AppScope.of(
        context,
      ).photos.import(picked.path);
      if (!mounted) {
        return;
      }
      if (stored == null) {
        await _showMessage(l10n.dialog_photo_failed);
        return;
      }
      // Keep track of what to clean up if the form is abandoned.
      _uncommitted.add(stored);
      setState(() => _controller.setPhoto(stored));
    } catch (_) {
      if (mounted) {
        await _showMessage(l10n.dialog_photo_failed);
      }
    }
  }

  Future<void> _showPermissionDialog(AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: const Key('photoPermissionDialog'),
          title: Text(l10n.dialog_permission_title),
          content: Text(l10n.dialog_permission_body),
          actions: <Widget>[
            TextButton(
              key: const Key('permissionCancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.btn_cancel),
            ),
            FilledButton(
              key: const Key('permissionOpenSettings'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              child: Text(l10n.btn_open_settings),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).btn_ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEmptyEntry() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: const Key('emptyEntryDialog'),
          title: Text(l10n.dialog_empty_title),
          content: Text(l10n.dialog_empty_body),
          actions: <Widget>[
            TextButton(
              key: const Key('emptyEntryOk'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.btn_ok),
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? kept = _controller.photoFileName;
    if (kept != null) {
      _uncommitted.remove(kept);
    }
    Navigator.of(
      context,
    ).pop(_controller.buildEntry(untitledLabel: l10n.entry_untitled));
  }

  /// Dropping the photo removes the file right away — the entry will not
  /// reference it, and nobody else can.
  void _removePhoto() {
    final String? dropped = _controller.photoFileName;
    if (dropped != null && _uncommitted.remove(dropped)) {
      unawaited(_photos?.delete(dropped));
    }
    setState(_controller.clearPhoto);
  }

  Widget _buildPhotoSection(AppLocalizations l10n) {
    final String? path = AppScope.of(context).photos.pathOf(
      _controller.photoFileName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.form_photo_label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (path != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              key: const Key('addPhotoPreview'),
              height: _previewHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                key: Key('addPhotoBroken'),
                height: _previewHeight,
              ),
            ),
          )
        else
          Container(
            key: const Key('addPhotoPlaceholder'),
            height: 88,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              key: const Key('pickFromGallery'),
              onPressed: () => _pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l10n.btn_photo_gallery),
            ),
            OutlinedButton.icon(
              key: const Key('pickFromCamera'),
              onPressed: () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(l10n.btn_photo_camera),
            ),
            if (_controller.hasPhoto)
              TextButton.icon(
                key: const Key('removePhoto'),
                onPressed: _removePhoto,
                icon: const Icon(Icons.close, size: 18),
                label: Text(l10n.btn_photo_remove),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String label = _controller.isEditing
        ? l10n.edit_title
        : l10n.add_title;
    final String saveLabel = _controller.isEditing
        ? l10n.btn_update
        : l10n.btn_save;

    return Scaffold(
      appBar: AppBar(title: Text(label)),
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
              decoration: InputDecoration(
                labelText: l10n.form_title_label,
                hintText: l10n.form_title_hint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('noteField'),
              controller: _controller.noteController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l10n.form_note_label,
                hintText: l10n.form_note_hint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            _buildPhotoSection(l10n),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('saveButton'),
              onPressed: _save,
              child: Text(saveLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('AddBack'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.btn_back),
            ),
          ],
        ),
      ),
    );
  }
}
