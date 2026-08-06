import 'package:flutter/widgets.dart';

/// The visual presentation used for an adaptive sheet route.
enum AdaptiveSheetPresentation {
  /// A draggable surface attached to the bottom of the window.
  bottomSheet,

  /// A fixed-width surface centered in the available window area.
  dialog,
}

/// Selects a presentation using values available from [context].
///
/// Reading [MediaQuery] in a resolver makes an open route react when its
/// window is resized.
typedef AdaptiveSheetPresentationResolver = AdaptiveSheetPresentation Function(BuildContext context);

/// Controls how an adaptive sheet chooses its current presentation.
@immutable
class AdaptiveSheetPresentationPolicy {
  /// Creates a presentation policy.
  const AdaptiveSheetPresentationPolicy({this.dialogBreakpoint, this.resolver}) : assert(dialogBreakpoint == null || dialogBreakpoint >= 0);

  /// Overrides the global width breakpoint for this route.
  ///
  /// The dialog presentation is selected when the window is strictly wider
  /// than this value.
  final double? dialogBreakpoint;

  /// An optional resolver that takes precedence over [dialogBreakpoint].
  final AdaptiveSheetPresentationResolver? resolver;

  /// Resolves the presentation for the current window.
  ///
  /// [fallbackDialogBreakpoint] is normally supplied by the effective
  /// `AdaptiveSheetThemeData` by `showAdaptiveSheet`.
  AdaptiveSheetPresentation resolve(
    BuildContext context, {
    double fallbackDialogBreakpoint = 600,
  }) {
    final resolvedByCallback = resolver?.call(context);
    if (resolvedByCallback != null) {
      return resolvedByCallback;
    }

    final breakpoint = dialogBreakpoint ?? fallbackDialogBreakpoint;
    return MediaQuery.sizeOf(context).width > breakpoint ? AdaptiveSheetPresentation.dialog : AdaptiveSheetPresentation.bottomSheet;
  }
}
