import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'adaptive_sheet_config.dart';
import 'adaptive_sheet_native_back_behavior.dart';
import 'adaptive_sheet_page.dart';
import 'adaptive_sheet_page_transition.dart';
import 'adaptive_sheet_presentation.dart';
import 'adaptive_sheet_scope.dart';
import 'adaptive_sheet_theme.dart';

part 'adaptive_sheet_navigator.dart';
part 'adaptive_sheet_pop_scope.dart';

/// Shows a modal containing one initial [AdaptiveSheetPage].
///
/// Presentation is resolved inside the route, so an already-open modal reacts
/// when its window crosses the configured breakpoint. Push more pages through
/// [AdaptiveSheetNavigator] from a context below [page].
///
/// The returned future completes with the value passed to
/// [AdaptiveSheetNavigator.close], or null when the modal is dismissed without
/// a result.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required AdaptiveSheetPage<T> page,
  AdaptiveSheetConfig config = const AdaptiveSheetConfig(),
}) {
  final theme = config.resolveTheme(AdaptiveSheetThemeData.of(context));
  final route = _AdaptiveSheetRoute<T>(
    config: config,
    theme: theme,
    page: page,
    barrierLabel: config.barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
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
    required AdaptiveSheetPage<T> page,
    required String barrierLabel,
  }) : super(
         settings: config.routeSettings,
         maintainState: config.maintainState,
         barrierDismissible: theme.barrierDismissible,
         barrierLabel: barrierLabel,
         barrierColor: theme.barrierColor,
         swipeDismissible: theme.swipeDismissible,
         transitionDuration: theme.openCloseTransitionDuration,
         transitionCurve: theme.openCloseTransitionCurve,
         barrierBuilder: _buildAdaptiveSheetBarrier,
         viewportBuilder: (context, child) {
           final presentation = config.presentationPolicy.resolve(
             context,
             fallbackDialogBreakpoint: theme.dialogBreakpoint,
           );
           final topSafeArea = theme.useSafeArea ? MediaQuery.viewPaddingOf(context).top : 0.0;
           final topPadding = switch (presentation) {
             AdaptiveSheetPresentation.dialog => 0.0,
             AdaptiveSheetPresentation.bottomSheet when topSafeArea > 0 => topSafeArea + theme.bottomSheetMinimumTopGapAfterSafeArea,
             AdaptiveSheetPresentation.bottomSheet => theme.bottomSheetMinimumTopGap,
           };

           return SheetViewport(
             padding: EdgeInsets.only(top: topPadding),
             child: child,
           );
         },
         builder: (context) => _AdaptiveSheet<T>(
           config: config,
           theme: theme,
           page: page,
         ),
       );

  final AdaptiveSheetConfig config;
  final AdaptiveSheetThemeData theme;
  VoidCallback? _closeFromBarrier;
  bool Function()? _canClose;

  @override
  RoutePopDisposition get popDisposition {
    // A system-back PopScope can block the outer route while an internal page
    // is active. Smooth Sheets owns swipe dismissal separately, so let an
    // allowed swipe finish without mutating pop scopes during its drag.
    if ((navigator?.userGestureInProgress ?? false) && (_canClose?.call() ?? true)) {
      return RoutePopDisposition.pop;
    }
    return super.popDisposition;
  }

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
      curve: theme.openCloseTransitionCurve,
      reverseCurve: theme.openCloseTransitionCurve.flipped,
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

