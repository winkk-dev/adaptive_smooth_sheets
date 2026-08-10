import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'base_modal.dart';

/// Shows a three-page flow using the package-owned sheet navigator.
Future<void> showNavigationModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(
      settings: RouteSettings(name: 'direction'),
      child: _DirectionPage(),
    ),
  );
}

class _DirectionPage extends StatefulWidget {
  const _DirectionPage();

  @override
  State<_DirectionPage> createState() => _DirectionPageState();
}

class _DirectionPageState extends State<_DirectionPage> {
  var _selection = 0;

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = AdaptiveSheetNavigator.of(context);
    return BaseModal(
      title: 'Choose direction',
      subtitle: 'Step 1 of 3',
      body: BaseModalBody.singleChild(
        child: Column(
          key: const ValueKey('navigation-step-1'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StepIcon(icon: Icons.route_outlined),
            const SizedBox(height: 20),
            Text(
              'Choose a starting direction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Each step is an AdaptiveSheetPage. Smooth Sheets owns the '
              'route transition and keeps previous page state mounted.',
            ),
            const SizedBox(height: 24),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Mobile')),
                ButtonSegment(value: 1, label: Text('Desktop')),
                ButtonSegment(value: 2, label: Text('Both')),
              ],
              selected: {_selection},
              onSelectionChanged: (selection) {
                setState(() => _selection = selection.single);
              },
            ),
          ],
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          FilledButton.icon(
            onPressed: () {
              sheetNavigator.push<void>(
                const AdaptiveSheetPage<void>(
                  settings: RouteSettings(name: 'behavior'),
                  child: _BehaviorPage(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _BehaviorPage extends StatefulWidget {
  const _BehaviorPage();

  @override
  State<_BehaviorPage> createState() => _BehaviorPageState();
}

class _BehaviorPageState extends State<_BehaviorPage> {
  var _sendReminder = true;
  var _automationLevel = 0.6;

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = AdaptiveSheetNavigator.of(context);
    return BaseModal(
      title: 'Tune behavior',
      subtitle: 'Step 2 of 3',
      body: BaseModalBody.singleChild(
        child: Column(
          key: const ValueKey('navigation-step-2'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StepIcon(icon: Icons.tune),
            const SizedBox(height: 20),
            Text(
              'Tune the interaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'The project BaseModal reads canPop and supplies its back button '
              'without owning a Navigator or transition controller.',
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sendReminder,
              onChanged: (value) => setState(() => _sendReminder = value),
              title: const Text('Send a completion reminder'),
            ),
            Text('Automation level: ${(_automationLevel * 100).round()}%'),
            Slider(
              value: _automationLevel,
              onChanged: (value) => setState(() => _automationLevel = value),
            ),
          ],
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          OutlinedButton(
            onPressed: sheetNavigator.pop,
            child: const Text('Back'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await sheetNavigator.push<void>(
                const AdaptiveSheetPage<void>(
                  settings: RouteSettings(name: 'review'),
                  child: _ReviewPage(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _ReviewPage extends StatelessWidget {
  const _ReviewPage();

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = AdaptiveSheetNavigator.of(context);
    return BaseModal(
      title: 'Review',
      subtitle: 'Step 3 of 3',
      body: BaseModalBody.singleChild(
        child: Column(
          key: const ValueKey('navigation-step-3'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StepIcon(icon: Icons.task_alt),
            const SizedBox(height: 20),
            Text(
              'Ready to finish',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'The adaptive modal stayed open while PagedSheet coordinated '
              'three page routes and their different content sizes.',
            ),
            const SizedBox(height: 24),
            const Card(
              child: ListTile(
                leading: Icon(Icons.layers_outlined),
                title: Text('Three-page stack'),
                subtitle: Text('Explicit page back and complete modal close'),
              ),
            ),
          ],
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          OutlinedButton(
            onPressed: sheetNavigator.pop,
            child: const Text('Back'),
          ),
          FilledButton.icon(
            onPressed: sheetNavigator.close,
            icon: const Icon(Icons.check),
            label: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
