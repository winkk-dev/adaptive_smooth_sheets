import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launcher presents focused public API demos', (tester) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Basic adaptive modal'), findsOneWidget);
    expect(find.text('Lazy list'), findsOneWidget);
    expect(find.text('Resize state'), findsOneWidget);
    expect(find.text('Modal navigation'), findsOneWidget);
    expect(find.text('Guarded dismissal'), findsOneWidget);
    expect(find.text('Route-specific config'), findsOneWidget);
    expect(find.text('Fixed app chrome'), findsNothing);
    expect(find.text('Reactive form'), findsNothing);
    expect(find.text('Scrollable tabs'), findsNothing);
  });

  testWidgets('basic demo opens in bottom-sheet presentation on a narrow window', (tester) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Basic adaptive modal'));
    await tester.pumpAndSettle();

    expect(find.text('Bottom sheet'), findsOneWidget);
    expect(find.textContaining('Resize the window while this modal is open'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Bottom sheet')).dy,
      closeTo(tester.getCenter(find.byTooltip('Close')).dy, 0.5),
    );
  });

  testWidgets('route-specific config stays a sheet past the app breakpoint', (tester) async {
    _configureView(tester);
    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpWidget(const ExampleApp());

    await tester.ensureVisible(find.text('Route-specific config'));
    await tester.tap(find.text('Route-specific config'));
    await tester.pumpAndSettle();

    expect(find.text('Bottom sheet'), findsOneWidget);
    expect(find.text('Dialog breakpoint'), findsOneWidget);
    expect(find.text('900 px'), findsOneWidget);

    tester.view.physicalSize = const Size(1000, 900);
    await tester.pumpAndSettle();

    expect(find.text('Dialog'), findsOneWidget);
  });

  testWidgets('resize demo preserves widget and text-field state', (tester) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Resize state'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('resize-state-field')), 'Kept across resize');
    await tester.tap(find.text('Increment'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1000, 900);
    await tester.pumpAndSettle();

    expect(find.text('Dialog'), findsOneWidget);
    expect(find.text('Count: 1'), findsOneWidget);
    expect(find.text('Kept across resize'), findsOneWidget);
  });

  testWidgets('navigation pushes and pops without losing the first page state', (tester) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.ensureVisible(find.text('Modal navigation'));
    await tester.tap(find.text('Modal navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Increment state'));
    await tester.tap(find.text('Push next page'));
    await tester.pumpAndSettle();

    expect(find.text('Second page'), findsOneWidget);
    await tester.tap(find.text('Pop page'));
    await tester.pumpAndSettle();

    expect(find.text('State value: 1'), findsOneWidget);
  });

  testWidgets('navigation replaceAll creates a new stack root', (tester) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.ensureVisible(find.text('Modal navigation'));
    await tester.tap(find.text('Modal navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push next page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('replaceAll'));
    await tester.pumpAndSettle();

    expect(find.text('Entire stack replaced'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('dismissal guard blocks then allows a close request', (tester) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.ensureVisible(find.text('Guarded dismissal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guarded dismissal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try to close'));
    await tester.pump();

    expect(find.text('Close blocked while changes are unsaved.'), findsOneWidget);
    final saveButton = find.text('Mark as saved');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    final closeButton = find.text('Close modal');
    await tester.ensureVisible(closeButton);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    expect(find.text('Guarded dismissal'), findsOneWidget);
  });

  testWidgets('lazy list exposes programmatic primary scrolling', (tester) async {
    _configureView(tester);
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Lazy list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scroll to item 60'));
    await tester.pumpAndSettle();

    expect(find.text('List item 60'), findsOneWidget);
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
