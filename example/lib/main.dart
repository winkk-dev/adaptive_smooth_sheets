import 'dart:async';

import 'package:flutter/material.dart';

import 'demos/core_demos.dart';
import 'demos/navigation_demo.dart';
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

/// Launcher for focused, public API examples.
class ExampleHomePage extends StatelessWidget {
  /// Creates the example launcher.
  const ExampleHomePage({super.key, required this.onToggleTheme});

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
                    'Every demo uses only adaptive_smooth_sheets and ordinary '
                    'Material widgets. This app switches at a 720 px dialog '
                    'breakpoint and preserves open modal state while resizing.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _ExampleButton(
                    icon: Icons.flash_on_outlined,
                    title: 'Basic adaptive modal',
                    description: 'The smallest useful showAdaptiveSheet call',
                    onPressed: () => unawaited(showBasicDemo(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.view_list_outlined,
                    title: 'Lazy list',
                    description: 'Primary scrolling and sheet-drag handoff',
                    onPressed: () => unawaited(showLazyListDemo(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.aspect_ratio_outlined,
                    title: 'Resize state',
                    description: 'Widget and input state stay mounted',
                    onPressed: () => unawaited(showResizeStateDemo(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.route_outlined,
                    title: 'Modal navigation',
                    description: 'Push, pop, replace, and replaceAll pages',
                    onPressed: () => unawaited(showNavigationDemo(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.shield_outlined,
                    title: 'Guarded dismissal',
                    description: 'Block barrier, Back, Escape, and swipe dismissal',
                    onPressed: () => unawaited(showGuardedDismissDemo(context)),
                  ),
                  _ExampleButton(
                    icon: Icons.tune_outlined,
                    title: 'Route-specific config',
                    description: 'Custom breakpoint and geometry for one modal',
                    onPressed: () => unawaited(showLocalOverridesDemo(context)),
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
