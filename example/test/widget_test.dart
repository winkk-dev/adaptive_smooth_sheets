import 'package:example/main.dart';
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

    await tester.drag(find.byType(ListView), const Offset(0, -500));
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

  testWidgets('selected tab survives an adaptive presentation change', (
    tester,
  ) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Tabs'));
    await tester.pumpAndSettle();
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

    await tester.drag(find.byType(ListView), const Offset(0, -200));
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
