import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'demo_sheet_scaffold.dart';

/// Opens a small page flow inside one adaptive modal.
Future<void> showNavigationDemo(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    config: const AdaptiveSheetConfig(dialogWidth: 520),
    page: const AdaptiveSheetPage<void>(child: _NavigationStartPage()),
  );
}

class _NavigationStartPage extends StatefulWidget {
  const _NavigationStartPage();

  @override
  State<_NavigationStartPage> createState() => _NavigationStartPageState();
}

class _NavigationStartPageState extends State<_NavigationStartPage> {
  var _stateValue = 0;

  @override
  Widget build(BuildContext context) {
    return DemoSheetScaffold(
      title: 'Modal navigation',
      subtitle: 'The first page stays mounted while another page covers it.',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('State value: $_stateValue', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => setState(() => _stateValue += 1),
              child: const Text('Increment state'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Push the next page, then pop it again. The value above remains '
              'because this first AdaptiveSheetPage is retained by default.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () {
            unawaited(
              AdaptiveSheetNavigator.of(context).push<void>(
                const AdaptiveSheetPage<void>(child: _NavigationDetailsPage()),
              ),
            );
          },
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Push next page'),
        ),
      ],
    );
  }
}

class _NavigationDetailsPage extends StatelessWidget {
  const _NavigationDetailsPage();

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = AdaptiveSheetNavigator.of(context);

    return DemoSheetScaffold(
      title: 'Second page',
      subtitle: 'Choose an internal page operation.',
      body: const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Text(
          'pop returns to the already-mounted first page. replace keeps that '
          'first page in the stack. replaceAll makes its result the new stack root.',
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => sheetNavigator.pop<void>(),
          child: const Text('Pop page'),
        ),
        OutlinedButton(
          onPressed: () {
            unawaited(
              sheetNavigator.replace<void, void>(
                const AdaptiveSheetPage<void>(child: _ReplacedPage()),
              ),
            );
          },
          child: const Text('replace'),
        ),
        FilledButton(
          onPressed: () {
            unawaited(
              sheetNavigator.replaceAll<void>(
                const AdaptiveSheetPage<void>(child: _CompletedPage()),
              ),
            );
          },
          child: const Text('replaceAll'),
        ),
      ],
    );
  }
}

class _ReplacedPage extends StatelessWidget {
  const _ReplacedPage();

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = AdaptiveSheetNavigator.of(context);

    return DemoSheetScaffold(
      title: 'Current page replaced',
      subtitle: 'The first page is still below this page in the stack.',
      body: const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Text(
          'Use the automatic header Back button or this footer action to reveal '
          'the original first page. It retains its counter state.',
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => sheetNavigator.pop<void>(),
          child: const Text('Pop page'),
        ),
        FilledButton(
          onPressed: () {
            unawaited(
              sheetNavigator.replaceAll<void>(
                const AdaptiveSheetPage<void>(child: _CompletedPage()),
              ),
            );
          },
          child: const Text('replaceAll'),
        ),
      ],
    );
  }
}

class _CompletedPage extends StatelessWidget {
  const _CompletedPage();

  @override
  Widget build(BuildContext context) {
    return DemoSheetScaffold(
      title: 'Entire stack replaced',
      subtitle: 'This confirmation page is the new internal stack root.',
      body: const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Text(
          'replaceAll removed every earlier page. There is no internal page to '
          'pop now, but the outer adaptive modal can still be closed normally.',
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
