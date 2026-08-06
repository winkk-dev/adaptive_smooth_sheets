import 'dart:async';

import 'package:flutter/material.dart';

import 'modals/example_form_modal.dart';
import 'modals/example_modals.dart';
import 'modals/navigation_modal.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ExampleApp());
}

/// Example application for adaptive_smooth_sheets.
class ExampleApp extends StatefulWidget {
  /// Creates the example application.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.dark => ThemeMode.light,
        _ => ThemeMode.dark,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adaptive Smooth Sheets',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: ExampleHomePage(onToggleTheme: _toggleTheme),
    );
  }
}

/// Launcher for the focused adaptive modal examples.
class ExampleHomePage extends StatelessWidget {
  /// Creates the example launcher.
  const ExampleHomePage({required this.onToggleTheme, super.key});

  /// Toggles the MaterialApp theme mode.
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Smooth Sheets'),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            tooltip: 'Toggle light and dark theme',
            icon: const Icon(Icons.brightness_6_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Resize the window while a modal is open.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The MaterialApp registers package route defaults and a '
                    'separate project-level modal chrome theme. This example '
                    'uses a 720 px dialog breakpoint and 640 px dialog width.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _ExampleButton(
                    icon: Icons.flash_on_outlined,
                    title: 'Quick view',
                    description: 'Short content and natural sheet height',
                    onPressed: () => unawaited(showQuickViewModal(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.view_list_outlined,
                    title: 'Lazy list',
                    description: 'Scroll-to-drag gesture handoff',
                    onPressed: () => unawaited(showLazyListModal(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.aspect_ratio_outlined,
                    title: 'Resize state',
                    description: 'Widget and input state stay mounted',
                    onPressed: () => unawaited(showResizeStateModal(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.tab_outlined,
                    title: 'Tabs',
                    description: 'Shared header, lazy tab body, sticky footer',
                    onPressed: () => unawaited(showTabsModal(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.route_outlined,
                    title: 'Navigation flow',
                    description: 'Three nested routes with transitions',
                    onPressed: () => unawaited(showNavigationModal(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.shield_outlined,
                    title: 'Guarded close',
                    description: 'Intercept barrier, back, and sheet swipe',
                    onPressed: () =>
                        unawaited(showGuardedDismissModal(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.palette_outlined,
                    title: 'Local theme',
                    description: 'Per-route package and chrome overrides',
                    onPressed: () => unawaited(showLocallyThemedModal(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.fact_check_outlined,
                    title: 'Reactive form',
                    description: 'Long validation and keyboard example',
                    onPressed: () => unawaited(showExampleFormModal(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleButton extends StatelessWidget {
  const _ExampleButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
