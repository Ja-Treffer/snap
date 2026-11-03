import 'package:flutter/material.dart';

import 'SettingsPageController.dart';

/// Shows the page name as a large Text plus a Back button that pops.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    this.controller = const SettingsPageController(),
  });

  final SettingsPageController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(controller.label, style: theme.textTheme.displaySmall),
              const SizedBox(height: 40),
              TextButton(
                key: const Key('SettingsBack'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
