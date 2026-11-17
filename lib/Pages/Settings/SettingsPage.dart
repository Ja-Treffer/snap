import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Utils/app_scope.dart';
import '../../Utils/app_settings.dart';
import '../../l10n/app_localizations.dart';
import 'SettingsPageController.dart';

/// Settings page: language, local storage report and the destructive clear
/// action required by the Session 3 challenge.
///
/// Language lives in [AppSettings] (app-wide), so switching it rebuilds
/// `MaterialApp` and every page picks up the new strings immediately.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.entryCount,
    this.onClearAll,
    this.controller,
    this.backgroundPicker,
  });

  /// How many entries exist right now. A getter (not a value) because clearing
  /// the journal happens on this very page — a captured `int` would go stale.
  final int Function() entryCount;

  /// Empties the journal (list + photos + file) and returns how many entries
  /// were removed. Provided by HomePage, which owns the list controller.
  final Future<int> Function()? onClearAll;

  /// Optional injected controller (tests read the version without a platform
  /// channel); when null the page builds its own from [AppScope].
  final SettingsPageController? controller;

  /// Injected in tests; the gallery picker has no platform implementation there.
  final ImagePicker? backgroundPicker;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsPageController? _controller;
  late bool _ownsController;
  late final ImagePicker _picker =
      widget.backgroundPicker ?? ImagePicker();
  bool _picking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) {
      return;
    }
    final SettingsPageController? injected = widget.controller;
    if (injected != null) {
      _ownsController = false;
      _controller = injected;
    } else {
      _ownsController = true;
      final AppScope scope = AppScope.of(context);
      _controller = SettingsPageController(
        settings: scope.settings,
        photos: scope.photos,
        journal: scope.journal,
        clearEntries: () async => await widget.onClearAll?.call() ?? 0,
      );
    }
    _controller!.refreshStorage();
    // Version comes from the build, not from disk: one read is enough.
    unawaited(_controller!.refreshVersion());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _clearAll(AppLocalizations l10n) async {
    final bool? first = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        key: const Key('clearConfirmDialog'),
        title: Text(l10n.settings_clear_title),
        content: Text(l10n.settings_clear_body(widget.entryCount())),
        actions: <Widget>[
          TextButton(
            key: const Key('clearCancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.btn_cancel),
          ),
          FilledButton(
            key: const Key('clearConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.btn_delete),
          ),
        ],
      ),
    );
    if (first != true || !mounted) {
      return;
    }

    // Second confirmation: deleting every photo cannot be undone, so the course
    // asks for a double check rather than a single tap.
    final bool? second = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        key: const Key('clearConfirmAgainDialog'),
        title: Text(l10n.settings_clear_again_title),
        content: Text(l10n.settings_clear_again_body),
        actions: <Widget>[
          TextButton(
            key: const Key('clearAgainCancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.btn_cancel),
          ),
          FilledButton(
            key: const Key('clearAgainConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.btn_ok),
          ),
        ],
      ),
    );
    if (second != true || !mounted) {
      return;
    }

    await _controller!.clearAll();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.settings_cleared)));
  }

  Widget _languageTile({
    required String label,
    required String code,
    required String current,
    required String keyName,
  }) {
    final bool selected = current == code;
    return ListTile(
      key: Key(keyName),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(label),
      onTap: () => _controller!.setLocaleCode(code),
    );
  }

  /// Thumbnail for the background row: the picture itself, or a placeholder.
  Widget _backgroundThumb(ThemeData theme) {
    final String? path = AppScope.of(
      context,
    ).photos.pathOf(_controller!.backgroundImage);
    if (path == null) {
      return Icon(
        Icons.image_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(path),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            Icon(Icons.broken_image_outlined, color: theme.colorScheme.error),
      ),
    );
  }

  /// Picks a picture from the gallery, copies it into the photo store (the
  /// picker's path lives in an OS cache) and points the page at the copy.
  Future<void> _pickBackground() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppScope scope = AppScope.of(context);
    setState(() => _picking = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) {
        return;
      }
      final String? fileName = await scope.photos.import(picked.path);
      if (fileName == null) {
        _warn(l10n.settings_background_failed);
        return;
      }
      await _controller!.useBackgroundImage(fileName);
    } catch (_) {
      _warn(l10n.settings_background_failed);
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _removeBackground() async {
    await _controller!.useBackgroundImage(null);
  }

  void _warn(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // PART 04: the native Duo rail owns Back when it is active.
        automaticallyImplyLeading:
            !(AppScope.maybeOf(context)?.duo?.railActive ?? false),
        title: Text(l10n.settings_title),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _controller!,
          _controller!.settings,
        ]),
        builder: (BuildContext context, Widget? _) {
          final String current = _controller!.localeCode;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              _sectionTitle(theme, l10n.settings_language),
              _languageTile(
                label: l10n.settings_language_system,
                code: AppSettings.systemCode,
                current: current,
                keyName: 'languageSystem',
              ),
              _languageTile(
                label: 'English',
                code: 'en',
                current: current,
                keyName: 'languageEnglish',
              ),
              _languageTile(
                label: '简体中文',
                code: 'zh',
                current: current,
                keyName: 'languageChinese',
              ),
              _languageTile(
                label: '繁體中文',
                code: 'zh_Hant',
                current: current,
                keyName: 'languageChineseTraditional',
              ),
              const Divider(height: 24),
              _sectionTitle(theme, l10n.settings_background),
              ListTile(
                key: const Key('pickBackground'),
                leading: _backgroundThumb(theme),
                title: Text(
                  _controller!.backgroundImage == null
                      ? l10n.settings_background_none
                      : l10n.settings_background_change,
                ),
                trailing: _controller!.backgroundImage == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        key: const Key('removeBackground'),
                        tooltip: l10n.settings_background_remove,
                        icon: const Icon(Icons.close),
                        onPressed: _picking ? null : _removeBackground,
                      ),
                onTap: _picking ? null : _pickBackground,
              ),
              if (_controller!.backgroundImage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Text(l10n.settings_background_opacity),
                      Expanded(
                        child: Slider(
                          key: const Key('backgroundOpacity'),
                          value: _controller!.backgroundOpacity,
                          min: AppSettings.minBackgroundOpacity,
                          max: AppSettings.maxBackgroundOpacity,
                          label:
                              '${(_controller!.backgroundOpacity * 100).round()}%',
                          onChanged: _controller!.setBackgroundOpacity,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${(_controller!.backgroundOpacity * 100).round()}%',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              _sectionTitle(theme, l10n.settings_storage),
              ListTile(
                key: const Key('storageUsed'),
                leading: const Icon(Icons.sd_storage_outlined),
                title: Text(
                  _controller!.isLoading
                      ? '…'
                      : l10n.settings_storage_used(_controller!.storageValue),
                ),
                subtitle: Text('${widget.entryCount()}'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.tonalIcon(
                  key: const Key('clearAllButton'),
                  onPressed: () => _clearAll(l10n),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(l10n.settings_clear),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 24),
              _sectionTitle(theme, l10n.settings_about),
              ListTile(
                key: const Key('appVersion'),
                leading: const Icon(Icons.info_outline),
                title: Text(
                  l10n.settings_version(
                    _controller!.version.version,
                    _controller!.version.buildNumber,
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  key: const Key('SettingsBack'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.btn_back),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
