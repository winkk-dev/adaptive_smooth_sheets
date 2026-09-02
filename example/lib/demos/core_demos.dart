import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'demo_sheet_scaffold.dart';

/// Opens the smallest useful adaptive modal.
Future<void> showBasicDemo(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _BasicDemo()),
  );
}

/// Opens a primary scroll view that coordinates list scrolling and sheet drag.
Future<void> showLazyListDemo(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _LazyListDemo()),
  );
}

/// Opens state that remains mounted across an adaptive presentation change.
Future<void> showResizeStateDemo(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _ResizeStateDemo()),
  );
}

/// Opens a modal that blocks outer dismissal until its changes are saved.
Future<void> showGuardedDismissDemo(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _GuardedDismissDemo()),
  );
}

/// Opens a route with its own breakpoint and geometry.
Future<void> showLocalOverridesDemo(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    config: AdaptiveSheetConfig(
      presentationPolicy: const AdaptiveSheetPresentationPolicy(
        dialogBreakpoint: 900,
      ),
      dialogWidth: 520,
      dialogMaxHeight: 620,
      bottomSheetBorderRadius: const BorderRadius.vertical(
        top: Radius.circular(36),
      ),
      dialogBorderRadius: BorderRadius.circular(36),
    ),
    page: const AdaptiveSheetPage<void>(child: _LocalOverridesDemo()),
  );
}

class _BasicDemo extends StatelessWidget {
  const _BasicDemo();

  @override
  Widget build(BuildContext context) {
    return DemoSheetScaffold(
      title: 'Basic adaptive modal',
      subtitle: 'The same route uses the right presentation for its window.',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
            const SizedBox(height: 16),
            const Text(
              'Resize the window while this modal is open. Its route and '
              'content stay mounted while the presentation changes.',
            ),
            const SizedBox(height: 12),
            const SelectableText(
              'Try selecting this sentence with a mouse. Text selection wins '
              'over a sheet drag gesture.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => AdaptiveSheetNavigator.of(context).close<void>(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _LazyListDemo extends StatelessWidget {
  const _LazyListDemo();

  @override
  Widget build(BuildContext context) {
    const headerExtent = 168.0;
    const rowExtent = 80.0;
    const targetIndex = 60;

    return DemoSheetScaffold(
      title: 'Lazy list',
      subtitle: 'This primary ListView inherits the adaptive scroll controller.',
      body: ListView.builder(
        key: const ValueKey('lazy-list'),
        primary: true,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemExtentBuilder: (index, _) => index == 0 ? headerExtent : rowExtent,
        itemCount: 150,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scroll normally, then drag down at the top of the list to '
                    'move the bottom sheet. The package coordinates both gestures.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      unawaited(
                        AdaptiveSheetScrollController.of(context).animateTo(
                          headerExtent + (targetIndex - 1) * rowExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                      );
                    },
                    child: const Text('Scroll to item 60'),
                  ),
                ],
              ),
            );
          }

          return ListTile(
            leading: CircleAvatar(child: Text('$index')),
            title: Text('List item $index'),
            subtitle: const Text('Built lazily by the primary ListView.'),
          );
        },
      ),
      actions: [
        FilledButton(
          onPressed: () => AdaptiveSheetNavigator.of(context).close<void>(),
          child: const Text('Close modal'),
        ),
      ],
    );
  }
}

class _ResizeStateDemo extends StatefulWidget {
  const _ResizeStateDemo();

  @override
  State<_ResizeStateDemo> createState() => _ResizeStateDemoState();
}

class _ResizeStateDemoState extends State<_ResizeStateDemo> {
  final _textController = TextEditingController();
  var _count = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoSheetScaffold(
      title: 'Resize state',
      subtitle: 'Widget and text-field state survive a live presentation change.',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Count: $_count', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => setState(() => _count += 1),
              child: const Text('Increment'),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('resize-state-field'),
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Type something, then resize the window',
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => AdaptiveSheetNavigator.of(context).close<void>(),
          child: const Text('Close modal'),
        ),
      ],
    );
  }
}

class _GuardedDismissDemo extends StatefulWidget {
  const _GuardedDismissDemo();

  @override
  State<_GuardedDismissDemo> createState() => _GuardedDismissDemoState();
}

class _GuardedDismissDemoState extends State<_GuardedDismissDemo> {
  var _hasUnsavedChanges = true;
  String? _dismissalStatus;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSheetPopScope<void>(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _dismissalStatus = 'Close blocked while changes are unsaved.';
          });
        }
      },
      child: DemoSheetScaffold(
        title: 'Guarded dismissal',
        subtitle: 'The outer modal cannot close until its changes are saved.',
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _hasUnsavedChanges
                    ? 'Unsaved changes are currently blocking dismissal.'
                    : 'Changes are saved. Close, Back, barrier, and swipe dismissal work again.',
              ),
              if (_dismissalStatus != null) ...[
                const SizedBox(height: 16),
                Text(
                  _dismissalStatus!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_hasUnsavedChanges) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _hasUnsavedChanges = false),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as saved'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => AdaptiveSheetNavigator.of(context).close<void>(),
            child: Text(_hasUnsavedChanges ? 'Try to close' : 'Close modal'),
          ),
        ],
      ),
    );
  }
}

class _LocalOverridesDemo extends StatelessWidget {
  const _LocalOverridesDemo();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DemoSheetScaffold(
      title: 'Route-specific config',
      subtitle: 'One modal can override selected application defaults.',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This route becomes a dialog above 900 px. Every other demo '
              'switches after the app-wide 720 px breakpoint.',
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _ConfigValue(label: 'Dialog breakpoint', value: '900 px'),
                    Divider(height: 1),
                    _ConfigValue(label: 'Dialog width', value: '520 px'),
                    Divider(height: 1),
                    _ConfigValue(label: 'Corner radius', value: '36 px'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Between 720 and 900 px, this modal remains a bottom sheet while '
              'the other demos are already dialogs.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => AdaptiveSheetNavigator.of(context).close<void>(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ConfigValue extends StatelessWidget {
  const _ConfigValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
