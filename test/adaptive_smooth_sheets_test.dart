import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets(
    'dialog route adapts to a bottom sheet without losing child state',
    (tester) async {
      _configureView(tester, size: const Size(1200, 800));

      await _pumpLauncher(
        tester,
        builder: (context) => const AdaptiveSheetScaffold(
          body: SizedBox(height: 240, child: _StateProbe()),
        ),
      );

      await _openSheet(tester);
      final stateBefore = tester.state<_StateProbeState>(
        find.byType(_StateProbe),
      );
      await tester.tap(find.text('Increment'));
      await tester.enterText(
        find.byKey(const ValueKey('state-probe-input')),
        'Draft note',
      );
      await tester.pump();
      expect(find.text('dialog:1'), findsOneWidget);

      tester.view.physicalSize = const Size(500, 800);
      await tester.pumpAndSettle();

      final stateAfter = tester.state<_StateProbeState>(
        find.byType(_StateProbe),
      );
      expect(identical(stateAfter, stateBefore), isTrue);
      expect(find.text('bottomSheet:1'), findsOneWidget);
      expect(find.text('Draft note'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('page provides stable primary scrolling across presentations', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 800));
    AdaptiveSheetScrollController? firstController;
    AdaptiveSheetScrollController? currentController;

    await _pumpLauncher(
      tester,
      theme: ThemeData(platform: TargetPlatform.macOS),
      builder: (context) {
        currentController = AdaptiveSheetScrollController.of(context);
        firstController ??= currentController;
        return SizedBox(
          height: 300,
          child: ListView.builder(
            key: const ValueKey('primary-scroll-list'),
            itemExtent: 48,
            itemCount: 30,
            itemBuilder: (context, index) => Text('Item $index'),
          ),
        );
      },
    );
    await _openSheet(tester);

    final listContext = tester.element(
      find.byKey(const ValueKey('primary-scroll-list')),
    );
    expect(currentController, same(firstController));
    expect(PrimaryScrollController.of(listContext), same(firstController));

    firstController!.jumpTo(320);
    await tester.pump();
    expect(firstController!.offset, 320);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();

    expect(currentController, same(firstController));
    expect(
      PrimaryScrollController.of(
        tester.element(find.byKey(const ValueKey('primary-scroll-list'))),
      ),
      same(firstController),
    );
    expect(firstController!.offset, 320);

    tester.view.physicalSize = const Size(500, 800);
    await tester.pumpAndSettle();

    expect(
      PrimaryScrollController.of(
        tester.element(find.byKey(const ValueKey('primary-scroll-list'))),
      ),
      same(firstController),
    );
    expect(firstController!.offset, 320);
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
      enableMouseDrag: false,
      bottomSheetPhysics: BouncingSheetPhysics(),
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
        enableMouseDrag: true,
        bottomSheetPhysics: ClampingSheetPhysics(),
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
    expect(resolvedScope.theme.enableMouseDrag, isTrue);
    expect(
      resolvedScope.theme.bottomSheetPhysics,
      isA<ClampingSheetPhysics>(),
    );
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
        resolver: (context) => MediaQuery.sizeOf(context).width >= 900 ? AdaptiveSheetPresentation.dialog : AdaptiveSheetPresentation.bottomSheet,
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
      builder: (context) => const SizedBox(key: ValueKey('tall-content'), height: 1200),
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
      builder: (context) => const SizedBox(key: ValueKey('keyboard-content'), height: 240),
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
      builder: (context) => const SizedBox(key: ValueKey('dialog-content'), height: 700),
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

    await tester.drag(
      find.byKey(const ValueKey('guarded-content')),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guarded-content')), findsOneWidget);
  });

  testWidgets(
    'navigator pushes pages, returns typed results, and keeps the first page',
    (tester) async {
      _configureView(tester, size: const Size(500, 900));
      await tester.pumpWidget(const _NavigationTestApp());
      await _openSheet(tester);

      expect(find.text('canPop:false'), findsOneWidget);
      await tester.tap(find.text('Try first pop'));
      await tester.pump();
      expect(find.text('firstPop:false'), findsOneWidget);
      expect(find.text('First page'), findsOneWidget);

      await tester.tap(find.text('Increment first'));
      await tester.tap(find.text('Push second'));
      await tester.pumpAndSettle();
      expect(find.text('Second page'), findsOneWidget);
      expect(find.text('canPop:true'), findsOneWidget);

      await tester.tap(find.text('Push third'));
      await tester.pumpAndSettle();
      expect(find.text('Third page'), findsOneWidget);

      await tester.tap(find.text('Return third result'));
      await tester.pumpAndSettle();
      expect(find.text('thirdResult:done'), findsOneWidget);

      await tester.tap(find.text('Return second result'));
      await tester.pumpAndSettle();
      expect(find.text('First page'), findsOneWidget);
      expect(find.text('firstCount:1'), findsOneWidget);
      expect(find.text('secondResult:42'), findsOneWidget);
      expect(find.text('canPop:false'), findsOneWidget);
    },
  );

  testWidgets('navigator replaces the current page with typed results', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);

    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace second'));
    await tester.pumpAndSettle();

    expect(find.text('Replacement page'), findsOneWidget);
    expect(find.text('canPop:true'), findsOneWidget);
    expect(
      find.text('secondResult:42', skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('Back from replacement'));
    await tester.pumpAndSettle();

    expect(find.text('First page'), findsOneWidget);
    expect(find.text('Replacement page'), findsNothing);
    expect(find.text('Second page'), findsNothing);
    expect(find.text('secondResult:42'), findsOneWidget);
    expect(find.text('canPop:false'), findsOneWidget);
  });

  testWidgets('replacing the first page keeps it at the stack root', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);

    await tester.tap(find.text('Replace first'));
    await tester.pumpAndSettle();

    expect(find.text('Root replacement page'), findsOneWidget);
    expect(find.text('canPop:false'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Root replacement page'), findsNothing);
  });

  testWidgets('replaceAll resets a deep internal page stack', (tester) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);

    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push third'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace all'));
    await tester.pumpAndSettle();

    expect(find.text('Stack replacement page'), findsOneWidget);
    expect(find.text('canPop:false'), findsOneWidget);
    expect(find.text('First page', skipOffstage: false), findsNothing);
    expect(find.text('Second page', skipOffstage: false), findsNothing);
    expect(find.text('Third page', skipOffstage: false), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Stack replacement page'), findsNothing);
  });

  testWidgets('close dismisses the complete sheet from internal depth', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push third'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close with result'));
    await tester.pumpAndSettle();

    expect(find.text('Third page'), findsNothing);
    expect(find.text('sheetResult:closed'), findsOneWidget);
  });

  testWidgets('consecutive native backs unwind every page before closing', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push third'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Third page'), findsNothing);
    expect(find.text('Second page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsNothing);
    expect(find.text('First page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('First page'), findsNothing);
  });

  testWidgets('dropdown routes do not count as adaptive sheet pages', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      builder: (context) => const _FirstPopupPage(),
    );
    await _openSheet(tester);

    expect(find.text('popupCanPop:false'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('first-popup-dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('First popup B').hitTestable(), findsOneWidget);
    expect(find.text('popupCanPop:false'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('First popup B').hitTestable(), findsNothing);
    expect(find.text('First popup page'), findsOneWidget);
    expect(find.text('popupCanPop:false'), findsOneWidget);

    await tester.tap(find.text('Push popup page'));
    await tester.pumpAndSettle();
    expect(find.text('popupCanPop:true'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('second-popup-dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('Second popup B').hitTestable(), findsOneWidget);
    expect(find.text('popupCanPop:true'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Second popup B').hitTestable(), findsNothing);
    expect(find.text('Second popup page'), findsOneWidget);
    expect(find.text('popupCanPop:true'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('First popup page'), findsOneWidget);
    expect(find.text('popupCanPop:false'), findsOneWidget);
  });

  testWidgets('page dismissal guard remains active below a dropdown route', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      builder: (context) => const _GuardedDropdownPage(),
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('guarded-dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('Guarded popup B').hitTestable(), findsOneWidget);

    tester
        .state<_GuardedDropdownPageState>(
          find.byType(_GuardedDropdownPage),
        )
        .attemptClose();
    await tester.pump();

    expect(find.text('Guarded dropdown page'), findsOneWidget);
    expect(find.text('Guarded popup B').hitTestable(), findsOneWidget);
    expect(find.text('blockedAttempts:1'), findsOneWidget);

    await tester.tap(find.text('Guarded popup B').hitTestable());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Guarded popup B').hitTestable(), findsNothing);
  });

  testWidgets('Escape preserves descendant autofocus and always closes', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      config: const AdaptiveSheetConfig(barrierDismissible: false),
      builder: (context) => const SizedBox(
        key: ValueKey('autofocus-content'),
        height: 180,
        child: TextField(autofocus: true),
      ),
    );
    await _openSheet(tester);

    final editableText = tester.widget<EditableText>(
      find.byType(EditableText),
    );
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('autofocus-content')), findsNothing);
  });

  testWidgets('barrier and Escape close the outer sheet at page depth', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsNothing);

    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsNothing);
    expect(find.text('First page'), findsNothing);
  });

  testWidgets('native back behavior supports theme and per-sheet policies', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(
      const _NavigationTestApp(
        sheetTheme: AdaptiveSheetThemeData(
          nativeBackBehavior: AdaptiveSheetNativeBackBehavior.closeSheet,
        ),
      ),
    );
    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('First page'), findsNothing);
    expect(find.text('Second page'), findsNothing);

    await tester.pumpWidget(
      const _NavigationTestApp(
        sheetTheme: AdaptiveSheetThemeData(
          nativeBackBehavior: AdaptiveSheetNativeBackBehavior.closeSheet,
        ),
        config: AdaptiveSheetConfig(
          nativeBackBehavior: AdaptiveSheetNativeBackBehavior.popPageOrCloseSheet,
        ),
      ),
    );
    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('First page'), findsOneWidget);
    expect(find.text('Second page'), findsNothing);
  });

  testWidgets('swipe dismissal closes the outer sheet at page depth', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('second-page-surface')),
      const Offset(0, 700),
    );
    await tester.pumpAndSettle();

    expect(find.text('Second page'), findsNothing);
  });

  testWidgets('dragging a tall dialog does not dismiss it', (tester) async {
    _configureView(tester, size: const Size(1200, 900));
    await _pumpLauncher(
      tester,
      builder: (context) => const ColoredBox(
        key: ValueKey('tall-dialog-content'),
        color: Colors.transparent,
        child: SizedBox(height: 800),
      ),
    );
    await _openSheet(tester);

    final content = find.byKey(const ValueKey('tall-dialog-content'));
    await tester.drag(content, const Offset(0, 700));
    await tester.pumpAndSettle();

    expect(content, findsOneWidget);
  });

  testWidgets('upward overdrag keeps the bottom sheet flush with the viewport', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      builder: (context) => const SizedBox(
        key: ValueKey('clamped-sheet-content'),
        height: 320,
      ),
    );
    await _openSheet(tester);

    final content = find.byKey(const ValueKey('clamped-sheet-content'));
    final initialRect = tester.getRect(content);
    final gesture = await tester.startGesture(tester.getCenter(content));
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();

    expect(tester.getRect(content), initialRect);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(content, findsOneWidget);
  });

  testWidgets('route physics can opt into elastic upward overdrag', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      config: const AdaptiveSheetConfig(
        bottomSheetPhysics: BouncingSheetPhysics(),
      ),
      builder: (context) => const SizedBox(
        key: ValueKey('bouncing-sheet-content'),
        height: 320,
      ),
    );
    await _openSheet(tester);

    final content = find.byKey(const ValueKey('bouncing-sheet-content'));
    final initialRect = tester.getRect(content);
    final gesture = await tester.startGesture(tester.getCenter(content));
    await gesture.moveBy(const Offset(0, -200));
    await tester.pump();

    expect(tester.getRect(content).bottom, lessThan(initialRect.bottom));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getRect(content), initialRect);
  });

  testWidgets('mouse dragging dismisses a bottom sheet', (tester) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      builder: (context) => const SizedBox(
        key: ValueKey('mouse-drag-content'),
        height: 320,
      ),
    );
    await _openSheet(tester);

    final content = find.byKey(const ValueKey('mouse-drag-content'));
    final initialTop = tester.getRect(content).top;
    final gesture = await tester.startGesture(
      tester.getCenter(content),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, 700));
    await tester.pump();
    expect(tester.getRect(content).top, greaterThan(initialTop));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(content, findsNothing);
  });

  testWidgets('mouse dragging can be disabled independently', (tester) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      config: const AdaptiveSheetConfig(enableMouseDrag: false),
      builder: (context) => const SizedBox(
        key: ValueKey('mouse-drag-disabled-content'),
        height: 320,
      ),
    );
    await _openSheet(tester);

    final content = find.byKey(
      const ValueKey('mouse-drag-disabled-content'),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(content),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, 700));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(content, findsOneWidget);

    final touchGesture = await tester.startGesture(tester.getCenter(content));
    await touchGesture.moveBy(const Offset(0, 700));
    await touchGesture.up();
    await tester.pumpAndSettle();
    expect(content, findsNothing);
  });

  testWidgets('current nested page and state survive responsive resizing', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await tester.pumpWidget(const _NavigationTestApp());
    await _openSheet(tester);
    await tester.tap(find.text('Push second'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Increment second'));
    await tester.pump();
    expect(find.text('secondCount:1'), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(find.text('Second page'), findsOneWidget);
    expect(find.text('secondCount:1'), findsOneWidget);
    expect(find.text('canPop:true'), findsOneWidget);
    expect(
      AdaptiveSheetScope.of(
        tester.element(find.byKey(const ValueKey('second-page-surface'))),
      ).presentation,
      AdaptiveSheetPresentation.dialog,
    );

    await tester.tap(find.text('Back to first'));
    await tester.pumpAndSettle();
    expect(find.text('First page'), findsOneWidget);
  });

  testWidgets('paged sheet settles to each page height in both directions', (
    tester,
  ) async {
    _configureView(tester, size: const Size(500, 900));
    await _pumpLauncher(
      tester,
      builder: (context) => const _ShortHeightPage(),
    );
    await _openSheet(tester);

    expect(
      tester.getRect(find.byKey(const ValueKey('short-height-page'))).top,
      680,
    );

    await tester.tap(find.text('Show tall page'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('tall-height-page'))).top,
      460,
    );

    await tester.tap(find.text('Show short page'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('short-height-page'))).top,
      680,
    );
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
                  page: AdaptiveSheetPage<void>(
                    child: Builder(builder: builder),
                  ),
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
        const TextField(key: ValueKey('state-probe-input')),
        FilledButton(
          onPressed: () => setState(() => _count += 1),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

class _NavigationTestApp extends StatefulWidget {
  const _NavigationTestApp({
    this.config = const AdaptiveSheetConfig(),
    this.sheetTheme,
  });

  final AdaptiveSheetConfig config;
  final AdaptiveSheetThemeData? sheetTheme;

  @override
  State<_NavigationTestApp> createState() => _NavigationTestAppState();
}

class _NavigationTestAppState extends State<_NavigationTestApp> {
  String? _sheetResult;

  Future<void> _showSheet(BuildContext context) async {
    final result = await showAdaptiveSheet<String>(
      context: context,
      config: widget.config,
      page: const AdaptiveSheetPage<String>(child: _FirstNavigationPage()),
    );
    if (mounted) {
      setState(() => _sheetResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: widget.sheetTheme == null ? null : ThemeData(extensions: [widget.sheetTheme!]),
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                onPressed: () => unawaited(_showSheet(context)),
                child: const Text('Open'),
              ),
              Text('sheetResult:${_sheetResult ?? 'none'}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirstNavigationPage extends StatefulWidget {
  const _FirstNavigationPage();

  @override
  State<_FirstNavigationPage> createState() => _FirstNavigationPageState();
}

class _FirstNavigationPageState extends State<_FirstNavigationPage> {
  int _count = 0;
  bool? _firstPopResult;
  int? _secondResult;

  Future<void> _pushSecond(BuildContext context) async {
    final result = await AdaptiveSheetNavigator.of(context).push<int>(
      const AdaptiveSheetPage<int>(child: _SecondNavigationPage()),
    );
    if (mounted) {
      setState(() => _secondResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigator = AdaptiveSheetNavigator.of(context);
    return SizedBox(
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('First page'),
          Text('canPop:${navigator.canPop}'),
          Text('firstCount:$_count'),
          Text('firstPop:${_firstPopResult ?? 'none'}'),
          Text('secondResult:${_secondResult ?? 'none'}'),
          FilledButton(
            onPressed: () => setState(() => _count += 1),
            child: const Text('Increment first'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _firstPopResult = navigator.pop<void>());
            },
            child: const Text('Try first pop'),
          ),
          FilledButton(
            onPressed: () => unawaited(_pushSecond(context)),
            child: const Text('Push second'),
          ),
          FilledButton(
            onPressed: () {
              unawaited(
                navigator.replace<void, void>(
                  const AdaptiveSheetPage<void>(
                    child: _ReplacementNavigationPage(
                      title: 'Root replacement page',
                    ),
                  ),
                ),
              );
            },
            child: const Text('Replace first'),
          ),
        ],
      ),
    );
  }
}

class _SecondNavigationPage extends StatefulWidget {
  const _SecondNavigationPage();

  @override
  State<_SecondNavigationPage> createState() => _SecondNavigationPageState();
}

class _SecondNavigationPageState extends State<_SecondNavigationPage> {
  int _count = 0;
  String? _thirdResult;

  Future<void> _pushThird(BuildContext context) async {
    final result = await AdaptiveSheetNavigator.of(context).push<String>(
      const AdaptiveSheetPage<String>(child: _ThirdNavigationPage()),
    );
    if (mounted) {
      setState(() => _thirdResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigator = AdaptiveSheetNavigator.of(context);
    return SizedBox(
      key: const ValueKey('second-page-surface'),
      height: 360,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Second page'),
          Text('canPop:${navigator.canPop}'),
          Text('secondCount:$_count'),
          Text('thirdResult:${_thirdResult ?? 'none'}'),
          FilledButton(
            onPressed: () => setState(() => _count += 1),
            child: const Text('Increment second'),
          ),
          FilledButton(
            onPressed: () => unawaited(_pushThird(context)),
            child: const Text('Push third'),
          ),
          FilledButton(
            onPressed: () {
              unawaited(
                navigator.replace<void, int>(
                  const AdaptiveSheetPage<void>(
                    child: _ReplacementNavigationPage(
                      title: 'Replacement page',
                    ),
                  ),
                  result: 42,
                ),
              );
            },
            child: const Text('Replace second'),
          ),
          OutlinedButton(
            onPressed: () => navigator.pop<int>(42),
            child: const Text('Return second result'),
          ),
          OutlinedButton(
            onPressed: navigator.pop,
            child: const Text('Back to first'),
          ),
        ],
      ),
    );
  }
}

class _ThirdNavigationPage extends StatelessWidget {
  const _ThirdNavigationPage();

  @override
  Widget build(BuildContext context) {
    final navigator = AdaptiveSheetNavigator.of(context);
    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Third page'),
          FilledButton(
            onPressed: () => navigator.pop<String>('done'),
            child: const Text('Return third result'),
          ),
          FilledButton(
            onPressed: () => navigator.close<String>('closed'),
            child: const Text('Close with result'),
          ),
          FilledButton(
            onPressed: () {
              unawaited(
                navigator.replaceAll<void>(
                  const AdaptiveSheetPage<void>(
                    child: _ReplacementNavigationPage(
                      title: 'Stack replacement page',
                    ),
                  ),
                ),
              );
            },
            child: const Text('Replace all'),
          ),
        ],
      ),
    );
  }
}

class _FirstPopupPage extends StatelessWidget {
  const _FirstPopupPage();

  @override
  Widget build(BuildContext context) {
    final navigator = AdaptiveSheetNavigator.of(context);
    return SizedBox(
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('First popup page'),
          Text('popupCanPop:${navigator.canPop}'),
          _PopupDropdown(
            key: const ValueKey('first-popup-dropdown'),
            labelPrefix: 'First popup',
          ),
          FilledButton(
            onPressed: () {
              unawaited(
                navigator.push<void>(
                  const AdaptiveSheetPage<void>(child: _SecondPopupPage()),
                ),
              );
            },
            child: const Text('Push popup page'),
          ),
        ],
      ),
    );
  }
}