Widget _buildAdaptiveSheetBarrier<T>(
  ModalRoute<T> modalRoute,
  VoidCallback defaultOnDismiss,
) {
  final route = modalRoute as _AdaptiveSheetRoute<T>;

  void onDismiss() {
    if (route.animation!.isCompleted && !route.navigator!.userGestureInProgress) {
      route._closeFromBarrier?.call();
    }
  }

  final barrierColor = route.barrierColor;
  if (barrierColor != null && barrierColor.a != 0 && !route.offstage) {
    return AnimatedModalBarrier(
      onDismiss: onDismiss,
      dismissible: route.barrierDismissible,
      semanticsLabel: route.barrierLabel,
      barrierSemanticsDismissible: route.semanticsDismissible,
      color: route.sheetVisibility.drive(
        ColorTween(
          begin: barrierColor.withValues(alpha: 0),
          end: barrierColor,
        ),
      ),
    );
  }

  return ModalBarrier(
    onDismiss: onDismiss,
    dismissible: route.barrierDismissible,
    semanticsLabel: route.barrierLabel,
    barrierSemanticsDismissible: route.semanticsDismissible,
  );
}

class _AdaptiveSheet<T> extends StatefulWidget {
  const _AdaptiveSheet({
    required this.config,
    required this.theme,
    required this.page,
  });

  final AdaptiveSheetConfig config;
  final AdaptiveSheetThemeData theme;
  final AdaptiveSheetPage<T> page;

  @override
  State<_AdaptiveSheet<T>> createState() => _AdaptiveSheetState<T>();
}

class _AdaptiveSheetState<T> extends State<_AdaptiveSheet<T>> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'adaptive-sheet-navigator',
  );
  AdaptiveSheetNavigator? _sheetNavigator;
  _AdaptiveSheetRoute<T>? _outerRoute;

  AdaptiveSheetNavigator get _navigator {
    return _sheetNavigator ??= AdaptiveSheetNavigator._(
      navigatorKey: _navigatorKey,
      forceCloseSheet: <R>(R? result) {
        Navigator.of(context).pop<R>(result);
      },
    );
  }

  void _closeFromBarrier() {
    _navigator.close();
  }

  @override
  void dispose() {
    _outerRoute
      ?.._closeFromBarrier = null
      .._canClose = null;
    _sheetNavigator?._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.config.presentationPolicy.resolve(
      context,
      fallbackDialogBreakpoint: widget.theme.dialogBreakpoint,
    );
    final isBottomSheet = presentation == AdaptiveSheetPresentation.bottomSheet;
    final sheetNavigator = _navigator;
    final outerRoute = ModalRoute.of(context)! as _AdaptiveSheetRoute<T>;
    _outerRoute = outerRoute
      .._closeFromBarrier = _closeFromBarrier
      .._canClose = (() => sheetNavigator._canClose);
    final safePadding = isBottomSheet && widget.theme.useSafeArea ? MediaQuery.paddingOf(context) : EdgeInsets.zero;
    final keyboardBottom = isBottomSheet && widget.theme.avoidKeyboardInset ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    final ambientScrollBehavior = ScrollConfiguration.of(context);

    final navigator = ScrollConfiguration(
      // Keep the ambient device policy for scrollables inside the sheet. The
      // outer ScrollConfiguration below is only for Smooth Sheets' drag layer.
      behavior: ambientScrollBehavior,
      child: Navigator(
        key: _navigatorKey,
        observers: [sheetNavigator._observer],
        onGenerateInitialRoutes: (navigator, initialRoute) => [
          _buildPageRoute<T>(widget.page),
        ],
      ),
    );

    final pagedSheet = PagedSheet(
      padding: EdgeInsets.fromLTRB(
        safePadding.left,
        0,
        safePadding.right,
        safePadding.bottom + keyboardBottom,
      ),
      decoration: isBottomSheet
          ? MaterialSheetDecoration(
              size: SheetSize.fit,
              elevation: widget.theme.bottomSheetElevation,
              color: widget.theme.surfaceColor,
              borderRadius: widget.theme.bottomSheetBorderRadius,
              clipBehavior: Clip.antiAlias,
            )
          : const MaterialSheetDecoration(
              size: SheetSize.stretch,
              type: MaterialType.transparency,
            ),
      navigator: navigator,
    );

    final routeTheme = PagedSheetRouteThemeData(
      scrollConfiguration: isBottomSheet
          ? const SheetScrollConfiguration(
              scrollSyncMode: SheetScrollHandlingBehavior.onlyFromTop,
            )
          : SheetScrollConfiguration.disabled,
      dragConfiguration: isBottomSheet && widget.theme.enableDrag
          ? const SheetDragConfiguration()
          : const SheetDragConfiguration(
              hitTestBehavior: HitTestBehavior.deferToChild,
              deviceKinds: {},
            ),
    );

    final routeThemeChild = PagedSheetRouteTheme(
      data: routeTheme,
      child: pagedSheet,
    );
    final sheetChild = ScrollConfiguration(
      // Flutter intentionally excludes mice from its default drag devices.
      // Opt in only for Smooth Sheets' outer drag layer when requested; the
      // route theme still disables dragging in a dialog presentation.
      behavior: widget.theme.enableMouseDrag
          ? ambientScrollBehavior.copyWith(
              dragDevices: {
                ...ambientScrollBehavior.dragDevices,
                PointerDeviceKind.mouse,
              },
            )
          : ambientScrollBehavior,
      child: routeThemeChild,
    );

    return AdaptiveSheetScope(
      presentation: presentation,
      theme: widget.theme,
      child: _AdaptiveSheetNavigatorScope(
        sheetNavigator: sheetNavigator,
        child: ListenableBuilder(
          listenable: sheetNavigator._changes,
          child: sheetChild,
          builder: (context, child) {
            final handlesNativeBack =
                !kIsWeb && widget.theme.nativeBackBehavior == AdaptiveSheetNativeBackBehavior.popPageOrCloseSheet && sheetNavigator._canPopAnyRoute;
            sheetNavigator._isHandlingNativeBack = handlesNativeBack;

            return PopScope<dynamic>(
              canPop: !handlesNativeBack,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && handlesNativeBack) {
                  sheetNavigator._popTopRoute();
                }
              },
              child: SheetPopScope<dynamic>(
                canPop: sheetNavigator._canClose,
                onPopInvokedWithResult: sheetNavigator._outerPopCallback,
                child: child!,
              ),
            );
          },
        ),
      ),
    );
  }
}

