/// Controls how a native platform Back request affects an adaptive sheet.
///
/// This policy applies only on non-web platforms, primarily to Android device
/// Back. Browser history is deliberately outside the package's control.
/// Escape, barrier taps, swipe dismissal, and `AdaptiveSheetNavigator.close()`
/// remain explicit requests to close the complete modal.
enum AdaptiveSheetNativeBackBehavior {
  /// Closes the complete adaptive sheet from any internal page depth.
  closeSheet,

  /// Pops an internal page when possible, otherwise closes the sheet.
  popPageOrCloseSheet,
}
