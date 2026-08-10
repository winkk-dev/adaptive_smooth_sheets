import 'package:flutter/material.dart';

import 'base_modal_theme.dart';

/// An explicit content and scrolling strategy for project modals.
///
/// Managed strategies create exactly one vertical scroll view, apply project
/// padding, dismiss the keyboard on drag by default, and participate in Smooth
/// Sheets' scroll-to-drag handoff. [BaseModalBody.custom] is the escape hatch
/// for layouts such as a [TabBarView] that own their internal scrolling.
sealed class BaseModalBody extends StatelessWidget {
  const BaseModalBody({super.key});

  /// Creates eager content that scrolls only when its height is constrained.
  const factory BaseModalBody.singleChild({
    required Widget child,
    Key? key,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior,
  }) = _SingleChildBaseModalBody;

  /// Creates a lazy list with optional separators.
  const factory BaseModalBody.list({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    Key? key,
    IndexedWidgetBuilder? separatorBuilder,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior,
  }) = _ListBaseModalBody;

  /// Creates a lazy custom scroll view from slivers.
  const factory BaseModalBody.slivers({
    required List<Widget> slivers,
    Key? key,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior,
  }) = _SliversBaseModalBody;

  /// Uses [child] without adding padding or another scroll view.
  ///
  /// Descendant vertical scroll views that do not provide their own controller
  /// still inherit the modal's coordinated primary scroll controller.
  const factory BaseModalBody.custom({
    required Widget child,
    Key? key,
  }) = _CustomBaseModalBody;
}

final class _SingleChildBaseModalBody extends BaseModalBody {
  const _SingleChildBaseModalBody({
    super.key,
    required this.child,
    this.padding,
    this.physics,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? BaseModalThemeData.of(context).bodyPadding,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      child: child,
    );
  }
}

final class _ListBaseModalBody extends BaseModalBody {
  const _ListBaseModalBody({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding,
    this.physics,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  }) : assert(itemCount >= 0);

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? BaseModalThemeData.of(context).bodyPadding;
    final separatorBuilder = this.separatorBuilder;
    if (separatorBuilder != null) {
      return ListView.separated(
        padding: effectivePadding,
        physics: physics,
        keyboardDismissBehavior: keyboardDismissBehavior,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder,
      );
    }

    return ListView.builder(
      padding: effectivePadding,
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

final class _SliversBaseModalBody extends BaseModalBody {
  const _SliversBaseModalBody({
    super.key,
    required this.slivers,
    this.padding,
    this.physics,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  });

  final List<Widget> slivers;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: physics,
      keyboardDismissBehavior: keyboardDismissBehavior,
      slivers: [
        SliverPadding(
          padding: padding ?? BaseModalThemeData.of(context).bodyPadding,
          // Group all slivers under one shared outer padding.
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
  }
}

final class _CustomBaseModalBody extends BaseModalBody {
  const _CustomBaseModalBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