class _SecondPopupPage extends StatelessWidget {
  const _SecondPopupPage();

  @override
  Widget build(BuildContext context) {
    final navigator = AdaptiveSheetNavigator.of(context);
    return SizedBox(
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Second popup page'),
          Text('popupCanPop:${navigator.canPop}'),
          const _PopupDropdown(
            key: ValueKey('second-popup-dropdown'),
            labelPrefix: 'Second popup',
          ),
        ],
      ),
    );
  }
}

class _PopupDropdown extends StatelessWidget {
  const _PopupDropdown({super.key, required this.labelPrefix});

  final String labelPrefix;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: 'a',
      onChanged: (_) {},
      items: [
        DropdownMenuItem(value: 'a', child: Text('$labelPrefix A')),
        DropdownMenuItem(value: 'b', child: Text('$labelPrefix B')),
      ],
    );
  }
}

class _ReplacementNavigationPage extends StatelessWidget {
  const _ReplacementNavigationPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final navigator = AdaptiveSheetNavigator.of(context);
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          Text('canPop:${navigator.canPop}'),
          if (navigator.canPop)
            FilledButton(
              onPressed: navigator.pop,
              child: const Text('Back from replacement'),
            ),
        ],
      ),
    );
  }
}

class _GuardedDropdownPage extends StatefulWidget {
  const _GuardedDropdownPage();

