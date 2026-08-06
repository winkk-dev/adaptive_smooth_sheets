import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// Controls whether an adaptive sheet can be popped or swipe-dismissed.
///
/// Unlike Flutter's [PopScope], this scope can disable the sheet's swipe
/// gesture completely when [canPop] is false and
/// [onPopInvokedWithResult] is null. Supplying a callback keeps the gesture
/// enabled and reports unsuccessful pop attempts to the callback.
class AdaptiveSheetPopScope<T> extends StatelessWidget {
  /// Creates a scope that coordinates route pops and sheet swipe gestures.
  const AdaptiveSheetPopScope({
    required this.child,
    super.key,
    this.canPop = true,
    this.onPopInvokedWithResult,
  });

  /// Whether the enclosing adaptive sheet route may be popped.
  final bool canPop;

  /// Called after a pop is handled or blocked, including swipe attempts.
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;

  /// The widget below this scope.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SheetPopScope<T>(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: child,
    );
  }
}
