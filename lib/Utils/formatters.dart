import 'package:intl/intl.dart';

/// Localised, human-readable date used on the Detail page and the card.
///
/// The pattern comes from `intl` for the active language, so `en` gets
/// "Oct 1, 2026" and `zh` gets "2026年10月1日" without a branch in the UI.
String formatEntryDate(DateTime value, String localeName) {
  try {
    return DateFormat.yMMMd(localeName).format(value);
  } catch (_) {
    // Unknown locale (or intl data missing): fall back to an ISO-ish date that
    // is at least unambiguous.
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

/// Human size for the Settings page, rounded **down** to whole KB on purpose:
/// an emptied journal still weighs a few dozen bytes and the course expects
/// "0 KB used" right after clearing.
String formatStorageSize(int bytes) {
  if (bytes <= 0) {
    return '0 KB';
  }
  final double kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.floor()} KB';
  }
  final double mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