  @override
  State<_GuardedDropdownPage> createState() => _GuardedDropdownPageState();
}

class _GuardedDropdownPageState extends State<_GuardedDropdownPage> {
  var _blockedAttempts = 0;

  void attemptClose() {
    AdaptiveSheetNavigator.of(context).close();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSheetPopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() => _blockedAttempts += 1);
        }
      },
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Guarded dropdown page'),
            Text('blockedAttempts:$_blockedAttempts'),
            const _PopupDropdown(
              key: ValueKey('guarded-dropdown'),
              labelPrefix: 'Guarded popup',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortHeightPage extends StatelessWidget {
  const _ShortHeightPage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('short-height-page'),
      height: 220,
      child: Center(
        child: FilledButton(
          onPressed: () {
            unawaited(
              AdaptiveSheetNavigator.of(context).push<void>(
                const AdaptiveSheetPage<void>(child: _TallHeightPage()),
              ),
            );
          },
          child: const Text('Show tall page'),
        ),
      ),
    );
  }
}

class _TallHeightPage extends StatelessWidget {
  const _TallHeightPage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('tall-height-page'),
      height: 440,
      child: Center(
        child: FilledButton(
          onPressed: AdaptiveSheetNavigator.of(context).pop,
          child: const Text('Show short page'),
        ),
      ),
    );
  }
}
