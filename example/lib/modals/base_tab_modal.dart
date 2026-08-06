import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'base_modal.dart';

/// A small project-level tab composition for adaptive modal content.
///
/// This is intentionally concrete rather than an abstract form/tab framework;
/// that API will be revisited during the dedicated simplification task.
class BaseTabModal extends StatelessWidget {
  /// Creates a tabbed modal.
  const BaseTabModal({
    required this.title,
    required this.tabs,
    required this.children,
    super.key,
    this.subtitle,
    this.footer,
  }) : assert(tabs.length == children.length),
       assert(tabs.length > 0);

  /// The modal title.
  final String title;

  /// Optional supporting header text.
  final String? subtitle;

  /// Tab labels.
  final List<Tab> tabs;

  /// Tab bodies corresponding to [tabs].
  final List<Widget> children;

  /// Optional fixed footer shared by all tabs.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewPaddingOf(context).vertical;
    final bodyHeight = math.max(220.0, math.min(480.0, availableHeight * 0.56));

    return DefaultTabController(
      length: tabs.length,
      child: BaseModal(
        title: title,
        subtitle: subtitle,
        headerBottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tabs: tabs,
        ),
        body: SizedBox(
          height: bodyHeight,
          child: TabBarView(children: children),
        ),
        footer: footer,
      ),
    );
  }
}
