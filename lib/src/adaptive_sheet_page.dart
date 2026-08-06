import 'package:flutter/widgets.dart';

/// Describes one page in an adaptive sheet's internal navigation stack.
///
/// The package converts this Flutter-only description into its private Smooth
/// Sheets route implementation. Consumers should push pages through
/// `AdaptiveSheetNavigator` rather than constructing routes themselves.
@immutable
class AdaptiveSheetPage<T> {
  /// Creates a page containing [child].
  const AdaptiveSheetPage({
    required this.child,
    this.settings,
    this.maintainState = true,
  });

  /// The content displayed for this page.
  final Widget child;

  /// Optional route metadata for this page.
  final RouteSettings? settings;

  /// Whether this page remains mounted while another page covers it.
  final bool maintainState;
}
