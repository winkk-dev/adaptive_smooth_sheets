import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'adaptive_sheet_config.dart';
import 'adaptive_sheet_presentation.dart';
import 'adaptive_sheet_scope.dart';
import 'adaptive_sheet_theme.dart';

/// Shows a modal that adapts between a bottom sheet and a dialog.
///
/// Presentation is resolved inside the route, so an already-open modal reacts
/// when its window crosses the configured breakpoint. The element built by
/// [builder] is preserved while it moves between presentation surfaces.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  AdaptiveSheetConfig config = const AdaptiveSheetConfig(),
}) {
  final theme = config.resolveTheme(AdaptiveSheetThemeData.of(context));
  final route = _AdaptiveSheetRoute<T>(
    config: config,
    theme: theme,
    builder: builder,
    barrierLabel:
        config.barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
  );

  return Navigator.of(
    context,
    rootNavigator: config.useRootNavigator,
  ).push(route);
}

class _AdaptiveSheetRoute<T> extends ModalSheetRoute<T> {
  _AdaptiveSheetRoute({
    required this.config,
    required this.theme,
    required WidgetBuilder builder,
    required String barrierLabel,
  }) : super(
         settings: config.routeSettings,
         maintainState: config.maintainState,
         barrierDismissible: theme.barrierDismissible,
         barrierLabel: barrierLabel,
         barrierColor: theme.barrierColor,
         swipeDismissible: theme.swipeDismissible,
         transitionDuration: theme.transitionDuration,
         transitionCurve: theme.transitionCurve,
         viewportBuilder: (context, child) {
           final presentation = config.presentationPolicy.resolve(
             context,
             fallbackDialogBreakpoint: theme.dialogBreakpoint,
           );
           final topSafeArea = theme.useSafeArea
               ? MediaQuery.viewPaddingOf(context).top
               : 0.0;
           final topPadding = switch (presentation) {
             AdaptiveSheetPresentation.dialog => 0.0,
             AdaptiveSheetPresentation.bottomSheet when topSafeArea > 0 =>
               topSafeArea + theme.bottomSheetMinimumTopGapAfterSafeArea,
             AdaptiveSheetPresentation.bottomSheet =>
               theme.bottomSheetMinimumTopGap,
           };

           return SheetViewport(
             padding: EdgeInsets.only(top: topPadding),
             child: child,
           );
         },
         builder: (context) =>
             _AdaptiveSheet(config: config, theme: theme, builder: builder),
       );

  final AdaptiveSheetConfig config;
  final AdaptiveSheetThemeData theme;

  AdaptiveSheetPresentation _presentationOf(BuildContext context) {
    return config.presentationPolicy.resolve(
      context,
      fallbackDialogBreakpoint: theme.dialogBreakpoint,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_presentationOf(context) == AdaptiveSheetPresentation.bottomSheet) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: transitionCurve,
      reverseCurve: transitionCurve.flipped,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

class _AdaptiveSheet extends StatefulWidget {
  const _AdaptiveSheet({
    required this.config,
    required this.theme,
    required this.builder,
  });

  final AdaptiveSheetConfig config;
  final AdaptiveSheetThemeData theme;
  final WidgetBuilder builder;

  @override
  State<_AdaptiveSheet> createState() => _AdaptiveSheetState();
}

class _AdaptiveSheetState extends State<_AdaptiveSheet> {
  // A global key lets Flutter move the existing content element between the
  // two surface trees instead of recreating state, scroll positions, or forms.
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'adaptive-sheet-content');

  @override
  Widget build(BuildContext context) {
    final presentation = widget.config.presentationPolicy.resolve(
      context,
      fallbackDialogBreakpoint: widget.theme.dialogBreakpoint,
    );
    final isBottomSheet = presentation == AdaptiveSheetPresentation.bottomSheet;

    Widget content = AdaptiveSheetScope(
      presentation: presentation,
      theme: widget.theme,
      child: KeyedSubtree(
        key: _contentKey,
        child: Builder(builder: widget.builder),
      ),
    );

    if (isBottomSheet && widget.theme.useSafeArea) {
      content = SafeArea(top: false, child: content);
    }

    return Sheet(
      scrollConfiguration: isBottomSheet
          ? const SheetScrollConfiguration(
              scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop,
            )
          : SheetScrollConfiguration.disabled,
      dragConfiguration: isBottomSheet && widget.theme.enableDrag
          ? const SheetDragConfiguration()
          : SheetDragConfiguration.disabled,
      padding: isBottomSheet && widget.theme.avoidKeyboardInset
          ? EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)
          : EdgeInsets.zero,
      decoration: isBottomSheet
          ? MaterialSheetDecoration(
              size: SheetSize.fit,
              elevation: widget.theme.bottomSheetElevation,
              color: widget.theme.surfaceColor,
              borderRadius: widget.theme.bottomSheetBorderRadius,
              clipBehavior: Clip.antiAlias,
            )
          : const SheetDecorationBuilder(
              size: SheetSize.stretch,
              builder: _buildUndecoratedSheet,
            ),
      child: isBottomSheet
          ? content
          : _AdaptiveDialogSurface(theme: widget.theme, child: content),
    );
  }
}

Widget _buildUndecoratedSheet(BuildContext context, Widget child) => child;

class _AdaptiveDialogSurface extends StatelessWidget {
  const _AdaptiveDialogSurface({required this.theme, required this.child});

  final AdaptiveSheetThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewPadding = theme.useSafeArea
        ? MediaQuery.viewPaddingOf(context)
        : EdgeInsets.zero;
    final keyboardBottom = theme.avoidKeyboardInset
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final margin = EdgeInsets.fromLTRB(
      math.max(theme.dialogMargin.left, viewPadding.left),
      math.max(theme.dialogMargin.top, viewPadding.top),
      math.max(theme.dialogMargin.right, viewPadding.right),
      math.max(
        math.max(theme.dialogMargin.bottom, viewPadding.bottom),
        keyboardBottom == 0 ? 0 : keyboardBottom + theme.dialogMargin.bottom,
      ),
    );

    return Padding(
      padding: margin,
      child: Center(
        child: SizedBox(
          width: theme.dialogWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: theme.dialogMaxHeight),
            child: Material(
              elevation: theme.dialogElevation,
              color:
                  theme.surfaceColor ?? Theme.of(context).colorScheme.surface,
              borderRadius: theme.dialogBorderRadius,
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
