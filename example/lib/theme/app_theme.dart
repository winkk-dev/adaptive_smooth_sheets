import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import '../modals/base_modal_theme.dart';

/// Material and modal themes for the example application.
class AppTheme {
  AppTheme._();

  /// The light example theme.
  static final ThemeData light = _build(Brightness.light);

  /// The dark example theme.
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF536DFE),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        border: const OutlineInputBorder(),
      ),
      extensions: [
        // Generic package mechanics are configured globally here.
        AdaptiveSheetThemeData(
          dialogBreakpoint: 720,
          dialogWidth: 640,
          dialogMaxHeight: 760,
          dialogMargin: const EdgeInsets.all(32),
          bottomSheetMinimumTopGap: 48,
          bottomSheetBorderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          dialogBorderRadius: BorderRadius.circular(28),
          surfaceColor: colors.surface,
          barrierColor: colors.scrim.withValues(alpha: 0.54),
          nativeBackBehavior: AdaptiveSheetNativeBackBehavior.popPageOrCloseSheet,
          bottomSheetPageTransition: const AdaptiveSheetPageTransition.platformDefault(),
          dialogPageTransition: const AdaptiveSheetPageTransition.sharedAxis(),
        ),
        // Application chrome stays independently customizable.
        BaseModalThemeData(
          dragHandleColor: colors.outlineVariant,
          headerBackgroundColor: colors.surface,
          headerForegroundColor: colors.onSurface,
          headerDivider: BorderSide(color: colors.outlineVariant),
          footerBackgroundColor: colors.surfaceContainerLow,
          footerDivider: BorderSide(color: colors.outlineVariant),
        ),
      ],
    );
  }
}
