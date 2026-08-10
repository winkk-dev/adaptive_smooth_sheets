import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'base_modal_body.dart';
import 'base_modal_theme.dart';

export 'base_modal_body.dart';
export 'base_modal_theme.dart';

/// Key used by tests and examples to identify the mobile drag handle.
const baseModalDragHandleKey = Key('base-modal-drag-handle');

/// Project-level modal composition built on the package primitives.
///
/// This widget owns application chrome only. Presentation, routing, surface
/// geometry, gestures, safe areas, and keyboard insets remain package concerns.
class BaseModal extends StatelessWidget {
  /// Creates a project-styled modal surface.
  const BaseModal({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.headerActions = const [],
    this.headerBottom,
    this.footer,
    this.showCloseButton = true,
    this.onClosePressed,
    this.showDragHandle = true,
  });

  /// The modal title.
  final String title;

  /// Optional supporting text below [title].
  final String? subtitle;

  /// The body widget, whose scrolling strategy is chosen by the caller.
  final BaseModalBody body;

  /// An optional widget before the title.
  ///
  /// This replaces the automatic internal-page back button when non-null.
  final Widget? leading;

  /// Whether to show an automatic back button on pushed pages.
  final bool showBackButton;

  /// Overrides the automatic internal-page back action.
  final VoidCallback? onBackPressed;

  /// Widgets placed before the close action.
  final List<Widget> headerActions;

  /// Optional content below the header row, such as a [TabBar].
  final PreferredSizeWidget? headerBottom;

  /// An optional fixed footer.
  final Widget? footer;

  /// Whether to include a close action in the header.
  final bool showCloseButton;

  /// Overrides the action that closes the complete adaptive sheet.
  final VoidCallback? onClosePressed;

  /// Whether bottom-sheet presentation includes a drag handle.
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return _BaseModalLayout(
      header: BaseModalHeader(
        title: title,
        subtitle: subtitle,
        leading: leading,
        showBackButton: showBackButton,
        onBackPressed: onBackPressed,
        actions: headerActions,
        bottom: headerBottom,
        showCloseButton: showCloseButton,
        onClosePressed: onClosePressed,
        showDragHandle: showDragHandle,
      ),
      footer: footer,
      body: body,
    );
  }
}

/// Internal stateful shell for scrolling and the footer overflow fade.
class _BaseModalLayout extends StatefulWidget {
  const _BaseModalLayout({
    required this.header,
    required this.body,
    this.footer,
  });

  final Widget header;
  final BaseModalBody body;
  final Widget? footer;

  @override
  State<_BaseModalLayout> createState() => _BaseModalLayoutState();
}

class _BaseModalLayoutState extends State<_BaseModalLayout> {
  // Whether vertical content remains below the visible body.
  var _canScrollForward = false;

  bool _handleScrollMetrics(ScrollMetrics metrics) {
    if (axisDirectionToAxis(metrics.axisDirection) != Axis.vertical) {
      return false;
    }

    final canScrollForward = metrics.extentAfter > 0.5;
    if (canScrollForward != _canScrollForward) {
      setState(() => _canScrollForward = canScrollForward);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final modalTheme = BaseModalThemeData.of(context);
    final footer = widget.footer;

    return AdaptiveSheetScaffold(
      topBar: widget.header,
      bottomBar: footer == null
          ? null
          : _BaseModalOverflowFooter(
              showGradient: _canScrollForward,
              theme: modalTheme,
              child: footer,
            ),
      body: NotificationListener<ScrollMetricsNotification>(
        // Metrics catch layout changes; scroll notifications catch movement.
        onNotification: (notification) => _handleScrollMetrics(notification.metrics),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) => _handleScrollMetrics(notification.metrics),
          child: widget.body,
        ),
      ),
    );
  }
}

/// Full-width footer wrapper that paints the overflow fade above the footer.
class _BaseModalOverflowFooter extends StatelessWidget {
  const _BaseModalOverflowFooter({
    required this.showGradient,
    required this.theme,
    required this.child,
  });

