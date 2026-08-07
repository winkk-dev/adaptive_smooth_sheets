import 'package:flutter/widgets.dart';

/// Builds the visual transition for one page in an adaptive sheet.
///
/// The animations follow Flutter's [RouteTransitionsBuilder] contract:
/// [animation] drives this page and [secondaryAnimation] drives the route
/// pushed above it.
typedef AdaptiveSheetPageTransitionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    );

/// Describes an internal adaptive-sheet page transition without exposing
/// Smooth Sheets route types.
///
/// Configure separate values for bottom-sheet and dialog presentations on
/// `AdaptiveSheetThemeData`, `AdaptiveSheetConfig`, or `AdaptiveSheetPage`.
@immutable
class AdaptiveSheetPageTransition {
  /// Uses Smooth Sheets' platform-default page transition.
  const AdaptiveSheetPageTransition.platformDefault({
    this.duration = const Duration(milliseconds: 300),
  }) : _builder = null;

  /// Fades the outgoing page fully before fading in the incoming page.
  ///
  /// This transition has no horizontal movement and never displays both page
  /// contents at a non-zero opacity at the same point in the animation.
  const AdaptiveSheetPageTransition.fadeThrough({
    this.duration = const Duration(milliseconds: 500),
  }) : _builder = _buildFadeThroughTransition;

  /// Uses subtle directional motion to communicate forward and back navigation.
  ///
  /// The complete page moves a small fixed distance within the route while the
  /// outgoing and incoming fades remain non-overlapping. Using logical pixels
  /// keeps the motion restrained on wide dialog layouts.
  const AdaptiveSheetPageTransition.sharedAxis({
    this.duration = const Duration(milliseconds: 400),
  }) : _builder = _buildSharedAxisTransition;

  /// Changes pages immediately without a visual transition.
  const AdaptiveSheetPageTransition.none() : duration = Duration.zero, _builder = _buildNoTransition;

  /// Uses [builder] for both forward and reverse navigation.
  const AdaptiveSheetPageTransition.custom({
    required Duration duration,
    required AdaptiveSheetPageTransitionBuilder builder,
  }) : this._(duration, builder);

  const AdaptiveSheetPageTransition._(this.duration, this._builder);

  /// How long the forward and reverse page animations run.
  final Duration duration;

  /// The Flutter-only transition builder, or null to delegate to Smooth
  /// Sheets' platform-default transition.
  AdaptiveSheetPageTransitionBuilder? get builder => _builder;

  final AdaptiveSheetPageTransitionBuilder? _builder;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is AdaptiveSheetPageTransition && duration == other.duration && builder == other.builder;
  }

  @override
  int get hashCode => Object.hash(duration, builder);
}

Widget _buildFadeThroughTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final incomingOpacity = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.4, 1, curve: Curves.easeOutCubic),
  );
  final outgoingOpacity = ReverseAnimation(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    ),
  );

  return FadeTransition(
    opacity: outgoingOpacity,
    child: FadeTransition(opacity: incomingOpacity, child: child),
  );
}

Widget _buildSharedAxisTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const distance = 16.0;
  const handoff = 0.5;
  final direction = Directionality.of(context) == TextDirection.ltr ? 1.0 : -1.0;
  final incomingOpacity = CurvedAnimation(
    parent: animation,
    curve: const Interval(handoff, 1, curve: Curves.easeOutCubic),
  );
  final outgoingOpacity = ReverseAnimation(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0, handoff, curve: Curves.easeOutCubic),
    ),
  );
  final incomingMotion = CurvedAnimation(
    parent: animation,
    curve: const Interval(handoff, 1, curve: Curves.easeOutCubic),
  );
  final outgoingMotion = CurvedAnimation(
    parent: secondaryAnimation,
    curve: const Interval(0, handoff, curve: Curves.easeInCubic),
  );

  return AnimatedBuilder(
    animation: Listenable.merge([animation, secondaryAnimation]),
    child: child,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(-distance * direction * outgoingMotion.value, 0),
        child: FadeTransition(
          opacity: outgoingOpacity,
          child: Transform.translate(
            offset: Offset(distance * direction * (1 - incomingMotion.value), 0),
            child: FadeTransition(
              opacity: incomingOpacity,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildNoTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return child;
}
