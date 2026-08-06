import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

import 'base_modal_theme.dart';

/// Key used by tests and examples to identify the mobile drag handle.
const baseModalDragHandleKey = Key('base-modal-drag-handle');

/// Project-level modal composition built on the package primitives.
///
/// This widget owns application chrome only. Presentation, routing, surface
/// geometry, gestures, safe areas, and keyboard insets remain package concerns.
class BaseModal extends StatelessWidget {
  /// Creates a project-styled modal surface.
  const BaseModal({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.leading,
    this.headerActions = const [],
    this.headerBottom,
    this.footer,
    this.showCloseButton = true,
    this.showDragHandle = true,
  });

  /// The modal title.
  final String title;

  /// Optional supporting text below [title].
  final String? subtitle;

  /// The body widget, whose scrolling strategy is chosen by the caller.
  final Widget body;

  /// An optional widget before the title.
  final Widget? leading;

  /// Widgets placed before the close action.
  final List<Widget> headerActions;

  /// Optional content below the header row, such as a [TabBar].
  final PreferredSizeWidget? headerBottom;

  /// An optional fixed footer.
  final Widget? footer;

  /// Whether to include a close action in the header.
  final bool showCloseButton;

  /// Whether bottom-sheet presentation includes a drag handle.
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSheetScaffold(
      topBar: BaseModalHeader(
        title: title,
        subtitle: subtitle,
        leading: leading,
        actions: headerActions,
        bottom: headerBottom,
        showCloseButton: showCloseButton,
        showDragHandle: showDragHandle,
      ),
      bottomBar: footer,
      body: body,
    );
  }
}

/// An explicitly padded or eager-scrollable modal body.
class BaseModalBody extends StatelessWidget {
  /// Creates a non-scrolling padded body.
  const BaseModalBody({required this.child, super.key, this.padding})
    : scrollable = false;

  /// Creates a padded body inside a [SingleChildScrollView].
  const BaseModalBody.scrollable({required this.child, super.key, this.padding})
    : scrollable = true;

  /// The body content.
  final Widget child;

  /// Optional padding overriding [BaseModalThemeData.bodyPadding].
  final EdgeInsets? padding;

  /// Whether to eagerly scroll [child].
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: padding ?? BaseModalThemeData.of(context).bodyPadding,
      child: child,
    );
    return scrollable ? SingleChildScrollView(child: padded) : padded;
  }
}

/// Standard project header with responsive drag-handle rendering.
class BaseModalHeader extends StatelessWidget {
  /// Creates a modal header.
  const BaseModalHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.showCloseButton = true,
    this.showDragHandle = true,
  });

  /// The primary header label.
  final String title;

  /// Optional supporting header text.
  final String? subtitle;

  /// Optional leading widget.
  final Widget? leading;

  /// Header action widgets.
  final List<Widget> actions;

  /// Optional content below the title row.
  final PreferredSizeWidget? bottom;

  /// Whether to include the default close action.
  final bool showCloseButton;

  /// Whether to render a handle in bottom-sheet presentation.
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final modalTheme = BaseModalThemeData.of(context);
    final isBottomSheet =
        AdaptiveSheetScope.of(context).presentation ==
        AdaptiveSheetPresentation.bottomSheet;

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
                if (leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      color: modalTheme.headerForegroundColor,
                    ),
                    child: leading!,
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: modalTheme.headerForegroundColor
                                    .withValues(alpha: 0.72),
                              ),
                        ),
                    ],
                  ),
                ),
                ...actions,
                if (showCloseButton)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
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
    required this.actions,
    super.key,
    this.stackOnBottomSheet = false,
  });

  /// Action widgets in visual order.
  final List<Widget> actions;

  /// Whether bottom-sheet actions use a vertical layout.
  final bool stackOnBottomSheet;

  @override
  Widget build(BuildContext context) {
    final modalTheme = BaseModalThemeData.of(context);
    final isBottomSheet =
        AdaptiveSheetScope.of(context).presentation ==
        AdaptiveSheetPresentation.bottomSheet;

    final Widget content;
    if (isBottomSheet && stackOnBottomSheet) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: _withVerticalGaps(actions),
      );
    } else {
      final rowActions = isBottomSheet
          ? actions.map((action) => Expanded(child: action)).toList()
          : actions;
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