  final bool showGradient;
  final BaseModalThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Passthrough preserves the footer's natural full-width layout.
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          top: -theme.footerOverflowGradientHeight,
          left: 0,
          right: 0,
          height: theme.footerOverflowGradientHeight,
          child: IgnorePointer(
            // Visual fade only; never intercept body interaction.
            child: AnimatedOpacity(
              opacity: showGradient ? 1 : 0,
              duration: theme.footerOverflowGradientDuration,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      theme.footerBackgroundColor,
                      theme.footerBackgroundColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard project header with responsive drag-handle rendering.
class BaseModalHeader extends StatelessWidget {
  /// Creates a modal header.
  const BaseModalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions = const [],
    this.bottom,
    this.showCloseButton = true,
    this.onClosePressed,
    this.showDragHandle = true,
  });

  /// The primary header label.
  final String title;

  /// Optional supporting header text.
  final String? subtitle;

  /// Optional leading widget.
  final Widget? leading;

  /// Whether to show an automatic back button on pushed pages.
  final bool showBackButton;

  /// Overrides the automatic internal-page back action.
  final VoidCallback? onBackPressed;

  /// Header action widgets.
  final List<Widget> actions;

  /// Optional content below the title row.
  final PreferredSizeWidget? bottom;

  /// Whether to include the default close action.
  final bool showCloseButton;

  /// Overrides the action that closes the complete adaptive sheet.
  final VoidCallback? onClosePressed;

  /// Whether to render a handle in bottom-sheet presentation.
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final modalTheme = BaseModalThemeData.of(context);
    final isBottomSheet = AdaptiveSheetScope.of(context).presentation == AdaptiveSheetPresentation.bottomSheet;
    final sheetNavigator = AdaptiveSheetNavigator.of(context);
    final effectiveLeading =
        leading ??
        (showBackButton && sheetNavigator.canPop
            ? IconButton(
                onPressed: onBackPressed ?? sheetNavigator.pop,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
              )
            : null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: modalTheme.headerBackgroundColor,
        border: Border(bottom: modalTheme.headerDivider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBottomSheet && showDragHandle)
            Padding(
              padding: modalTheme.dragHandlePadding,
              child: SizedBox.fromSize(
                key: baseModalDragHandleKey,
                size: modalTheme.dragHandleSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: modalTheme.dragHandleColor,
                    borderRadius: BorderRadius.circular(
                      modalTheme.dragHandleSize.height,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: modalTheme.headerPadding,
            child: Row(
              children: [
                if (effectiveLeading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      color: modalTheme.headerForegroundColor,
                    ),
                    child: effectiveLeading,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: modalTheme.headerForegroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: modalTheme.headerForegroundColor.withValues(alpha: 0.72),
                          ),
                        ),
                    ],
                  ),
                ),
                ...actions,
                if (showCloseButton)
                  IconButton(
                    onPressed: onClosePressed ?? sheetNavigator.close,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                    color: modalTheme.headerForegroundColor,
                  ),
              ],
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}

/// Project action footer that responds to the current presentation.
class BaseModalFooter extends StatelessWidget {
  /// Creates a modal action footer.
  const BaseModalFooter({
    super.key,
    required this.actions,
    this.stackOnBottomSheet = false,
  });

  /// Action widgets in visual order.
  final List<Widget> actions;

  /// Whether bottom-sheet actions use a vertical layout.
  final bool stackOnBottomSheet;

  @override
  Widget build(BuildContext context) {
    final modalTheme = BaseModalThemeData.of(context);
    final isBottomSheet = AdaptiveSheetScope.of(context).presentation == AdaptiveSheetPresentation.bottomSheet;

    final Widget content;
    if (isBottomSheet && stackOnBottomSheet) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: _withVerticalGaps(actions),
      );
    } else {
      // Mobile actions share width; dialog actions keep their natural size.
      final rowActions = isBottomSheet ? actions.map((action) => Expanded(child: action)).toList() : actions;
      content = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: isBottomSheet ? MainAxisSize.max : MainAxisSize.min,
        children: _withHorizontalGaps(rowActions),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: modalTheme.footerBackgroundColor,
        border: Border(top: modalTheme.footerDivider),
      ),
      child: Padding(padding: modalTheme.footerPadding, child: content),
    );
  }
}

List<Widget> _withHorizontalGaps(List<Widget> children) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(width: 12),
      children[index],
    ],
  ];
}

List<Widget> _withVerticalGaps(List<Widget> children) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(height: 12),
      children[index],
    ],
  ];
}
