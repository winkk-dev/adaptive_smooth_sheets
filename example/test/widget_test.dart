import 'package:example/main.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launcher explains and opens the quick-view example', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Quick view'), findsOneWidget);
    expect(find.text('Scroll-to-drag gesture handoff'), findsOneWidget);
    expect(find.text('Content-sized tabs'), findsOneWidget);
    expect(find.text('Scrollable tabs'), findsOneWidget);
    expect(find.text('Reactive form'), findsOneWidget);

    await tester.tap(find.text('Quick view'));
    await tester.pumpAndSettle();

    expect(find.text('Quick view'), findsWidgets);
    expect(find.textContaining('This content remains mounted'), findsOneWidget);
  });

  testWidgets('reactive form shares validation state with its footer', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.ensureVisible(find.text('Reactive form'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reactive form'));
    await tester.pumpAndSettle();

    expect(find.text('Project brief'), findsOneWidget);
    expect(find.text('Project name'), findsOneWidget);
    expect(find.text('Project code'), findsOneWidget);
    expect(find.text('Team size'), findsOneWidget);
    expect(find.text('Budget (€k)'), findsOneWidget);
    expect(find.text('After approval'), findsOneWidget);
    expect(find.text('First-month success target'), findsOneWidget);
    expect(find.text('Support contact'), findsOneWidget);
    expect(find.text('Follow-up notes'), findsOneWidget);
    expect(find.text('Save brief'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.ensureVisible(find.text('Project type'));
    await tester.tap(find.text('Project type'));
    await tester.pumpAndSettle();

    expect(find.text('Mobile application').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Mobile application').hitTestable());
    await tester.pumpAndSettle();
  });

  testWidgets('content-sized tabs resize and select their own footers', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Content-sized tabs'));
    await tester.pumpAndSettle();

    final pageView = find.byType(ExpandablePageView);
    final summaryHeight = tester.getSize(pageView).height;
    expect(find.widgetWithText(FilledButton, 'Show details'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Previous'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Show details'));
    await tester.pumpAndSettle();

    expect(find.textContaining('modal grows with it'), findsOneWidget);
    expect(tester.getSize(pageView).height, greaterThan(summaryHeight));
    expect(find.widgetWithText(OutlinedButton, 'Previous'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Review'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(tester.widget<ExpandablePageView>(pageView).controller!.page, 2);
    expect(find.textContaining('Previous and Show timeline'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Show timeline'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Show timeline'));
    await tester.pumpAndSettle();

    expect(find.text('Timeline event 7'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Finish'), findsOneWidget);

    await tester.drag(pageView, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('Previous and Show timeline'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Show timeline'), findsOneWidget);
  });

  testWidgets('content-sized tabs keep constant per-tab speed and monotonic motion', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Content-sized tabs'));
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final tabController = tabBar.controller!;
    await tester.tap(find.widgetWithText(Tab, 'Details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tabController.index, 1);
    expect(tabController.indexIsChanging, isFalse);
    await tester.tap(find.widgetWithText(Tab, 'Summary'));
    await tester.pumpAndSettle();

    final pageView = find.byType(ExpandablePageView);
    final pageController = tester.widget<ExpandablePageView>(pageView).controller!;
    final summaryHeight = tester.getSize(pageView).height;
    final indicatorPositions = <double>[tabController.animation!.value];
    final tabTargets = <int>[];
    final contentPages = <double>[];

    await tester.tap(find.widgetWithText(Tab, 'Timeline'));
    await tester.pump();
    expect(pageController.page, 0);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      indicatorPositions.add(tabController.animation!.value);
      tabTargets.add(tabController.index);
      contentPages.add(pageController.page!);
    }

    for (var i = 1; i < indicatorPositions.length; i++) {
      expect(
        indicatorPositions[i],
        greaterThanOrEqualTo(indicatorPositions[i - 1]),
        reason: 'The indicator must not reverse on its way from tab 1 to tab 4.',
      );
    }
    expect(tabTargets, everyElement(3));
    expect(tabController.indexIsChanging, isTrue);
    expect(contentPages, everyElement(anyOf(0, 3)));
    expect(pageController.page, 3);
    expect(tester.getSize(pageView).height, greaterThan(summaryHeight));
    await tester.pumpAndSettle();
    expect(tabController.index, 3);
    expect(tabController.animation!.value, 3);

    indicatorPositions
      ..clear()
      ..add(tabController.animation!.value);
    tabTargets.clear();
    contentPages.clear();
    await tester.tap(find.widgetWithText(Tab, 'Summary'));
    await tester.pump();
    expect(pageController.page, 3);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      indicatorPositions.add(tabController.animation!.value);
      tabTargets.add(tabController.index);
      contentPages.add(pageController.page!);
    }

    for (var i = 1; i < indicatorPositions.length; i++) {
      expect(
        indicatorPositions[i],
        lessThanOrEqualTo(indicatorPositions[i - 1]),
        reason: 'The indicator must not reverse on its way from tab 4 to tab 1.',
      );
    }
    expect(tabTargets, everyElement(0));
    expect(contentPages, everyElement(anyOf(0, 3)));
    expect(pageController.page, 0);
    await tester.pumpAndSettle();
    expect(tabController.index, 0);
    expect(tabController.animation!.value, 0);
    expect(tester.getSize(pageView).height, summaryHeight);
  });

  testWidgets('scrollable tabs use the same duration per crossed tab', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Scrollable tabs'));
    await tester.pumpAndSettle();

    final tabController = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    await tester.tap(find.widgetWithText(Tab, 'Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tabController.index, 2);
    expect(tabController.indexIsChanging, isTrue);
    await tester.pumpAndSettle();
    expect(tabController.animation!.value, 2);
  });

  testWidgets('selected tab survives an adaptive presentation change', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Scrollable tabs'));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(ExpandablePageView), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Close'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Activity event 1'), findsOneWidget);
    expect(find.text('Activity event 500'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Close'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('guarded close reports blocked dismissal attempts', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.ensureVisible(find.text('Guarded close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guarded close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Guarded close'), findsWidgets);
  });

  testWidgets('navigation modal transitions forward and back between steps', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.ensureVisible(find.text('Navigation flow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navigation flow'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 1 of 3'), findsOneWidget);
    expect(find.text('Choose a starting direction'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 2 of 3'), findsOneWidget);
    expect(find.text('Tune the interaction'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 2 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 1 of 3'), findsOneWidget);
    expect(find.text('Choose a starting direction'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 3 of 3'), findsOneWidget);
    expect(find.text('Ready to finish'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step 3 of 3'), findsNothing);
    expect(find.text('Navigation flow'), findsOneWidget);
  });
}

void _configureView(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(500, 900);
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}
