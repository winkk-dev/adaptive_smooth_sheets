import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'adaptive_sheet_native_back_behavior.dart';

/// Flutter-only defaults for adaptive sheet routes and outer surfaces.
///
/// Add an instance to [ThemeData.extensions] to configure every adaptive
/// sheet below that theme. Route-specific values from `AdaptiveSheetConfig`
/// are applied afterward.
@immutable
class AdaptiveSheetThemeData extends ThemeExtension<AdaptiveSheetThemeData> {
  /// Creates a complete adaptive sheet theme.
  ///
  /// A null [surfaceColor] follows the ambient Material color scheme.
  const AdaptiveSheetThemeData({
    this.dialogBreakpoint = 600,
    this.dialogWidth = 600,
    this.dialogMaxHeight = 800,
    this.dialogMargin = const EdgeInsets.all(24),
    this.bottomSheetMinimumTopGap = 32,
    this.bottomSheetMinimumTopGapAfterSafeArea = 32,
    this.bottomSheetBorderRadius = const BorderRadius.vertical(
      top: Radius.circular(24),
    ),
    this.dialogBorderRadius = const BorderRadius.all(Radius.circular(24)),
    this.bottomSheetElevation = 0,
    this.dialogElevation = 12,
    this.surfaceColor,
    this.barrierColor = const Color(0x8A000000),
    this.barrierDismissible = true,
    this.enableDrag = true,
    this.swipeDismissible = true,
    this.useSafeArea = true,
    this.avoidKeyboardInset = true,
    this.nativeBackBehavior = AdaptiveSheetNativeBackBehavior.popPageOrCloseSheet,
    this.transitionDuration = const Duration(milliseconds: 250),
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
  }) : assert(dialogBreakpoint >= 0),
       assert(dialogWidth > 0),
       assert(dialogMaxHeight > 0),
       assert(bottomSheetMinimumTopGap >= 0),
       assert(bottomSheetMinimumTopGapAfterSafeArea >= 0),
       assert(bottomSheetElevation >= 0),
       assert(dialogElevation >= 0);

  /// Returns the registered theme, or safe package defaults when absent.
  static AdaptiveSheetThemeData of(BuildContext context) {
    return Theme.of(context).extension<AdaptiveSheetThemeData>() ?? const AdaptiveSheetThemeData();
  }

  /// The width above which the dialog presentation is selected.
  final double dialogBreakpoint;

  /// The preferred dialog surface width.
  final double dialogWidth;

  /// The maximum dialog surface height.
  final double dialogMaxHeight;

  /// The minimum distance between a dialog and the window edges.
  final EdgeInsets dialogMargin;

  /// The minimum gap between the window's top edge and a tall bottom sheet
  /// when there is no top safe-area inset.
  final double bottomSheetMinimumTopGap;

  /// The minimum gap between the bottom of a top safe-area inset and a tall
  /// bottom sheet.
  ///
  /// When [useSafeArea] is true and a top inset exists, the inset itself is
  /// added separately before this gap.
  final double bottomSheetMinimumTopGapAfterSafeArea;

  /// The mobile bottom sheet's corner radii.
  final BorderRadius bottomSheetBorderRadius;

  /// The dialog's corner radii.
  final BorderRadius dialogBorderRadius;

  /// The mobile bottom sheet elevation.
  final double bottomSheetElevation;

  /// The dialog elevation.
  final double dialogElevation;

  /// The surface color, or the ambient Material surface color when null.
  final Color? surfaceColor;

  /// The color painted behind the route.
  final Color barrierColor;

  /// Whether tapping the barrier dismisses the route.
  final bool barrierDismissible;

  /// Whether the bottom sheet responds to vertical drag gestures.
  final bool enableDrag;

  /// Whether a downward bottom-sheet drag may dismiss the route.
  ///
  /// Dragging must also be enabled for the gesture to originate in the sheet.
  final bool swipeDismissible;

  /// Whether presentations avoid platform safe areas.
  ///
  /// Bottom sheets reserve the top inset and pad their content on the other
  /// edges. Dialog margins expand to include unsafe areas.
  final bool useSafeArea;

  /// Whether sheet content and dialogs avoid the software keyboard inset.
  final bool avoidKeyboardInset;

  /// How native platform Back affects an internal page stack.
  ///
  /// This value has no effect on web builds. Escape, barrier taps, swipe
  /// dismissal, and explicit close requests always target the complete modal.
  final AdaptiveSheetNativeBackBehavior nativeBackBehavior;

  /// The duration of the outer modal's entrance and exit transitions.
  ///
  /// Internal page transitions use Smooth Sheets' platform defaults.
  final Duration transitionDuration;

  /// The curve used by the outer modal's entrance and exit transitions.
  ///
  /// Internal page transitions use Smooth Sheets' platform defaults.
  final Curve transitionCurve;

