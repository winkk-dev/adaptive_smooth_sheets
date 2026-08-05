import 'package:flutter/material.dart';

import 'adaptive_sheet_presentation.dart';
import 'adaptive_sheet_theme.dart';

/// Per-route behavior and optional overrides for an adaptive sheet.
///
/// Null visual and interaction values inherit from the nearest
/// [AdaptiveSheetThemeData]. Navigator behavior is intentionally configured
/// per route instead of being animated as part of a theme.
@immutable
class AdaptiveSheetConfig {
  /// Creates an adaptive sheet configuration.
  const AdaptiveSheetConfig({
    this.presentationPolicy = const AdaptiveSheetPresentationPolicy(),
    this.useRootNavigator = true,
    this.maintainState = true,
    this.routeSettings,
    this.barrierLabel,
    this.dialogWidth,
    this.dialogMaxHeight,
    this.dialogMargin,
    this.bottomSheetMinimumTopGap,
    this.bottomSheetMinimumTopGapAfterSafeArea,
    this.bottomSheetBorderRadius,
    this.dialogBorderRadius,
    this.bottomSheetElevation,
    this.dialogElevation,
    this.surfaceColor,
    this.barrierColor,
    this.barrierDismissible,
    this.enableDrag,
    this.swipeDismissible,
    this.useSafeArea,
    this.avoidKeyboardInset,
    this.transitionDuration,
    this.transitionCurve,
  }) : assert(dialogWidth == null || dialogWidth > 0),
       assert(dialogMaxHeight == null || dialogMaxHeight > 0),
       assert(
         bottomSheetMinimumTopGap == null || bottomSheetMinimumTopGap >= 0,
       ),
       assert(
         bottomSheetMinimumTopGapAfterSafeArea == null ||
             bottomSheetMinimumTopGapAfterSafeArea >= 0,
       ),
       assert(bottomSheetElevation == null || bottomSheetElevation >= 0),
       assert(dialogElevation == null || dialogElevation >= 0);

  /// The responsive presentation rules for this route.
  final AdaptiveSheetPresentationPolicy presentationPolicy;

  /// Whether to push the route onto the root navigator.
  final bool useRootNavigator;

  /// Whether the route retains its state while covered by another route.
  final bool maintainState;

  /// Settings attached to the pushed route.
  final RouteSettings? routeSettings;

  /// A semantic label for the modal barrier.
  ///
  /// The localized Material dismiss label is used when this is null.
  final String? barrierLabel;

  /// Overrides [AdaptiveSheetThemeData.dialogWidth].
  final double? dialogWidth;

  /// Overrides [AdaptiveSheetThemeData.dialogMaxHeight].
  final double? dialogMaxHeight;

  /// Overrides [AdaptiveSheetThemeData.dialogMargin].
  final EdgeInsets? dialogMargin;

  /// Overrides [AdaptiveSheetThemeData.bottomSheetMinimumTopGap].
  final double? bottomSheetMinimumTopGap;

  /// Overrides
  /// [AdaptiveSheetThemeData.bottomSheetMinimumTopGapAfterSafeArea].
  final double? bottomSheetMinimumTopGapAfterSafeArea;

  /// Overrides [AdaptiveSheetThemeData.bottomSheetBorderRadius].
  final BorderRadius? bottomSheetBorderRadius;

  /// Overrides [AdaptiveSheetThemeData.dialogBorderRadius].
  final BorderRadius? dialogBorderRadius;

  /// Overrides [AdaptiveSheetThemeData.bottomSheetElevation].
  final double? bottomSheetElevation;

  /// Overrides [AdaptiveSheetThemeData.dialogElevation].
  final double? dialogElevation;

  /// Overrides [AdaptiveSheetThemeData.surfaceColor].
  final Color? surfaceColor;

  /// Overrides [AdaptiveSheetThemeData.barrierColor].
  final Color? barrierColor;

  /// Overrides [AdaptiveSheetThemeData.barrierDismissible].
  final bool? barrierDismissible;

  /// Overrides [AdaptiveSheetThemeData.enableDrag].
  final bool? enableDrag;

  /// Overrides [AdaptiveSheetThemeData.swipeDismissible].
  final bool? swipeDismissible;

  /// Overrides [AdaptiveSheetThemeData.useSafeArea].
  final bool? useSafeArea;

  /// Overrides [AdaptiveSheetThemeData.avoidKeyboardInset].
  final bool? avoidKeyboardInset;

  /// Overrides [AdaptiveSheetThemeData.transitionDuration].
  final Duration? transitionDuration;

  /// Overrides [AdaptiveSheetThemeData.transitionCurve].
  final Curve? transitionCurve;

  /// Applies this route's overrides to [baseTheme].
  AdaptiveSheetThemeData resolveTheme(AdaptiveSheetThemeData baseTheme) {
    return baseTheme.copyWith(
      dialogBreakpoint: presentationPolicy.dialogBreakpoint,
      dialogWidth: dialogWidth,
      dialogMaxHeight: dialogMaxHeight,
      dialogMargin: dialogMargin,
      bottomSheetMinimumTopGap: bottomSheetMinimumTopGap,
      bottomSheetMinimumTopGapAfterSafeArea:
          bottomSheetMinimumTopGapAfterSafeArea,
      bottomSheetBorderRadius: bottomSheetBorderRadius,
      dialogBorderRadius: dialogBorderRadius,
      bottomSheetElevation: bottomSheetElevation,
      dialogElevation: dialogElevation,
      surfaceColor: surfaceColor,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      enableDrag: enableDrag,
      swipeDismissible: swipeDismissible,
      useSafeArea: useSafeArea,
      avoidKeyboardInset: avoidKeyboardInset,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
    );
  }
}
