import 'package:flutter/widgets.dart';

import 'adaptive_sheet_presentation.dart';
import 'adaptive_sheet_theme.dart';

/// Exposes an adaptive route's current presentation and effective theme.
///
/// Descendants rebuild when a live window resize changes [presentation].
class AdaptiveSheetScope extends InheritedWidget {
  /// Creates an adaptive sheet scope.
  const AdaptiveSheetScope({
    required this.presentation,
    required this.theme,
    required super.child,
    super.key,
  });

  /// The presentation currently selected for the open route.
  final AdaptiveSheetPresentation presentation;

  /// The global package theme with per-route overrides applied.
  final AdaptiveSheetThemeData theme;

  /// Returns the closest scope and registers a dependency on it.
  static AdaptiveSheetScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AdaptiveSheetScope found in context.');
    return scope!;
  }

  /// Returns the closest scope, or null outside an adaptive sheet route.
  static AdaptiveSheetScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdaptiveSheetScope>();
  }

  @override
  bool updateShouldNotify(AdaptiveSheetScope oldWidget) {
    return presentation != oldWidget.presentation || theme != oldWidget.theme;
  }
}
