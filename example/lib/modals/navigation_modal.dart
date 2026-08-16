import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'base_modal/base_modal.dart';

/// Configures and shows a three-page flow using the package-owned navigator.
Future<void> showNavigationModal(BuildContext context) async {
  final options = await showAdaptiveSheet<_NavigationDemoOptions>(
    context: context,
    config: const AdaptiveSheetConfig(
      dialogWidth: 480,
      dialogMaxHeight: 560,
    ),
    page: const AdaptiveSheetPage<_NavigationDemoOptions>(
      settings: RouteSettings(name: 'navigation-state-setup'),
      child: _NavigationStateSetupModal(),
    ),
  );
  if (options == null || !context.mounted) {
    return;
  }

  await _showNavigationFlow(context, options);
}

Future<void> _showNavigationFlow(
  BuildContext context,
  _NavigationDemoOptions options,
) {
  return showAdaptiveSheet<void>(
    context: context,
    config: AdaptiveSheetConfig(
      maintainState: options.routeMaintainState,
    ),
    page: AdaptiveSheetPage<void>(
      settings: const RouteSettings(name: 'direction'),
      maintainState: options.pageMaintainState,
      child: _DirectionPage(
        routeMaintainState: options.routeMaintainState,
        pageMaintainState: options.pageMaintainState,
      ),
    ),
  );
}

class _NavigationDemoOptions {
  const _NavigationDemoOptions({
    required this.routeMaintainState,
    required this.pageMaintainState,
  });

  final bool routeMaintainState;
  final bool pageMaintainState;
}

class _NavigationStateSetupModal extends StatefulWidget {
  const _NavigationStateSetupModal();

  @override
  State<_NavigationStateSetupModal> createState() => _NavigationStateSetupModalState();
}

class _NavigationStateSetupModalState extends State<_NavigationStateSetupModal> {
  var _routeMaintainState = true;
  var _pageMaintainState = true;

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = AdaptiveSheetNavigator.of(context);
    return BaseModal(
      title: 'Navigation state setup',
      subtitle: 'Choose what Flutter may discard',
      body: BaseModalBody.singleChild(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep whole modal state'),
              subtitle: const Text(
                'AdaptiveSheetConfig. Applies when an opaque route covers '
                'the complete modal.',
              ),
              value: _routeMaintainState,
              onChanged: (value) {
                setState(() => _routeMaintainState = value);
              },
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep internal page state'),
              subtitle: const Text(
                'AdaptiveSheetPage. Applies when Continue pushes another '
                'page inside the modal.',
              ),
              value: _pageMaintainState,
              onChanged: (value) {
                setState(() => _pageMaintainState = value);
              },
            ),
          ],
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          FilledButton.icon(
            onPressed: () {
              sheetNavigator.close(
                _NavigationDemoOptions(
                  routeMaintainState: _routeMaintainState,
                  pageMaintainState: _pageMaintainState,
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Open navigation flow'),
          ),
        ],
      ),
    );
  }
}

class _DirectionPage extends StatefulWidget {
  const _DirectionPage({
    required this.routeMaintainState,
    required this.pageMaintainState,
  });

  final bool routeMaintainState;
  final bool pageMaintainState;

  @override
  State<_DirectionPage> createState() => _DirectionPageState();
}

class _DirectionPageState extends State<_DirectionPage> {
  static var _createdStateCount = 0;

  var _selection = 0;
  var _opaqueRouteReturnCount = 0;
  String? _modalSelection;
  late final int _stateInstance;

  @override
  void initState() {
    super.initState();
    _stateInstance = ++_createdStateCount;
  }

  Future<void> _openSelectionModal() async {
    final selection = await showAdaptiveSheet<String>(
      context: context,
      config: const AdaptiveSheetConfig(
        dialogWidth: 420,
        dialogMaxHeight: 460,
      ),
      page: const AdaptiveSheetPage<String>(
        settings: RouteSettings(name: 'compact-selection'),
        child: _CompactSelectionModal(),
      ),
    );
    if (mounted && selection != null) {
      setState(() => _modalSelection = selection);
    }
  }