PagedSheetRoute<T> _buildPageRoute<T>(AdaptiveSheetPage<T> page) {
  late final _AdaptivePagedSheetRoute<T> route;
  route = _AdaptivePagedSheetRoute<T>(
    settings: page.settings,
    maintainState: page.maintainState,
    bottomSheetPageTransition: page.bottomSheetPageTransition,
    dialogPageTransition: page.dialogPageTransition,
    builder: (context) => _AdaptiveSheetPageRouteScope(
      key: route._contentKey,
      route: route,
      child: _AdaptiveSheetPageSurface(child: page.child),
    ),
  );
  return route;
}

/// Identifies routes created from [AdaptiveSheetPage] among temporary popup
/// routes pushed onto the same nested Navigator.
class _AdaptivePagedSheetRoute<T> extends PagedSheetRoute<T> {
  _AdaptivePagedSheetRoute({
    required super.builder,
    required this.bottomSheetPageTransition,
    required this.dialogPageTransition,
    super.settings,
    super.maintainState,
  });

  final AdaptiveSheetPageTransition? bottomSheetPageTransition;
  final AdaptiveSheetPageTransition? dialogPageTransition;

  // Smooth Sheets inserts a scroll wrapper when a dialog route becomes a
  // bottom sheet. Keep the key on the route so the page survives that move.
  final GlobalKey _contentKey = GlobalKey(
    debugLabel: 'adaptive-sheet-route-content',
  );

  AdaptiveSheetPageTransition _resolveTransition(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AdaptiveSheetScope>();
    if (scope == null) {
      throw StateError('Adaptive sheet page route is outside AdaptiveSheetScope.');
    }

    return switch (scope.presentation) {
      AdaptiveSheetPresentation.bottomSheet => bottomSheetPageTransition ?? scope.theme.bottomSheetPageTransition,
      AdaptiveSheetPresentation.dialog => dialogPageTransition ?? scope.theme.dialogPageTransition,
    };
  }

