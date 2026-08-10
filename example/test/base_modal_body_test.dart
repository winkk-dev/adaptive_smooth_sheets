import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:example/modals/base_modal.dart';
import 'package:example/modals/base_modal_theme.dart';
import 'package:example/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('singleChild owns one eager scroll view with project defaults', (
    tester,
  ) async {
    await _pumpModal(
      tester,
      body: const BaseModalBody.singleChild(
        child: SizedBox(key: ValueKey('short-content'), height: 80),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.padding, BaseModalThemeData.of(tester.element(find.byType(SingleChildScrollView))).bodyPadding);
    expect(
      scrollView.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(CustomScrollView), findsNothing);
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).height,
      lessThan(300),
    );
  });

  testWidgets('list is lazy, supports separators, and fills the body viewport', (
    tester,
  ) async {
    var buildCount = 0;
    await _pumpModal(
      tester,
      footer: const _TestFooter(),
      body: BaseModalBody.list(
        itemCount: 500,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          buildCount += 1;
          return SizedBox(height: 56, child: Text('row $index'));
        },
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(Divider), findsWidgets);
    expect(buildCount, lessThan(500));
    expect(find.text('row 499'), findsNothing);
    expect(
      tester.getSize(find.byType(ListView)).height,
      greaterThan(300),
    );
  });

  testWidgets('slivers stay lazy inside one padded custom scroll view', (
    tester,
  ) async {
    var buildCount = 0;
    const padding = EdgeInsets.fromLTRB(11, 12, 13, 14);
    await _pumpModal(
      tester,
      body: BaseModalBody.slivers(
        padding: padding,
        slivers: [
          const SliverToBoxAdapter(child: Text('summary')),
          SliverList.builder(
            itemCount: 500,
            itemBuilder: (context, index) {
              buildCount += 1;
              return SizedBox(height: 56, child: Text('sliver $index'));
            },
          ),
        ],
      ),
    );

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverMainAxisGroup), findsOneWidget);
    expect(tester.widget<SliverPadding>(find.byType(SliverPadding)).padding, padding);
    expect(buildCount, lessThan(500));
    expect(find.text('sliver 499'), findsNothing);
  });

  testWidgets('custom leaves layout and scrolling to its child', (tester) async {
    await _pumpModal(
      tester,
      body: const BaseModalBody.custom(
        child: SizedBox(key: ValueKey('custom-body'), height: 96),
      ),
    );

    expect(find.byKey(const ValueKey('custom-body')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(CustomScrollView), findsNothing);
  });

  testWidgets('footer fade only shows while content remains below', (
    tester,
  ) async {
    await _pumpModal(
      tester,
      footer: const _TestFooter(),
      body: BaseModalBody.list(
        itemCount: 100,
        itemBuilder: (context, index) => SizedBox(
          height: 56,
          child: Text('overflow row $index'),
        ),
      ),
    );

    AnimatedOpacity gradient() => tester.widget<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );

    expect(gradient().opacity, 1);

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(gradient().opacity, 0);
  });

  testWidgets('footer keeps the full dialog width', (tester) async {
    await _pumpModal(
      tester,
      size: const Size(1200, 800),
      footer: const _TestFooter(),
      body: const BaseModalBody.singleChild(
        child: SizedBox(height: 80),
      ),
    );

    expect(
      tester.getSize(find.byType(BaseModalFooter)).width,
      tester.getSize(find.byType(BaseModalHeader)).width,
    );
  });

  testWidgets(
    'managed bodies inherit coordinated scrolling on desktop and keep offset across resize',
    (tester) async {
      await _pumpModal(
        tester,
        platform: TargetPlatform.macOS,
        body: BaseModalBody.list(
          key: const PageStorageKey('resize-list'),
          itemCount: 100,
          itemBuilder: (context, index) => SizedBox(
            height: 56,
            child: Text('resize row $index'),
          ),
        ),
      );

      ScrollableState scrollableState() => tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );

      final listContext = tester.element(find.byType(ListView));
      final primaryController = PrimaryScrollController.of(listContext);
      expect(
        AdaptiveSheetScrollController.of(listContext),
        same(primaryController),
      );
      expect(primaryController.positions, contains(scrollableState().position));

      scrollableState().position.jumpTo(320);
      await tester.pump();
      expect(scrollableState().position.pixels, 320);

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();
      expect(scrollableState().position.pixels, 320);

      tester.view.physicalSize = const Size(500, 800);
      await tester.pumpAndSettle();
      expect(scrollableState().position.pixels, 320);
    },
  );

  testWidgets('managed scrolling dismisses the keyboard on drag', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pumpModal(
      tester,
      body: BaseModalBody.singleChild(
        child: Column(
          children: [
            TextField(focusNode: focusNode),
            const SizedBox(height: 900),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('singleChild keeps a focused field above the keyboard', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pumpModal(
      tester,
      body: BaseModalBody.singleChild(
        child: Column(
          children: [
            const SizedBox(height: 700),
            TextField(
              key: const ValueKey('bottom-field'),
              focusNode: focusNode,
            ),
          ],
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isTrue);
    expect(
      tester.getRect(find.byKey(const ValueKey('bottom-field'))).bottom,
      lessThanOrEqualTo(500),
    );
  });
}

Future<void> _pumpModal(
  WidgetTester tester, {
  required BaseModalBody body,
  Widget? footer,
  TargetPlatform platform = TargetPlatform.android,
  Size size = const Size(500, 800),
}) async {
  _configureView(tester, size: size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light.copyWith(platform: platform),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () {
                unawaited(
                  showAdaptiveSheet<void>(
                    context: context,
                    page: AdaptiveSheetPage<void>(
                      child: BaseModal(
                        title: 'Body test',
                        body: body,
                        footer: footer,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void _configureView(
  WidgetTester tester, {
  Size size = const Size(500, 800),
}) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio()
      ..resetViewInsets();
  });
}

class _TestFooter extends StatelessWidget {
  const _TestFooter();

  @override
  Widget build(BuildContext context) {
    return const BaseModalFooter(
      actions: [SizedBox(width: 80, height: 40)],
    );
  }
}
