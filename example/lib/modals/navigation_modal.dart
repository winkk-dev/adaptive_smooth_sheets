import 'dart:math' as math;

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'base_modal.dart';

/// Shows a multi-step flow backed by a nested Navigator.
Future<void> showNavigationModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    builder: (context) => const NavigationModal(),
  );
}

/// A three-step modal that keeps its own navigation history.
class NavigationModal extends StatefulWidget {
  /// Creates the navigation modal example.
  const NavigationModal({super.key});

  @override
  State<NavigationModal> createState() => _NavigationModalState();
}

class _NavigationModalState extends State<NavigationModal> {
  static const _stepTitles = ['Choose direction', 'Tune behavior', 'Review'];
  final _navigatorKey = GlobalKey<NavigatorState>();
  var _step = 0;

  void _next() {
    if (_step == _stepTitles.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    final nextStep = _step + 1;
    setState(() => _step = nextStep);
    _navigatorKey.currentState!.push(_routeFor(nextStep));
  }

  void _back() {
    if (_step == 0) {
      return;
    }

    setState(() => _step -= 1);
    _navigatorKey.currentState!.pop();
  }

  PageRoute<void> _routeFor(int step) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(name: 'navigation-step-${step + 1}'),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return switch (step) {
          0 => const _DirectionStep(),
          1 => const _BehaviorStep(),
          _ => const _ReviewStep(),
        };
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewPaddingOf(context).vertical;
    final bodyHeight = math.max(320.0, math.min(480.0, availableHeight * 0.54));

    return BaseModal(
      title: _stepTitles[_step],
      subtitle: 'Step ${_step + 1} of ${_stepTitles.length}',
      leading: _step == 0
          ? null
          : IconButton(
              onPressed: _back,
              tooltip: 'Previous step',
              icon: const Icon(Icons.arrow_back),
            ),
      body: SizedBox(
        height: bodyHeight,
        child: NavigatorPopHandler<void>(
          onPopWithResult: (_) => _back(),
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (settings) => _routeFor(0),
          ),
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          if (_step > 0)
            OutlinedButton(onPressed: _back, child: const Text('Back')),
          FilledButton.icon(
            onPressed: _next,
            icon: Icon(
              _step == _stepTitles.length - 1
                  ? Icons.check
                  : Icons.arrow_forward,
            ),
            label: Text(
              _step == _stepTitles.length - 1 ? 'Finish' : 'Continue',
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionStep extends StatefulWidget {
  const _DirectionStep();

  @override
  State<_DirectionStep> createState() => _DirectionStepState();
}

class _DirectionStepState extends State<_DirectionStep> {
  var _selection = 0;

  @override
  Widget build(BuildContext context) {
    return BaseModalBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepIcon(icon: Icons.route_outlined),
          const SizedBox(height: 20),
          Text(
            'Choose a starting direction',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Each step is a route in a nested Navigator. Its local widget '
            'state remains alive when you move forward and then return.',
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
    );
  }
}

class _BehaviorStep extends StatefulWidget {
  const _BehaviorStep();

  @override
  State<_BehaviorStep> createState() => _BehaviorStepState();
}

class _BehaviorStepState extends State<_BehaviorStep> {
  var _sendReminder = true;
  var _automationLevel = 0.6;

  @override
  Widget build(BuildContext context) {
    return BaseModalBody(
      child: Column(
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
            'Use system back or the header back action to reverse the inner '
            'route before dismissing the outer modal.',
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
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    return BaseModalBody(
      child: Column(
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
            'The adaptive sheet stayed open while the nested Navigator '
            'animated between three independent routes.',
          ),
          const SizedBox(height: 24),
          const Card(
            child: ListTile(
              leading: Icon(Icons.layers_outlined),
              title: Text('Three route stack'),
              subtitle: Text('Forward, reverse, and system-back navigation'),
            ),
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
