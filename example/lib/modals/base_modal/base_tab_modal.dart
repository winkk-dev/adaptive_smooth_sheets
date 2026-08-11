import 'dart:async';
import 'dart:math' as math;

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';

import 'base_modal.dart';

/// Builds the fixed footer for the currently selected tab and controller.
typedef BaseTabModalFooterBuilder =
    Widget? Function(
      BuildContext context,
      int tabIndex,
      TabController tabController,
    );

/// Project-level tab composition for adaptive modal content.
class BaseTabModal extends StatelessWidget {
  /// Creates naturally sized tabs for ordinary eager content.
  ///
  /// The modal follows the active tab's height and scrolls as one body when the
  /// content exceeds the available space.
  const BaseTabModal({
    super.key,
    required this.title,
    required this.tabs,
    required this.children,
    this.subtitle,
    this.footer,
    this.footerBuilder,
    this.animationDurationPerTab = kTabScrollDuration,
  }) : _fillsAvailableHeight = false,
       assert(tabs.length == children.length),
       assert(tabs.length > 0),
       assert(footer == null || footerBuilder == null);

  /// Creates full-height tabs whose children own their vertical scrolling.
  ///
  /// Use this for lazy lists, slivers, or other independently scrolling bodies.
  const BaseTabModal.fill({
    super.key,
    required this.title,
    required this.tabs,
    required this.children,
    this.subtitle,
    this.footer,
    this.footerBuilder,
    this.animationDurationPerTab = kTabScrollDuration,
  }) : _fillsAvailableHeight = true,
       assert(tabs.length == children.length),
       assert(tabs.length > 0),
       assert(footer == null || footerBuilder == null);

  /// The modal title.
  final String title;

  /// Optional supporting header text.
  final String? subtitle;

  /// Tab labels.
  final List<Tab> tabs;

  /// Tab bodies corresponding to [tabs].
  ///
  /// Use ordinary eager widgets with [BaseTabModal] and independently
  /// scrolling widgets such as [BaseModalBody.list] with [BaseTabModal.fill].
  final List<Widget> children;

  /// Optional fixed footer shared by every tab.
  final Widget? footer;

  /// Optional fixed footer selected by the active tab index.
  ///
  /// This replaces [footer] and may return null for tabs without a footer.
  final BaseTabModalFooterBuilder? footerBuilder;

  /// Animation time for crossing one tab.
  final Duration animationDurationPerTab;

  final bool _fillsAvailableHeight;

  @override
  Widget build(BuildContext context) {
    return _BaseTabModalContent(
      key: ValueKey(_fillsAvailableHeight),
      title: title,
      subtitle: subtitle,
      tabs: tabs,
      footer: footer,
      footerBuilder: footerBuilder,
      fillsAvailableHeight: _fillsAvailableHeight,
      animationDurationPerTab: animationDurationPerTab,
      children: children,
    );
  }
}

class _BaseTabModalContent extends StatefulWidget {
  const _BaseTabModalContent({
    super.key,
    required this.title,
    required this.tabs,
    required this.children,
    required this.fillsAvailableHeight,
    required this.animationDurationPerTab,
    this.subtitle,
    this.footer,
    this.footerBuilder,
  });

  final String title;
  final String? subtitle;
  final List<Tab> tabs;
  final List<Widget> children;
  final Widget? footer;
  final BaseTabModalFooterBuilder? footerBuilder;
  final bool fillsAvailableHeight;
  final Duration animationDurationPerTab;

  @override
  State<_BaseTabModalContent> createState() => _BaseTabModalContentState();
}

class _BaseTabModalContentState extends State<_BaseTabModalContent> with TickerProviderStateMixin {
  final _pageController = PageController();
  late _DistanceAwareTabController _tabController;
  var _selectedIndex = 0;
  int? _requestedPage;
  int? _deferredPage;

  @override
  void initState() {
    super.initState();
    _tabController = _createTabController();
  }

  _DistanceAwareTabController _createTabController({int initialIndex = 0}) {
    final controller = _DistanceAwareTabController(
      length: widget.tabs.length,
      initialIndex: initialIndex,
      durationPerTab: widget.animationDurationPerTab,
      vsync: this,
    );
    controller
      ..addListener(_handleTabControllerChanged)
      ..animation!.addListener(_handleTabAnimationTick);
    return controller;
  }

