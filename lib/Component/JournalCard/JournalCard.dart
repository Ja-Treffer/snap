import 'package:flutter/material.dart';

import '../../Models/JournalEntry.dart';

/// One journal entry rendered as a Card.
///
/// View layer only: it does not create or mutate data, and it never navigates on
/// its own — the page decides what [onTap] does.
class JournalCard extends StatelessWidget {
  const JournalCard({super.key, required this.entry, this.onTap});

  final JournalEntry entry;

  /// Called when the card is tapped; the page wires this to its navigation.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(entry.title),
        subtitle: Text(entry.note),
      ),
    );
  }
}