  @override
  Duration get transitionDuration {
    final routeNavigator = navigator;
    if (routeNavigator == null) {
      return const Duration(milliseconds: 300);
    }
    final duration = _resolveTransition(routeNavigator.context).duration;
    // Smooth Sheets uses the route animation to finish its page-size
    // transition activity. A truly zero-duration controller can complete
    // before that listener is attached, leaving the sheet non-interactive.
    // One microsecond is still visually immediate but guarantees one tick.
    return duration == Duration.zero ? const Duration(microseconds: 1) : duration;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transition = _resolveTransition(context);
    final builder = transition.builder;
    if (builder == null) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    return builder(context, animation, secondaryAnimation, child);
  }
}

class _AdaptiveSheetPageRouteScope extends InheritedWidget {
  const _AdaptiveSheetPageRouteScope({
    super.key,
    required this.route,
    required super.child,
  });

  final Route<dynamic> route;

  static Route<dynamic>? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AdaptiveSheetPageRouteScope>()?.route;
  }

  @override
  bool updateShouldNotify(_AdaptiveSheetPageRouteScope oldWidget) {
    return route != oldWidget.route;
  }
}

class _AdaptiveSheetPageSurface extends StatefulWidget {
  const _AdaptiveSheetPageSurface({required this.child});

  final Widget child;

  @override
  State<_AdaptiveSheetPageSurface> createState() => _AdaptiveSheetPageSurfaceState();
}

class _AdaptiveSheetPageSurfaceState extends State<_AdaptiveSheetPageSurface> {
  final GlobalKey _contentKey = GlobalKey(
    debugLabel: 'adaptive-sheet-page-content',
  );

  @override
  Widget build(BuildContext context) {
    final scope = AdaptiveSheetScope.of(context);
    final content = SizedBox(
      width: double.infinity,
      child: KeyedSubtree(
        key: _contentKey,
        child: _AdaptiveSheetDismissShortcuts(child: widget.child),
      ),
    );

    if (scope.presentation == AdaptiveSheetPresentation.bottomSheet) {
      return content;
    }

    return _AdaptiveDialogSurface(theme: scope.theme, child: content);
  }
}

class _AdaptiveSheetDismissShortcuts extends StatelessWidget {
  const _AdaptiveSheetDismissShortcuts({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              AdaptiveSheetNavigator.of(context).close();
              return null;
            },
          ),
        },
        // Give the page an active focus scope for Escape without winning the
        // autofocus race against a descendant form field.
        child: FocusScope(autofocus: true, child: child),
      ),
    );
  }
}

class _AdaptiveDialogSurface extends StatelessWidget {
  const _AdaptiveDialogSurface({required this.theme, required this.child});

  final AdaptiveSheetThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewPadding = theme.useSafeArea ? MediaQuery.viewPaddingOf(context) : EdgeInsets.zero;
    final keyboardBottom = theme.avoidKeyboardInset ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    final margin = EdgeInsets.fromLTRB(
      math.max(theme.dialogMargin.left, viewPadding.left),
      math.max(theme.dialogMargin.top, viewPadding.top),
      math.max(theme.dialogMargin.right, viewPadding.right),
      math.max(
        math.max(theme.dialogMargin.bottom, viewPadding.bottom),
        keyboardBottom == 0 ? 0 : keyboardBottom + theme.dialogMargin.bottom,
      ),
    );

    final outsideSurface = theme.barrierDismissible
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: AdaptiveSheetNavigator.of(context).close,
          )
        : const AbsorbPointer();

    return Stack(
      children: [
        Positioned.fill(child: outsideSurface),
        Padding(
          padding: margin,
          child: Center(
            child: SizedBox(
              width: theme.dialogWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: theme.dialogMaxHeight),
                child: Material(
                  elevation: theme.dialogElevation,
                  color: theme.surfaceColor ?? Theme.of(context).colorScheme.surface,
                  borderRadius: theme.dialogBorderRadius,
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
