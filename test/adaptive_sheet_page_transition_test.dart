import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme uses platform pages on mobile and shared-axis in dialogs', () {
    const theme = AdaptiveSheetThemeData();

    expect(theme.bottomSheetPageTransition.duration, const Duration(milliseconds: 300));
    expect(theme.bottomSheetPageTransition.builder, isNull);
    expect(theme.dialogPageTransition.duration, const Duration(milliseconds: 400));
    expect(theme.dialogPageTransition.builder, isNotNull);
  });

  testWidgets('shared-axis sequences opacity and uses directional motion', (
    tester,
  ) async {
    const transition = AdaptiveSheetPageTransition.sharedAxis();

    for (final progress in <double>[0, 0.25, 0.49, 0.5, 0.51, 0.75, 1]) {
      final outgoingOpacity = await _effectiveOpacity(
        tester,
        transition: transition,
        animationValue: 1,
        secondaryAnimationValue: progress,
      );
      final incomingOpacity = await _effectiveOpacity(
        tester,
        transition: transition,
        animationValue: progress,
        secondaryAnimationValue: 0,
      );

      expect(
        outgoingOpacity <= 1e-9 || incomingOpacity <= 1e-9,
        isTrue,
        reason: 'Both pages were visible at progress $progress.',
      );
    }

    final incomingTranslations = await _effectiveTranslations(
      tester,
      transition: transition,
      animationValue: 0.5,
      secondaryAnimationValue: 0,
    );
    final outgoingTranslations = await _effectiveTranslations(
      tester,
      transition: transition,
      animationValue: 1,
      secondaryAnimationValue: 0.5,
    );
    final incomingAtFadeStart = await _effectiveTranslations(
      tester,
      transition: transition,
      animationValue: 0.5,
      secondaryAnimationValue: 0,
    );
    final rtlIncomingTranslations = await _effectiveTranslations(
      tester,
      transition: transition,
      animationValue: 0.5,
      secondaryAnimationValue: 0,
      textDirection: TextDirection.rtl,
    );

    expect(incomingTranslations, contains(greaterThan(0)));
    expect(outgoingTranslations, contains(lessThan(0)));
    expect(incomingAtFadeStart, contains(closeTo(16, 1e-9)));
    expect(rtlIncomingTranslations, contains(lessThan(0)));
  });

  testWidgets('fade-through never shows incoming and outgoing pages together', (
    tester,
  ) async {
    const transition = AdaptiveSheetPageTransition.fadeThrough();

    for (final progress in <double>[0, 0.2, 0.39, 0.4, 0.41, 0.7, 1]) {
      final outgoingOpacity = await _effectiveOpacity(
        tester,
        transition: transition,
        animationValue: 1,
        secondaryAnimationValue: progress,
      );
      final incomingOpacity = await _effectiveOpacity(
        tester,
        transition: transition,
        animationValue: progress,
        secondaryAnimationValue: 0,
      );

      expect(
        outgoingOpacity <= 1e-9 || incomingOpacity <= 1e-9,
        isTrue,
        reason: 'Both pages were visible at progress $progress.',
      );
    }
  });

  testWidgets('dialog navigation uses subtle directional displacement', (
    tester,
  ) async {
    _configureView(tester, const Size(1200, 900));
    await _pumpTransitionHarness(tester);
    await _openSheet(tester);

    final first = find.byKey(const ValueKey('transition-first'));
    expect(tester.getCenter(first).dx, 600);

    await tester.tap(find.text('Push transition page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    final second = find.byKey(const ValueKey('transition-second'));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(tester.getCenter(first).dx, lessThan(600));
    expect(tester.getCenter(second).dx, greaterThan(600));
    expect(
      find.ancestor(of: second, matching: find.byType(SlideTransition)),
      findsNothing,
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Pop transition page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(tester.getCenter(first).dx, lessThan(600));
    expect(tester.getCenter(second).dx, greaterThan(600));
  });

  testWidgets('bottom-sheet pages delegate to the platform transition', (
    tester,
  ) async {
    _configureView(tester, const Size(500, 900));
    await _pumpTransitionHarness(
      tester,
      theme: _themeWithPlatformTransition(),
    );
    await _openSheet(tester);

    final first = find.byKey(const ValueKey('transition-first'));
    expect(
      find.ancestor(
        of: first,
        matching: find.byKey(const ValueKey('platform-page-transition')),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Push transition page'));
    await tester.pump(const Duration(milliseconds: 80));

    final second = find.byKey(const ValueKey('transition-second'));
    expect(
      find.ancestor(
        of: second,
        matching: find.byKey(const ValueKey('platform-page-transition')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('theme, config, and page transitions resolve in precedence order', (
    tester,
  ) async {
    _configureView(tester, const Size(1200, 900));
    await _pumpTransitionHarness(
      tester,
      sheetTheme: const AdaptiveSheetThemeData(
        dialogPageTransition: AdaptiveSheetPageTransition.custom(
          duration: Duration(milliseconds: 240),
          builder: _themeTransition,
        ),
      ),
      config: const AdaptiveSheetConfig(
        dialogPageTransition: AdaptiveSheetPageTransition.custom(
          duration: Duration(milliseconds: 180),
          builder: _configTransition,
        ),
      ),
      secondDialogTransition: const AdaptiveSheetPageTransition.custom(
        duration: Duration(milliseconds: 120),
        builder: _pageTransition,
      ),
    );
    await _openSheet(tester);

    final first = find.byKey(const ValueKey('transition-first'));
    expect(
      find.ancestor(
        of: first,
        matching: find.byKey(const ValueKey('config-transition')),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: first,
        matching: find.byKey(const ValueKey('theme-transition')),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Push transition page'));
    await tester.pump(const Duration(milliseconds: 40));

    final second = find.byKey(const ValueKey('transition-second'));
    expect(
      find.ancestor(
        of: second,
        matching: find.byKey(const ValueKey('page-transition')),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: second,
        matching: find.byKey(const ValueKey('config-transition')),
      ),
      findsNothing,
    );
  });

  testWidgets('theme transition applies when no closer override exists', (
    tester,
  ) async {
    _configureView(tester, const Size(1200, 900));
    await _pumpTransitionHarness(
      tester,
      sheetTheme: const AdaptiveSheetThemeData(
        dialogPageTransition: AdaptiveSheetPageTransition.custom(
          duration: Duration(milliseconds: 180),
          builder: _themeTransition,
        ),
      ),
    );
    await _openSheet(tester);

    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('transition-first')),
        matching: find.byKey(const ValueKey('theme-transition')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('none changes pages immediately and preserves state and results', (
    tester,
  ) async {
    _configureView(tester, const Size(1200, 900));
    await _pumpTransitionHarness(
      tester,
      config: const AdaptiveSheetConfig(
        dialogPageTransition: AdaptiveSheetPageTransition.none(),
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.text('Increment transition first'));
    await tester.tap(find.text('Push transition page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Transition second'), findsOneWidget);
    final pageRoute = ModalRoute.of(
      tester.element(find.byKey(const ValueKey('transition-second'))),
    )!;
    expect(pageRoute.animation!.value, 1);
    expect(pageRoute.animation!.status, AnimationStatus.completed);

    await tester.tap(find.text('Increment transition second'));
    await tester.pump();
    expect(find.text('transitionSecondCount:1'), findsOneWidget);
    await tester.tap(find.text('Pop transition page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('transitionFirstCount:1'), findsOneWidget);
    expect(find.text('transitionResult:done'), findsOneWidget);
  });

  testWidgets('custom builder drives forward and reverse animations', (
    tester,
  ) async {
    _configureView(tester, const Size(1200, 900));
    _recordedCustomStatuses.clear();
    await _pumpTransitionHarness(
      tester,
      secondDialogTransition: const AdaptiveSheetPageTransition.custom(
        duration: Duration(milliseconds: 200),
        builder: _recordingTransition,
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.text('Push transition page'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_recordedCustomStatuses, contains(AnimationStatus.forward));
    expect(
      find.byKey(const ValueKey('recording-transition')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    _recordedCustomStatuses.clear();
    await tester.tap(find.text('Pop transition page'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_recordedCustomStatuses, contains(AnimationStatus.reverse));
  });

  testWidgets('resizing selects the new presentation for later navigation', (
    tester,
  ) async {
    _configureView(tester, const Size(500, 900));
    await _pumpTransitionHarness(
      tester,
      theme: _themeWithPlatformTransition(),
    );
    await _openSheet(tester);

    final first = find.byKey(const ValueKey('transition-first'));
    expect(
      find.ancestor(
        of: first,
        matching: find.byKey(const ValueKey('platform-page-transition')),
      ),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Push transition page'));
    await tester.pump(const Duration(milliseconds: 70));
    final second = find.byKey(const ValueKey('transition-second'));
    expect(
      find.ancestor(
        of: second,
        matching: find.byKey(const ValueKey('platform-page-transition')),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(of: second, matching: find.byType(SlideTransition)),
      findsNothing,
    );
  });
}

Future<double> _effectiveOpacity(
  WidgetTester tester, {
  required AdaptiveSheetPageTransition transition,
  required double animationValue,
  required double secondaryAnimationValue,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (context) => transition.builder!(
          context,
          AlwaysStoppedAnimation(animationValue),
          AlwaysStoppedAnimation(secondaryAnimationValue),
          const SizedBox(key: ValueKey('opacity-probe'), width: 40, height: 40),
        ),
      ),
    ),
  );

  return tester.widgetList<FadeTransition>(find.byType(FadeTransition)).fold<double>(1, (opacity, fade) => opacity * fade.opacity.value);
}

Future<List<double>> _effectiveTranslations(
  WidgetTester tester, {
  required AdaptiveSheetPageTransition transition,
  required double animationValue,
  required double secondaryAnimationValue,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: textDirection,
      child: Builder(
        builder: (context) => transition.builder!(
          context,
          AlwaysStoppedAnimation(animationValue),
          AlwaysStoppedAnimation(secondaryAnimationValue),
          const SizedBox(key: ValueKey('translation-probe'), width: 40, height: 40),
        ),
      ),
    ),
  );

  return tester.widgetList<Transform>(find.byType(Transform)).map((transform) => transform.transform.getTranslation().x).toList();
}

void _configureView(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}

Future<void> _pumpTransitionHarness(
  WidgetTester tester, {
  ThemeData? theme,
  AdaptiveSheetThemeData? sheetTheme,
  AdaptiveSheetConfig config = const AdaptiveSheetConfig(),
  AdaptiveSheetPageTransition? secondBottomSheetTransition,
  AdaptiveSheetPageTransition? secondDialogTransition,
}) {
  return tester.pumpWidget(
    _TransitionHarness(
      theme: theme,
      sheetTheme: sheetTheme,
      config: config,
      secondBottomSheetTransition: secondBottomSheetTransition,
      secondDialogTransition: secondDialogTransition,
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open transitions'));
  await tester.pumpAndSettle();
}

ThemeData _themeWithPlatformTransition() {
  return ThemeData(
    platform: TargetPlatform.linux,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.linux: _MarkerPageTransitionsBuilder(),
      },
    ),
  );
}

class _TransitionHarness extends StatelessWidget {
  const _TransitionHarness({
    required this.theme,
    required this.sheetTheme,
    required this.config,
    required this.secondBottomSheetTransition,
    required this.secondDialogTransition,
  });

  final ThemeData? theme;
  final AdaptiveSheetThemeData? sheetTheme;
  final AdaptiveSheetConfig config;
  final AdaptiveSheetPageTransition? secondBottomSheetTransition;
  final AdaptiveSheetPageTransition? secondDialogTransition;

  @override
  Widget build(BuildContext context) {
    final baseTheme = theme ?? ThemeData();
    final appTheme = sheetTheme == null ? baseTheme : baseTheme.copyWith(extensions: [sheetTheme!]);

    return MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () {
              unawaited(
                showAdaptiveSheet<void>(
                  context: context,
                  config: config,
                  page: AdaptiveSheetPage<void>(
                    child: _TransitionFirstPage(
                      secondBottomSheetTransition: secondBottomSheetTransition,
                      secondDialogTransition: secondDialogTransition,
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open transitions'),
          ),
        ),
      ),
    );
  }
}

class _TransitionFirstPage extends StatefulWidget {
  const _TransitionFirstPage({
    required this.secondBottomSheetTransition,
    required this.secondDialogTransition,
  });

  final AdaptiveSheetPageTransition? secondBottomSheetTransition;
  final AdaptiveSheetPageTransition? secondDialogTransition;

  @override
  State<_TransitionFirstPage> createState() => _TransitionFirstPageState();
}

class _TransitionFirstPageState extends State<_TransitionFirstPage> {
  var _count = 0;
  String? _result;

  Future<void> _pushSecond() async {
    final result = await AdaptiveSheetNavigator.of(context).push<String>(
      AdaptiveSheetPage<String>(
        bottomSheetPageTransition: widget.secondBottomSheetTransition,
        dialogPageTransition: widget.secondDialogTransition,
        child: const _TransitionSecondPage(),
      ),
    );
    if (mounted) {
      setState(() => _result = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('transition-first'),
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Transition first'),
          Text('transitionFirstCount:$_count'),
          Text('transitionResult:${_result ?? 'none'}'),
          FilledButton(
            onPressed: () => setState(() => _count += 1),
            child: const Text('Increment transition first'),
          ),
          FilledButton(
            onPressed: () => unawaited(_pushSecond()),
            child: const Text('Push transition page'),
          ),
        ],
      ),
    );
  }
}

class _TransitionSecondPage extends StatefulWidget {
  const _TransitionSecondPage();

  @override
  State<_TransitionSecondPage> createState() => _TransitionSecondPageState();
}

class _TransitionSecondPageState extends State<_TransitionSecondPage> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('transition-second'),
      height: 360,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Transition second'),
          Text('transitionSecondCount:$_count'),
          FilledButton(
            onPressed: () => setState(() => _count += 1),
            child: const Text('Increment transition second'),
          ),
          FilledButton(
            onPressed: () => AdaptiveSheetNavigator.of(context).pop<String>('done'),
            child: const Text('Pop transition page'),
          ),
        ],
      ),
    );
  }
}

class _MarkerPageTransitionsBuilder extends PageTransitionsBuilder {
  const _MarkerPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return KeyedSubtree(
      key: const ValueKey('platform-page-transition'),
      child: ZoomPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    );
  }
}

Widget _themeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return KeyedSubtree(key: const ValueKey('theme-transition'), child: child);
}

Widget _configTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return KeyedSubtree(key: const ValueKey('config-transition'), child: child);
}

Widget _pageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return KeyedSubtree(key: const ValueKey('page-transition'), child: child);
}

final List<AnimationStatus> _recordedCustomStatuses = [];

Widget _recordingTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      _recordedCustomStatuses.add(animation.status);
      return KeyedSubtree(
        key: const ValueKey('recording-transition'),
        child: child!,
      );
    },
  );
}
