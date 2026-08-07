import 'dart:math' as math;

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'base_modal.dart';
import 'base_modal_theme.dart';
import 'base_tab_modal.dart';

/// Shows a compact modal using only project-level chrome.
Future<void> showQuickViewModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(
      child: _QuickViewModal(),
    ),
  );
}

/// Shows a lazy list to demonstrate scroll and sheet drag coordination.
Future<void> showLazyListModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _LazyListModal()),
  );
}

/// Shows state that can be edited before and after live presentation changes.
Future<void> showResizeStateModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _ResizeStateModal()),
  );
}

/// Shows a project-level tab modal.
Future<void> showTabsModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _TabsModal()),
  );
}

/// Shows sheet-aware pop interception for barrier, back, and swipe attempts.
Future<void> showGuardedDismissModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: _GuardedDismissModal()),
  );
}

/// Shows local package and project-chrome overrides layered over global theme.
Future<void> showLocallyThemedModal(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return showAdaptiveSheet<void>(
    context: context,
    config: AdaptiveSheetConfig(
      dialogWidth: 520,
      dialogMaxHeight: 620,
      surfaceColor: colors.tertiaryContainer,
      barrierColor: colors.tertiary.withValues(alpha: 0.28),
      bottomSheetBorderRadius: const BorderRadius.vertical(
        top: Radius.circular(44),
      ),
      dialogBorderRadius: BorderRadius.circular(44),
    ),
    page: const AdaptiveSheetPage<void>(child: _LocallyThemedModal()),
  );
}

class _QuickViewModal extends StatelessWidget {
  const _QuickViewModal();

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Quick view',
      subtitle: 'Short content uses its natural height',
      body: BaseModalBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PresentationBadge(),
            const SizedBox(height: 16),
            Text(
              'This content remains mounted when a resized window switches '
              'between the bottom-sheet and dialog surfaces.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const SelectableText(
              'Selection test: drag across this sentence with the mouse. The '
              'text should be selected instead of dragging the sheet.',
            ),
          ],
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          FilledButton(
            onPressed: AdaptiveSheetNavigator.of(context).close,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _TabsModal extends StatelessWidget {
  const _TabsModal();

  @override
  Widget build(BuildContext context) {
    return BaseTabModal(
      title: 'Workspace',
      subtitle: 'Flutter tabs inside an adaptive route',
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Activity'),
        Tab(text: 'Settings'),
      ],
      footer: BaseModalFooter(
        actions: [
          FilledButton(
            onPressed: AdaptiveSheetNavigator.of(context).close,
            child: const Text('Close'),
          ),
        ],
      ),
      children: const [
        BaseModalBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PresentationBadge(),
              SizedBox(height: 16),
              Text(
                'The DefaultTabController lives inside the preserved modal '
                'content tree, so the selected tab survives live resizing.',
              ),
            ],
          ),
        ),
        _ActivityTab(),
        _SettingsTab(),
      ],
    );
  }
}

class _LocallyThemedModal extends StatelessWidget {
  const _LocallyThemedModal();

