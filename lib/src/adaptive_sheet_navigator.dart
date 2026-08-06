part of 'adaptive_sheet_route.dart';

/// Navigates between pages inside an adaptive sheet or closes the whole modal.
///
/// Obtain the navigator from a context below an [AdaptiveSheetPage]. Internal
/// page navigation is deliberately separate from closing the outer modal:
/// [pop] only removes an internal page, while [close] dismisses the sheet.
class AdaptiveSheetNavigator {
  AdaptiveSheetNavigator._({
    required this._navigatorKey,
    required this._forceCloseSheet,
  }) {
    _observer = _AdaptiveSheetNavigatorObserver(_handleStackChanged);
  }

  final GlobalKey<NavigatorState> _navigatorKey;
  final _CloseAdaptiveSheet _forceCloseSheet;
  final ValueNotifier<int> _changes = ValueNotifier(0);
  final Set<_AdaptiveSheetPopRegistration> _popRegistrations = {};
  late final _AdaptiveSheetNavigatorObserver _observer;
  bool _notificationScheduled = false;
  bool _disposed = false;
  bool _isHandlingNativeBack = false;

  /// Returns the closest adaptive sheet navigator and registers for updates.
  static AdaptiveSheetNavigator of(BuildContext context) {
    final navigator = maybeOf(context);
    assert(
      navigator != null,
      'No AdaptiveSheetNavigator found in context. Use a context below an AdaptiveSheetPage.',
    );
    return navigator!;
  }

  /// Returns the closest adaptive sheet navigator, or null outside a sheet.
  static AdaptiveSheetNavigator? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AdaptiveSheetNavigatorScope>()?.sheetNavigator;
  }

  /// Whether an internal page can currently be popped.
  ///
  /// Temporary popup routes, such as dropdown menus and date pickers, do not
  /// count as adaptive sheet pages.
  ///
  /// A widget that obtains this navigator through [of] or [maybeOf] rebuilds
  /// when this value changes.
  bool get canPop => _observer.canPopPage;

  /// Pushes [page] onto this sheet's internal navigation stack.
  Future<T?> push<T>(AdaptiveSheetPage<T> page) {
    return _navigatorKey.currentState!.push<T>(_buildPageRoute(page));
  }

  /// Pops the current internal page without closing the adaptive sheet.
  ///
  /// Returns false and does nothing when the first page is current.
  bool pop<T>([T? result]) {
    if (!canPop) {
      return false;
    }

    _navigatorKey.currentState!.pop<T>(result);
    return true;
  }

  /// Closes the complete adaptive sheet with an optional [result].
  ///
  /// An enclosing [AdaptiveSheetPopScope] may guard the dismissal.
  void close<T>([T? result]) {
    if (_canClose) {
      _forceCloseSheet<T>(result);
    } else {
      _notifyPopInvoked(false, result);
    }
  }

  Route<dynamic>? get _currentPageRoute => _observer.currentPageRoute;

  bool get _canPopAnyRoute => _observer.canPopAnyRoute;

  void _popTopRoute() {
    unawaited(_navigatorKey.currentState!.maybePop());
  }

  Iterable<_AdaptiveSheetPopRegistration> get _currentPopRegistrations {
    final currentRoute = _currentPageRoute;
    return _popRegistrations.where(
      (registration) => registration.route == currentRoute,
    );
  }

  bool get _canClose => _currentPopRegistrations.every(
    (registration) => registration.canPop,
  );

  bool get _isDismissGestureEnabled => _currentPopRegistrations.every(
    (registration) => registration.canPop || registration.onPopInvokedWithResult != null,
  );

  bool get _hasPopCallbacks => _currentPopRegistrations.any(
    (registration) => registration.onPopInvokedWithResult != null,
  );

  PopInvokedWithResultCallback<dynamic>? get _outerPopCallback {
    if (!_isDismissGestureEnabled || !_hasPopCallbacks) {
      return null;
    }
    return _handleOuterPopInvoked;
  }

  void _handleOuterPopInvoked(bool didPop, Object? result) {
    // The native-back PopScope reports the blocked outer attempt too. That
    // attempt belongs to internal navigation, not to an outer dismissal guard.
    if (!didPop && _isHandlingNativeBack) {
      return;
    }
    _notifyPopInvoked(didPop, result);
  }

  void _notifyPopInvoked(bool didPop, Object? result) {
    for (final registration in _currentPopRegistrations.toList()) {
      registration.onPopInvokedWithResult?.call(didPop, result);
    }
  }

  void _registerPopScope(_AdaptiveSheetPopRegistration registration) {
    _popRegistrations.add(registration);
    _scheduleNotification();
  }

  void _unregisterPopScope(_AdaptiveSheetPopRegistration registration) {
    _popRegistrations.remove(registration);
    _scheduleNotification();
  }

  void _popScopeChanged() {
    _scheduleNotification();
  }

  void _handleStackChanged() {
    _scheduleNotification();
  }

  // Navigator observers can fire while their Navigator is building. Defer the
  // inherited notification while updating stack state synchronously so newly
  // built pages still read the correct value from [canPop].
  void _scheduleNotification() {
    if (_disposed || _notificationScheduled) {
      return;
    }
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) {
        return;
      }
      _notificationScheduled = false;
      _changes.value += 1;
    });
  }

  void _dispose() {
    _disposed = true;
    _isHandlingNativeBack = false;
    _changes.dispose();
  }
}

typedef _CloseAdaptiveSheet = void Function<T>(T? result);

class _AdaptiveSheetNavigatorScope extends InheritedNotifier<ValueNotifier<int>> {
  _AdaptiveSheetNavigatorScope({
    required this.sheetNavigator,
    required super.child,
  }) : super(notifier: sheetNavigator._changes);

  final AdaptiveSheetNavigator sheetNavigator;
}

class _AdaptiveSheetNavigatorObserver extends NavigatorObserver {
  _AdaptiveSheetNavigatorObserver(this._onChanged);

  final VoidCallback _onChanged;
  final List<Route<dynamic>> _routes = [];

  Iterable<_AdaptivePagedSheetRoute<dynamic>> get _pageRoutes {
    return _routes.whereType<_AdaptivePagedSheetRoute<dynamic>>();
  }

  bool get canPopPage => _pageRoutes.length > 1;

  bool get canPopAnyRoute => _routes.length > 1;

  Route<dynamic>? get currentPageRoute => _pageRoutes.lastOrNull;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) {
      _routes[index] = newRoute;
    }
    _onChanged();
  }
}

class _AdaptiveSheetPopRegistration {
  _AdaptiveSheetPopRegistration({
    required this.route,
    required this.canPop,
    required this.onPopInvokedWithResult,
  });

  Route<dynamic> route;
  bool canPop;
  PopInvokedWithResultCallback<dynamic>? onPopInvokedWithResult;
}