  Future<void> _openOpaqueRoute() async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'opaque-maintain-state-test'),
        builder: (context) => const _OpaqueCoveragePage(),
      ),
    );
    if (mounted) {
      setState(() => _opaqueRouteReturnCount++);
    }
  }

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
            const SizedBox(height: 24),
            Text(
              'Two independent settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _MaintainStateSetting(
              name: 'AdaptiveSheetConfig',
              value: widget.routeMaintainState,
              description:
                  'Controls the whole modal when an opaque route '
                  'covers it.',
            ),
            const SizedBox(height: 8),
            _MaintainStateSetting(
              name: 'AdaptiveSheetPage',
              value: widget.pageMaintainState,
              description:
                  'Controls this page when Continue pushes the next '
                  'page inside the modal.',
            ),
            const SizedBox(height: 12),
            Text(
              'State instance #$_stateInstance. Change the direction above, '
              'then try both coverage types.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openSelectionModal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Show smaller adaptive modal'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adaptive modals are non-opaque, so this page stays mounted '
              'with either maintainState setting.',
            ),
            if (_modalSelection case final selection?) ...[
              const SizedBox(height: 8),
              Text('Selection modal returned: $selection'),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openOpaqueRoute,
              icon: const Icon(Icons.fullscreen),
              label: const Text('Cover with an opaque route'),
            ),
            const SizedBox(height: 8),
            Text(
              widget.routeMaintainState
                  ? 'This page stays mounted, preserving its direction and '
                        'state instance.'
                  : 'Flutter may dispose this page. Returning recreates it '
                        'with Mobile selected and a new state instance.',
            ),
            if (_opaqueRouteReturnCount > 0) ...[
              const SizedBox(height: 8),
              Text('Returned while mounted: $_opaqueRouteReturnCount'),
            ],
          ],
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          FilledButton.icon(
            onPressed: () {
              sheetNavigator.push<void>(
                AdaptiveSheetPage<void>(
                  settings: const RouteSettings(name: 'behavior'),
                  maintainState: widget.pageMaintainState,
                  child: const _BehaviorPage(),
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

class _MaintainStateSetting extends StatelessWidget {
  const _MaintainStateSetting({
    required this.name,
    required this.value,
    required this.description,
  });

  final String name;
  final bool value;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$name.maintainState: $value',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(description),
          ],
        ),
      ),
    );
  }
}

class _CompactSelectionModal extends StatefulWidget {
  const _CompactSelectionModal();

  @override
  State<_CompactSelectionModal> createState() => _CompactSelectionModalState();
}

class _CompactSelectionModalState extends State<_CompactSelectionModal> {
  var _selection = 'Design';

  @override
  Widget build(BuildContext context) {
    final sheetNavigator = AdaptiveSheetNavigator.of(context);
    return BaseModal(
      title: 'Select a workspace',
      subtitle: 'A separate, narrower adaptive modal',
      body: BaseModalBody.singleChild(
        child: RadioGroup<String>(
          groupValue: _selection,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selection = value);
            }
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'Design',
                title: Text('Design'),
              ),
              RadioListTile<String>(
                value: 'Engineering',
                title: Text('Engineering'),
              ),
              RadioListTile<String>(
                value: 'Operations',
                title: Text('Operations'),
              ),
            ],
          ),
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          FilledButton(
            onPressed: () => sheetNavigator.close(_selection),
            child: const Text('Use selection'),
          ),
        ],
      ),
    );
  }
}

class _OpaqueCoveragePage extends StatelessWidget {
  const _OpaqueCoveragePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opaque route')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers_clear_outlined, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'The navigation modal is now completely hidden',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Because this route is opaque, Flutter can discard the '
                    'covered sheet when its maintainState is false.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to modal'),
                  ),
                ],
              ),
            ),
          ),
        ),
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
