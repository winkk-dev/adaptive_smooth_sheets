import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'adaptive_sheet_presentation.dart';
import 'adaptive_sheet_scope.dart';

// PrimaryScrollController otherwise auto-inherits on mobile platforms only.
const _allTargetPlatforms = <TargetPlatform>{
  TargetPlatform.android,
  TargetPlatform.fuchsia,
  TargetPlatform.iOS,
  TargetPlatform.linux,
  TargetPlatform.macOS,
  TargetPlatform.windows,
};

/// The primary controller shared by scroll views in an adaptive sheet page.
///
/// The package creates this controller automatically. Use [of] when an action
/// needs to control the page's primary scroll view directly.
class AdaptiveSheetScrollController extends SheetScrollController {
  AdaptiveSheetScrollController._() : super(debugLabel: 'adaptive-sheet-primary');

  /// Returns the controller for the nearest [AdaptiveSheetPage].
  static AdaptiveSheetScrollController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'No AdaptiveSheetScrollController found in context. '
      'The context must be below an AdaptiveSheetPage.',
    );
    return controller!;
  }

  /// Returns the nearest controller, or null outside an adaptive sheet page.
  static AdaptiveSheetScrollController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AdaptiveSheetScrollControllerScope>()?.controller;
  }
}

/// Package-owned provider installed around every adaptive sheet page.
@internal
class AdaptiveSheetScrollControllerProvider extends StatefulWidget {
  const AdaptiveSheetScrollControllerProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AdaptiveSheetScrollControllerProvider> createState() => _AdaptiveSheetScrollControllerProviderState();
}

class _AdaptiveSheetScrollControllerProviderState extends State<AdaptiveSheetScrollControllerProvider> {
  final _controller = AdaptiveSheetScrollController._();

  // Keeps page content mounted when SheetScrollable is added or removed.
  final _contentKey = GlobalKey(
    debugLabel: 'adaptive-sheet-scroll-content',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One controller for inherited scroll views and direct page actions.
    final primaryScrollContent = PrimaryScrollController(
      key: _contentKey,
      controller: _controller,
      automaticallyInheritForPlatforms: _allTargetPlatforms,
      scrollDirection: Axis.vertical,
      child: _AdaptiveSheetScrollControllerScope(
        controller: _controller,
        child: widget.child,
      ),
    );

    // Dialogs do not need SheetScrollable's sheet-drag handoff.
    if (AdaptiveSheetScope.of(context).presentation == AdaptiveSheetPresentation.dialog) {
      return primaryScrollContent;
    }

    return SheetScrollable(
      controller: _controller,
      child: primaryScrollContent,
    );
  }
}

class _AdaptiveSheetScrollControllerScope extends InheritedWidget {
  const _AdaptiveSheetScrollControllerScope({
    required this.controller,
    required super.child,
  });

  final AdaptiveSheetScrollController controller;

  @override
  bool updateShouldNotify(_AdaptiveSheetScrollControllerScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
