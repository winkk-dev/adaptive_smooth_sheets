part of 'adaptive_sheet_route.dart';

/// Controls whether the current adaptive sheet can be dismissed.
///
/// Unlike Flutter's [PopScope], this scope targets the outer adaptive modal
/// even when its child is hosted by an internal page route. Supplying a
/// callback while [canPop] is false keeps the sheet gesture enabled and reports
/// blocked dismissal attempts. Omitting the callback disables the gesture.
class AdaptiveSheetPopScope<T> extends StatefulWidget {
  /// Creates a scope that coordinates modal pops and sheet swipe gestures.
  const AdaptiveSheetPopScope({
    required this.child,
    super.key,
    this.canPop = true,
    this.onPopInvokedWithResult,
  });

  /// Whether the enclosing adaptive modal may be closed.
  final bool canPop;

  /// Called after an outer-modal pop is handled or blocked.
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;

  /// The widget below this scope.
  final Widget child;

  @override
  State<AdaptiveSheetPopScope<T>> createState() => _AdaptiveSheetPopScopeState<T>();
}

class _AdaptiveSheetPopScopeState<T> extends State<AdaptiveSheetPopScope<T>> {
  AdaptiveSheetNavigator? _sheetNavigator;
  _AdaptiveSheetPopRegistration? _registration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sheetNavigator = AdaptiveSheetNavigator.maybeOf(context);
    final pageRoute = _AdaptiveSheetPageRouteScope.maybeOf(context);
    assert(
      sheetNavigator != null && pageRoute != null,
      'AdaptiveSheetPopScope must be used below an AdaptiveSheetPage.',
    );

    if (sheetNavigator == _sheetNavigator && pageRoute == _registration?.route) {
      return;
    }

    _unregister();
    _sheetNavigator = sheetNavigator;
    _registration = _AdaptiveSheetPopRegistration(
      route: pageRoute!,
      canPop: widget.canPop,
      onPopInvokedWithResult: _effectiveCallback,
    );
    sheetNavigator!._registerPopScope(_registration!);
  }

  @override
  void didUpdateWidget(AdaptiveSheetPopScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final registration = _registration;
    if (registration != null) {
      registration
        ..canPop = widget.canPop
        ..onPopInvokedWithResult = _effectiveCallback;
      _sheetNavigator!._popScopeChanged();
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  void _unregister() {
    final registration = _registration;
    if (registration != null) {
      _sheetNavigator?._unregisterPopScope(registration);
    }
    _registration = null;
    _sheetNavigator = null;
  }

  void _invokeCallback(bool didPop, Object? result) {
    widget.onPopInvokedWithResult?.call(didPop, result as T?);
  }

  PopInvokedWithResultCallback<dynamic>? get _effectiveCallback {
    return widget.onPopInvokedWithResult == null ? null : _invokeCallback;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
