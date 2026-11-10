import 'dart:io';

import 'package:flutter/material.dart';

import '../../Models/JournalEntry.dart';

/// One journal entry rendered as a Card.
///
/// View layer only: it does not create or mutate data, does not resolve file
/// paths (the page hands in [imagePath]) and never navigates on its own — the
/// page decides what [onTap] does.
class JournalCard extends StatelessWidget {
  const JournalCard({
    super.key,
    required this.entry,
    this.onTap,
    this.imagePath,
    this.noPhotoLabel = 'No photo',
    this.createdLabel,
  });

  final JournalEntry entry;

  /// Called when the card is tapped; the page wires this to its navigation.
  final VoidCallback? onTap;

  /// Absolute path of the photo, or null when the entry has none.
  final String? imagePath;

  /// Shown on the placeholder square when there is no photo.
  final String noPhotoLabel;

  /// Optional localised "created on …" line under the note.
  final String? createdLabel;

  static const double _thumbSize = 56;

  Widget _thumb(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String? path = imagePath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _thumbSize,
        height: _thumbSize,
        child: path == null
            ? Container(
                key: const Key('cardPhotoPlaceholder'),
                color: colors.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.photo_outlined,
                  size: 22,
                  color: colors.onSurfaceVariant,
                ),
              )
            : Image.file(
                File(path),
                key: const Key('cardPhoto'),
                fit: BoxFit.cover,
                // Decode at thumbnail resolution: a 1600px photo decoded at full
                // size for a 56px square is ~3 MB of RAM per visible card.
                cacheWidth: (_thumbSize * 3).round(),
                errorBuilder: (_, _, _) => Container(
                  color: colors.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 22,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? subtitle = createdLabel;

    return Card(
      child: ListTile(
        onTap: onTap,
        isThreeLine: subtitle != null,
        leading: _thumb(context),
        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(entry.note, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
