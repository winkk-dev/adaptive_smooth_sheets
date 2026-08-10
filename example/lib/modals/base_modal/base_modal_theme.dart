import 'package:flutter/material.dart';

/// Project-level modal chrome used by the example application's base modal.
///
/// Responsive route geometry and behavior belong to
/// `AdaptiveSheetThemeData`; this extension contains only application UI.
@immutable
class BaseModalThemeData extends ThemeExtension<BaseModalThemeData> {
  /// Creates a project-level modal chrome theme.
  const BaseModalThemeData({
    required this.dragHandleColor,
    required this.headerBackgroundColor,
    required this.headerForegroundColor,
    required this.headerDivider,
    required this.footerBackgroundColor,
    required this.footerDivider,
    this.dragHandleSize = const Size(56, 4),
    this.dragHandlePadding = const EdgeInsets.fromLTRB(24, 12, 24, 4),
    this.headerPadding = const EdgeInsets.fromLTRB(24, 12, 16, 16),
    this.bodyPadding = const EdgeInsets.fromLTRB(24, 20, 24, 32),
    this.footerPadding = const EdgeInsets.fromLTRB(24, 16, 24, 20),
    this.footerOverflowGradientHeight = 24,
    this.footerOverflowGradientDuration = const Duration(milliseconds: 200),
  }) : assert(footerOverflowGradientHeight >= 0),
       assert(footerOverflowGradientDuration >= Duration.zero);

  /// Returns the registered extension or colors derived from the Material
  /// theme when the example is embedded without `AppTheme`.
  static BaseModalThemeData of(BuildContext context) {
    final materialTheme = Theme.of(context);
    final colors = materialTheme.colorScheme;
    return materialTheme.extension<BaseModalThemeData>() ??
        BaseModalThemeData(
          dragHandleColor: colors.outlineVariant,
          headerBackgroundColor: colors.surface,
          headerForegroundColor: colors.onSurface,
          headerDivider: BorderSide(color: colors.outlineVariant),
          footerBackgroundColor: colors.surface,
          footerDivider: BorderSide(color: colors.outlineVariant),
        );
  }

  /// The mobile drag handle color.
  final Color dragHandleColor;

  /// The mobile drag handle size.
  final Size dragHandleSize;

  /// Space around the mobile drag handle.
  final EdgeInsets dragHandlePadding;

  /// The header background color.
  final Color headerBackgroundColor;

  /// The header title and icon color.
  final Color headerForegroundColor;

  /// Padding around header content.
  final EdgeInsets headerPadding;

  /// The divider below the header.
  final BorderSide headerDivider;

  /// Default padding used by `BaseModalBody`.
  final EdgeInsets bodyPadding;

  /// The footer background color.
  final Color footerBackgroundColor;

  /// Padding around footer actions.
  final EdgeInsets footerPadding;

  /// The divider above the footer.
  final BorderSide footerDivider;

  /// Height of the fade indicating that body content continues below.
  final double footerOverflowGradientHeight;

  /// Animation duration of the footer overflow fade.
  final Duration footerOverflowGradientDuration;

  @override
  BaseModalThemeData copyWith({
    Color? dragHandleColor,
    Size? dragHandleSize,
    EdgeInsets? dragHandlePadding,
    Color? headerBackgroundColor,
    Color? headerForegroundColor,
    EdgeInsets? headerPadding,
    BorderSide? headerDivider,
    EdgeInsets? bodyPadding,
    Color? footerBackgroundColor,
    EdgeInsets? footerPadding,
    BorderSide? footerDivider,
    double? footerOverflowGradientHeight,
    Duration? footerOverflowGradientDuration,
  }) {
    return BaseModalThemeData(
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      dragHandleSize: dragHandleSize ?? this.dragHandleSize,
      dragHandlePadding: dragHandlePadding ?? this.dragHandlePadding,
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerForegroundColor: headerForegroundColor ?? this.headerForegroundColor,
      headerPadding: headerPadding ?? this.headerPadding,
      headerDivider: headerDivider ?? this.headerDivider,
      bodyPadding: bodyPadding ?? this.bodyPadding,
      footerBackgroundColor: footerBackgroundColor ?? this.footerBackgroundColor,
      footerPadding: footerPadding ?? this.footerPadding,
      footerDivider: footerDivider ?? this.footerDivider,
      footerOverflowGradientHeight: footerOverflowGradientHeight ?? this.footerOverflowGradientHeight,
      footerOverflowGradientDuration: footerOverflowGradientDuration ?? this.footerOverflowGradientDuration,
    );
  }

  @override
  BaseModalThemeData lerp(covariant BaseModalThemeData? other, double t) {
    if (other == null) {
      return this;
    }

    return BaseModalThemeData(
      dragHandleColor: Color.lerp(dragHandleColor, other.dragHandleColor, t)!,
      dragHandleSize: Size.lerp(dragHandleSize, other.dragHandleSize, t)!,
      dragHandlePadding: EdgeInsets.lerp(
        dragHandlePadding,
        other.dragHandlePadding,
        t,
      )!,
      headerBackgroundColor: Color.lerp(
        headerBackgroundColor,
        other.headerBackgroundColor,
        t,
      )!,
      headerForegroundColor: Color.lerp(
        headerForegroundColor,
        other.headerForegroundColor,
        t,
      )!,
      headerPadding: EdgeInsets.lerp(headerPadding, other.headerPadding, t)!,
      headerDivider: BorderSide.lerp(headerDivider, other.headerDivider, t),
      bodyPadding: EdgeInsets.lerp(bodyPadding, other.bodyPadding, t)!,
      footerBackgroundColor: Color.lerp(
        footerBackgroundColor,
        other.footerBackgroundColor,
        t,
      )!,
      footerPadding: EdgeInsets.lerp(footerPadding, other.footerPadding, t)!,
      footerDivider: BorderSide.lerp(footerDivider, other.footerDivider, t),
      footerOverflowGradientHeight: footerOverflowGradientHeight + (other.footerOverflowGradientHeight - footerOverflowGradientHeight) * t,
      footerOverflowGradientDuration: t < 0.5 ? footerOverflowGradientDuration : other.footerOverflowGradientDuration,
    );
  }
}