  @override
  Widget build(BuildContext context) {
    final materialTheme = Theme.of(context);
    final colors = materialTheme.colorScheme;
    final localSurface = colors.tertiaryContainer;
    final localForeground = colors.onTertiaryContainer;
    final localChrome = BaseModalThemeData.of(context).copyWith(
      dragHandleColor: localForeground.withValues(alpha: 0.4),
      headerBackgroundColor: localSurface,
      headerForegroundColor: localForeground,
      headerDivider: BorderSide(
        color: localForeground.withValues(alpha: 0.18),
      ),
      footerBackgroundColor: localSurface,
      footerDivider: BorderSide(
        color: localForeground.withValues(alpha: 0.18),
      ),
    );

    return Theme(
      data: materialTheme.copyWith(
        extensions: [
          for (final extension in materialTheme.extensions.values)
            if (extension is! BaseModalThemeData) extension,
          localChrome,
        ],
      ),
      child: Builder(
        builder: (context) => BaseModal(
          title: 'Local theme',
          subtitle: 'One route overrides global package defaults',
          body: BaseModalBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.palette_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  'The outer radius, width, surface, and barrier come from '
                  'AdaptiveSheetConfig. Header and footer colors remain '
                  'project-level overrides.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          footer: BaseModalFooter(
            actions: [
              FilledButton(
                onPressed: AdaptiveSheetNavigator.of(context).close,
                child: const Text('Nice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresentationBadge extends StatelessWidget {
  const _PresentationBadge();

  @override
  Widget build(BuildContext context) {
    final presentation = AdaptiveSheetScope.of(context).presentation;
    final label = switch (presentation) {
      AdaptiveSheetPresentation.bottomSheet => 'Bottom sheet',
      AdaptiveSheetPresentation.dialog => 'Dialog',
    };
    return Chip(
      avatar: Icon(
        presentation == AdaptiveSheetPresentation.bottomSheet ? Icons.vertical_align_bottom : Icons.web_asset_outlined,
      ),
      label: Text(label),
    );
  }
}

class _LazyListModal extends StatefulWidget {
  const _LazyListModal();

  @override
  State<_LazyListModal> createState() => _LazyListModalState();
}

class _LazyListModalState extends State<_LazyListModal> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modalTheme = BaseModalThemeData.of(context);
    final availableHeight = MediaQuery.sizeOf(context).height * 0.62;
    final listHeight = math.min(540.0, math.max(280.0, availableHeight));

    return BaseModal(
      title: 'Lazy list',
      subtitle: 'Scroll content hands drag gestures back to the sheet',
      body: SizedBox(
        height: listHeight,
        child: ListView.separated(
          key: const PageStorageKey('lazy-list'),
          controller: _scrollController,
          padding: modalTheme.bodyPadding,
          itemCount: 500,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final number = index + 1;
            return ListTile(
              leading: CircleAvatar(child: Text('$number')),
              title: Text('Generated record $number'),
              subtitle: const Text('Built only when it enters the viewport'),
            );
          },
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            icon: const Icon(Icons.vertical_align_top),
            label: const Text('Top'),
          ),
          FilledButton(
            onPressed: AdaptiveSheetNavigator.of(context).close,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ResizeStateModal extends StatefulWidget {
  const _ResizeStateModal();

  @override
  State<_ResizeStateModal> createState() => _ResizeStateModalState();
}

class _ResizeStateModalState extends State<_ResizeStateModal> {
  var _count = 0;
  var _note = '';

  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Resize state',
      subtitle: 'Edit values, then resize across the breakpoint',
      body: BaseModalBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: _PresentationBadge(),
            ),
            const SizedBox(height: 16),
            Text('Counter: $_count'),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _count += 1),
              icon: const Icon(Icons.add),
              label: const Text('Increment'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _note,
              onChanged: (value) => _note = value,
              decoration: const InputDecoration(
                labelText: 'Temporary note',
                hintText: 'This input state also stays mounted',
              ),
            ),
          ],
        ),
      ),
      footer: BaseModalFooter(
        actions: [
          FilledButton(
            onPressed: AdaptiveSheetNavigator.of(context).close,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: BaseModalThemeData.of(context).bodyPadding,
      itemCount: 500,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.history),
        title: Text('Activity event ${index + 1}'),
        subtitle: const Text('Tab content can use its own lazy scroll view'),
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  var _notifications = true;
  var _compactRows = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: BaseModalThemeData.of(context).bodyPadding,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _notifications,
          onChanged: (value) => setState(() => _notifications = value),
          title: const Text('Notifications'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _compactRows,
          onChanged: (value) => setState(() => _compactRows = value),
          title: const Text('Compact rows'),
        ),
      ],
    );
  }
}

class _GuardedDismissModal extends StatefulWidget {
  const _GuardedDismissModal();

  @override
  State<_GuardedDismissModal> createState() => _GuardedDismissModalState();
}

class _GuardedDismissModalState extends State<_GuardedDismissModal> {
  var _hasUnsavedChanges = true;
  var _allowPop = false;
  var _isConfirming = false;

  void _closeAfterAllowingPop() {
    setState(() {
      _allowPop = true;
      _hasUnsavedChanges = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AdaptiveSheetNavigator.of(context).close();
      }
    });
  }

  Future<void> _confirmDiscard() async {
    if (_isConfirming) {
      return;
    }
    _isConfirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'This prompt also handles barrier, back, and swipe-dismiss attempts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _isConfirming = false;
    if (discard == true && mounted) {
      _closeAfterAllowingPop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = _allowPop || !_hasUnsavedChanges;
    return AdaptiveSheetPopScope<void>(
      canPop: canPop,
      onPopInvokedWithResult: canPop
          ? null
          : (didPop, result) {
              if (!didPop) {
                _confirmDiscard();
              }
            },
      child: BaseModal(
        title: 'Guarded close',
        subtitle: 'Smooth Sheets reports swipe dismissal attempts',
        body: BaseModalBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Try the close button, native device Back, modal barrier, or a '
                'downward swipe. Unsaved state intercepts every route pop.',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _hasUnsavedChanges,
                onChanged: (value) {
                  setState(() => _hasUnsavedChanges = value);
                },
                title: const Text('Has unsaved changes'),
              ),
            ],
          ),
        ),
        footer: BaseModalFooter(
          actions: [
            OutlinedButton(
              onPressed: _hasUnsavedChanges ? _confirmDiscard : AdaptiveSheetNavigator.of(context).close,
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: _closeAfterAllowingPop,
              child: const Text('Save & close'),
            ),
          ],
        ),
      ),
    );
  }
}