  @override
  void didUpdateWidget(_BaseTabModalContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length == widget.tabs.length && oldWidget.animationDurationPerTab == widget.animationDurationPerTab) {
      return;
    }

    final initialIndex = math.min(_tabController.index, widget.tabs.length - 1);
    _tabController.animation!.removeListener(_handleTabAnimationTick);
    _tabController
      ..removeListener(_handleTabControllerChanged)
      ..dispose();
    _tabController = _createTabController(initialIndex: initialIndex);
    _selectedIndex = initialIndex;
    _requestedPage = null;
    _deferredPage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(initialIndex);
      }
    });
  }

  void _handleTabControllerChanged() {
    final tabController = _tabController;
    final index = tabController.index;
    if (_selectedIndex == index) {
      return;
    }

    setState(() => _selectedIndex = index);
    if (_requestedPage != index && _pageController.hasClients) {
      _requestedPage = index;
      final duration = tabController.currentAnimationDuration;
      final distance = (index - tabController.previousIndex).abs();
      if (!widget.fillsAvailableHeight && distance > 1 && duration > Duration.zero) {
        // Reveal the target as the indicator enters its final segment.
        _deferredPage = index;
        return;
      }

      _deferredPage = null;
      if (duration == Duration.zero) {
        _pageController.jumpToPage(index);
      } else {
        unawaited(
          _pageController
              .animateToPage(
                index,
                duration: duration,
                curve: tabController.currentAnimationCurve,
              )
              .whenComplete(() {
                if (mounted && _requestedPage == index) {
                  _requestedPage = null;
                }
              }),
        );
      }
    }
  }

  void _handleTabAnimationTick() {
    final targetPage = _deferredPage;
    if (targetPage != null && (_tabController.animation!.value - targetPage).abs() <= 1) {
      _showDeferredPage(targetPage);
    }
  }

  void _showDeferredPage(int index) {
    if (_deferredPage != index) {
      return;
    }
    if (!_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showDeferredPage(index);
        }
      });
      return;
    }

    _deferredPage = null;
    _pageController.jumpToPage(index);
  }

  void _handleContentPageChanged(int index) {
    final requestedPage = _requestedPage;
    if (requestedPage != null) {
      // Ignore pages crossed on the way to a non-adjacent tab.
      if (index != requestedPage) {
        return;
      }
      _requestedPage = null;
      return;
    }

    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  @override
  void dispose() {
    _tabController.animation!.removeListener(_handleTabAnimationTick);
    _tabController
      ..removeListener(_handleTabControllerChanged)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabController = _tabController;
    final body = widget.fillsAvailableHeight
        ? BaseModalBody.custom(
            child: PageView(
              controller: _pageController,
              onPageChanged: _handleContentPageChanged,
              children: widget.children,
            ),
          )
        : BaseModalBody.singleChild(
            child: ExpandablePageView(
              controller: _pageController,
              onPageChanged: _handleContentPageChanged,
              animationDuration: widget.animationDurationPerTab,
              animationCurve: Curves.ease,
              children: widget.children,
            ),
          );

    final footer = widget.footerBuilder == null ? widget.footer : widget.footerBuilder!(context, _selectedIndex, tabController);

    return BaseModal(
      title: widget.title,
      subtitle: widget.subtitle,
      headerBottom: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: widget.tabs,
      ),
      body: body,
      footer: footer,
    );
  }
}

// Keeps animation speed stable when skipping tabs.
class _DistanceAwareTabController extends TabController {
  _DistanceAwareTabController({
    required super.length,
    required super.vsync,
    required Duration durationPerTab,
    super.initialIndex,
  }) : assert(!durationPerTab.isNegative),
       super(animationDuration: durationPerTab);

  Duration currentAnimationDuration = Duration.zero;
  Curve currentAnimationCurve = Curves.ease;

  @override
  set index(int value) {
    currentAnimationDuration = Duration.zero;
    currentAnimationCurve = Curves.linear;
    super.index = value;
  }

  @override
  void animateTo(
    int value, {
    Duration? duration,
    Curve curve = Curves.ease,
  }) {
    final distance = (value - index).abs();
    currentAnimationDuration = duration ?? animationDuration * distance;
    currentAnimationCurve = curve;
    super.animateTo(
      value,
      duration: currentAnimationDuration,
      curve: currentAnimationCurve,
    );
  }
}
