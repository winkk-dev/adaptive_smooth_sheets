import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'adaptive_sheet_scope.dart';

/// A generic adaptive-sheet layout with optional fixed top and bottom bars.
///
/// This intentionally exposes only the common layout capabilities needed by
/// application-level modal chrome; Smooth Sheets types stay internal to the
/// package API.
class AdaptiveSheetScaffold extends StatelessWidget {
  /// Creates an adaptive sheet content scaffold.
  const AdaptiveSheetScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomBar,
    this.backgroundColor,
    this.extendBodyBehindTopBar = false,
    this.extendBodyBehindBottomBar = false,
    this.keepBottomBarVisible = true,
    this.bottomBarAvoidsKeyboard = true,
  });

  /// The primary sheet content.
  final Widget body;

  /// An optional fixed widget above [body].
  final Widget? topBar;

  /// An optional fixed widget below [body].
  final Widget? bottomBar;

  /// The scaffold color, defaulting to the adaptive route surface color.
  final Color? backgroundColor;

  /// Whether [body] extends behind [topBar].
  final bool extendBodyBehindTopBar;

  /// Whether [body] extends behind [bottomBar].
  final bool extendBodyBehindBottomBar;

  /// Whether the bottom bar remains visible as the sheet moves.
  final bool keepBottomBarVisible;

  /// Whether the bottom bar moves above the software keyboard.
  final bool bottomBarAvoidsKeyboard;

  @override
  Widget build(BuildContext context) {
    final scopedSurfaceColor = AdaptiveSheetScope.maybeOf(context)?.theme.surfaceColor ?? Theme.of(context).colorScheme.surface;
    final bottomBarVisibility = keepBottomBarVisible
        ? BottomBarVisibility.always(ignoreBottomInset: bottomBarAvoidsKeyboard)
        : BottomBarVisibility.natural(
            ignoreBottomInset: bottomBarAvoidsKeyboard,
          );

    return SheetContentScaffold(
      backgroundColor: backgroundColor ?? scopedSurfaceColor,
      extendBodyBehindTopBar: extendBodyBehindTopBar,
      extendBodyBehindBottomBar: extendBodyBehindBottomBar,
      bottomBarVisibility: bottomBarVisibility,
      topBar: topBar,
      bottomBar: bottomBar,
      body: body,
    );
  }
}