  @override
  AdaptiveSheetThemeData copyWith({
    double? dialogBreakpoint,
    double? dialogWidth,
    double? dialogMaxHeight,
    EdgeInsets? dialogMargin,
    double? bottomSheetMinimumTopGap,
    double? bottomSheetMinimumTopGapAfterSafeArea,
    BorderRadius? bottomSheetBorderRadius,
    BorderRadius? dialogBorderRadius,
    double? bottomSheetElevation,
    double? dialogElevation,
    Color? surfaceColor,
    Color? barrierColor,
    bool? barrierDismissible,
    bool? enableDrag,
    bool? swipeDismissible,
    bool? useSafeArea,
    bool? avoidKeyboardInset,
    AdaptiveSheetNativeBackBehavior? nativeBackBehavior,
    Duration? transitionDuration,
    Curve? transitionCurve,
  }) {
    return AdaptiveSheetThemeData(
      dialogBreakpoint: dialogBreakpoint ?? this.dialogBreakpoint,
      dialogWidth: dialogWidth ?? this.dialogWidth,
      dialogMaxHeight: dialogMaxHeight ?? this.dialogMaxHeight,
      dialogMargin: dialogMargin ?? this.dialogMargin,
      bottomSheetMinimumTopGap: bottomSheetMinimumTopGap ?? this.bottomSheetMinimumTopGap,
      bottomSheetMinimumTopGapAfterSafeArea: bottomSheetMinimumTopGapAfterSafeArea ?? this.bottomSheetMinimumTopGapAfterSafeArea,
      bottomSheetBorderRadius: bottomSheetBorderRadius ?? this.bottomSheetBorderRadius,
      dialogBorderRadius: dialogBorderRadius ?? this.dialogBorderRadius,
      bottomSheetElevation: bottomSheetElevation ?? this.bottomSheetElevation,
      dialogElevation: dialogElevation ?? this.dialogElevation,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      barrierColor: barrierColor ?? this.barrierColor,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      enableDrag: enableDrag ?? this.enableDrag,
      swipeDismissible: swipeDismissible ?? this.swipeDismissible,
      useSafeArea: useSafeArea ?? this.useSafeArea,
      avoidKeyboardInset: avoidKeyboardInset ?? this.avoidKeyboardInset,
      nativeBackBehavior: nativeBackBehavior ?? this.nativeBackBehavior,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionCurve: transitionCurve ?? this.transitionCurve,
    );
  }

  @override
  AdaptiveSheetThemeData lerp(
    covariant AdaptiveSheetThemeData? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }

    return AdaptiveSheetThemeData(
      dialogBreakpoint: ui.lerpDouble(
        dialogBreakpoint,
        other.dialogBreakpoint,
        t,
      )!,
      dialogWidth: ui.lerpDouble(dialogWidth, other.dialogWidth, t)!,
      dialogMaxHeight: ui.lerpDouble(
        dialogMaxHeight,
        other.dialogMaxHeight,
        t,
      )!,
      dialogMargin: EdgeInsets.lerp(dialogMargin, other.dialogMargin, t)!,
      bottomSheetMinimumTopGap: ui.lerpDouble(
        bottomSheetMinimumTopGap,
        other.bottomSheetMinimumTopGap,
        t,
      )!,
      bottomSheetMinimumTopGapAfterSafeArea: ui.lerpDouble(
        bottomSheetMinimumTopGapAfterSafeArea,
        other.bottomSheetMinimumTopGapAfterSafeArea,
        t,
      )!,
      bottomSheetBorderRadius: BorderRadius.lerp(
        bottomSheetBorderRadius,
        other.bottomSheetBorderRadius,
        t,
      )!,
      dialogBorderRadius: BorderRadius.lerp(
        dialogBorderRadius,
        other.dialogBorderRadius,
        t,
      )!,
      bottomSheetElevation: ui.lerpDouble(
        bottomSheetElevation,
        other.bottomSheetElevation,
        t,
      )!,
      dialogElevation: ui.lerpDouble(
        dialogElevation,
        other.dialogElevation,
        t,
      )!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
      barrierDismissible: t < 0.5 ? barrierDismissible : other.barrierDismissible,
      enableDrag: t < 0.5 ? enableDrag : other.enableDrag,
      swipeDismissible: t < 0.5 ? swipeDismissible : other.swipeDismissible,
      useSafeArea: t < 0.5 ? useSafeArea : other.useSafeArea,
      avoidKeyboardInset: t < 0.5 ? avoidKeyboardInset : other.avoidKeyboardInset,
      nativeBackBehavior: t < 0.5 ? nativeBackBehavior : other.nativeBackBehavior,
      transitionDuration: Duration(
        microseconds: ui
            .lerpDouble(
              transitionDuration.inMicroseconds,
              other.transitionDuration.inMicroseconds,
              t,
            )!
            .round(),
      ),
      transitionCurve: t < 0.5 ? transitionCurve : other.transitionCurve,
    );
  }
}
