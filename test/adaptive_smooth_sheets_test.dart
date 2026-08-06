import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'open route adapts across the breakpoint without losing child state',
    (tester) async {
      _configureView(tester, size: const Size(500, 800));

      await _pumpLauncher(
        tester,
        builder: (context) => const AdaptiveSheetScaffold(
          body: SizedBox(
            key: ValueKey('modal-content'),
            height: 240,
            child: _StateProbe(),
          ),
        ),
      );

      await _openSheet(tester);
      expect(find.text('bottomSheet:0'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('modal-content'))).width,
        500,
      );

      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('bottomSheet:1'), findsOneWidget);

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();

      expect(find.text('dialog:1'), findsOneWidget);
      expect(find.text('bottomSheet:1'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('modal-content'))).width,
        600,
      );
      expect(tester.takeException(), isNull);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('modal-content')), findsNothing);
    },
  );

  testWidgets('scroll position survives responsive reparenting', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 800));

    await _pumpLauncher(
      tester,
      builder: (context) => const SizedBox(
        height: 300,
        child: _ScrollProbe(key: ValueKey('scroll-probe')),
      ),
    );
    await _openSheet(tester);

    final stateBefore = tester.state<_ScrollProbeState>(
      find.byKey(const ValueKey('scroll-probe')),
    );
    stateBefore.controller.jumpTo(320);
    await tester.pump();
    expect(stateBefore.controller.offset, 320);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();

    final stateAfter = tester.state<_ScrollProbeState>(
      find.byKey(const ValueKey('scroll-probe')),
    );
    expect(identical(stateAfter, stateBefore), isTrue);
    expect(stateAfter.controller.offset, 320);
  });

  testWidgets('global theme defaults and per-route overrides are layered', (
    tester,
  ) async {
    _configureView(tester, size: const Size(1200, 800));
    const globalTheme = AdaptiveSheetThemeData(
      dialogBreakpoint: 1400,
      dialogWidth: 700,
      surfaceColor: Colors.red,
      barrierDismissible: true,
    );
    late AdaptiveSheetScope resolvedScope;

    await _pumpLauncher(
      tester,
      theme: ThemeData(extensions: const [globalTheme]),
      config: const AdaptiveSheetConfig(
        presentationPolicy: AdaptiveSheetPresentationPolicy(
          dialogBreakpoint: 1000,
        ),
        dialogWidth: 520,
        surfaceColor: Colors.blue,
        barrierDismissible: false,
      ),
      builder: (context) {
        final scope = AdaptiveSheetScope.of(context);
        resolvedScope = scope;
        return SizedBox(
          key: const ValueKey('overridden-content'),
          height: 160,
          child: const Text('Overridden content'),
        );
      },
    );

    await _openSheet(tester);

    expect(resolvedScope.presentation, AdaptiveSheetPresentation.dialog);
    expect(resolvedScope.theme.dialogBreakpoint, 1000);
    expect(resolvedScope.theme.dialogWidth, 520);
    expect(resolvedScope.theme.surfaceColor, Colors.blue);
    expect(resolvedScope.theme.dialogMaxHeight, globalTheme.dialogMaxHeight);
    expect(
      tester.getSize(find.byKey(const ValueKey('overridden-content'))).width,
      520,
    );

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overridden-content')), findsOneWidget);
  });

  testWidgets('custom resolver reacts to live MediaQuery changes', (
    tester,
  ) async {
    _configureView(tester, size: const Size(1000, 800));
    final config = AdaptiveSheetConfig(
      presentationPolicy: AdaptiveSheetPresentationPolicy(
        resolver: (context) => MediaQuery.sizeOf(context).width >= 900
            ? AdaptiveSheetPresentation.dialog
            : AdaptiveSheetPresentation.bottomSheet,
      ),
    );

    await _pumpLauncher(
      tester,
      config: config,
      builder: (context) => SizedBox(
        height: 100,
        child: Text(AdaptiveSheetScope.of(context).presentation.name),
      ),
    );

    await _openSheet(tester);
    expect(find.text('dialog'), findsOneWidget);

    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();
    expect(find.text('bottomSheet'), findsOneWidget);
  });

  testWidgets('bottom sheet uses distinct window and safe-area top gaps', (
    tester,
  ) async {
    _configureView(
      tester,
      size: const Size(500, 800),
      padding: const FakeViewPadding(top: 80, bottom: 34),
    );

    await _pumpLauncher(
      tester,
      config: const AdaptiveSheetConfig(
        bottomSheetMinimumTopGap: 30,
        bottomSheetMinimumTopGapAfterSafeArea: 40,
      ),
      builder: (context) =>
          const SizedBox(key: ValueKey('tall-content'), height: 1200),
    );

    await _openSheet(tester);

    final contentRect = tester.getRect(
      find.byKey(const ValueKey('tall-content')),
    );
    expect(contentRect.top, 80 + 40);
    expect(contentRect.bottom, lessThanOrEqualTo(800 - 34));

    tester.view
      ..padding = FakeViewPadding.zero
      ..viewPadding = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('tall-content'))).top, 30);
  });

  testWidgets('bottom sheet moves above the software keyboard', (tester) async {
    _configureView(tester, size: const Size(500, 800));

    await _pumpLauncher(
      tester,
      builder: (context) =>
          const SizedBox(key: ValueKey('keyboard-content'), height: 240),
    );
    await _openSheet(tester);
    expect(
      tester.getRect(find.byKey(const ValueKey('keyboard-content'))).bottom,
      800,
    );

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('keyboard-content'))).bottom,
      540,
    );
  });

  testWidgets('dialog margin expands for safe areas and the keyboard', (
    tester,
  ) async {
    _configureView(
      tester,
      size: const Size(1200, 800),
      padding: const FakeViewPadding(top: 40),
    );

    await _pumpLauncher(
      tester,
      config: const AdaptiveSheetConfig(dialogMargin: EdgeInsets.all(24)),
      builder: (context) =>
          const SizedBox(key: ValueKey('dialog-content'), height: 700),
    );
    await _openSheet(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 40);
    await tester.pumpAndSettle();

    final contentRect = tester.getRect(
      find.byKey(const ValueKey('dialog-content')),
    );
    expect(contentRect.top, greaterThanOrEqualTo(40));
    expect(contentRect.bottom, lessThanOrEqualTo(800 - 300 - 24));
  });

  testWidgets('adaptive pop scope can guard route dismissal', (tester) async {
    _configureView(tester, size: const Size(500, 800));

    await _pumpLauncher(
      tester,
      builder: (context) => const AdaptiveSheetPopScope<void>(
        canPop: false,
        child: SizedBox(
          key: ValueKey('guarded-content'),
          height: 180,
          child: Text('Guarded content'),
        ),
      ),
    );
    await _openSheet(tester);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('guarded-content')), findsOneWidget);
  });
}

void _configureView(
  WidgetTester tester, {
  required Size size,
  FakeViewPadding padding = FakeViewPadding.zero,
}) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..padding = padding
    ..viewPadding = padding;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio()
      ..resetPadding()
      ..resetViewPadding()
      ..resetViewInsets();
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required WidgetBuilder builder,
  ThemeData? theme,
  AdaptiveSheetConfig config = const AdaptiveSheetConfig(),
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () {
              unawaited(
                showAdaptiveSheet<void>(
                  context: context,
                  config: config,
                  builder: builder,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

class _StateProbe extends StatefulWidget {
  const _StateProbe();

  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final presentation = AdaptiveSheetScope.of(context).presentation;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${presentation.name}:$_count'),
        FilledButton(
          onPressed: () => setState(() => _count += 1),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _ScrollProbe extends StatefulWidget {
  const _ScrollProbe({super.key});

  @override
  State<_ScrollProbe> createState() => _ScrollProbeState();
}

class _ScrollProbeState extends State<_ScrollProbe> {
  final ScrollController controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemExtent: 48,
      itemCount: 30,
      itemBuilder: (context, index) => Text('Item $index'),
    );
  }
}
