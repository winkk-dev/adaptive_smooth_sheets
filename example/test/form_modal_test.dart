import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:example/modals/base_modal/base_modal.dart';
import 'package:example/modals/form_modal.dart';
import 'package:example/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

void main() {
  testWidgets('body and footer share one form and invalid submit is disabled', (
    tester,
  ) async {
    final form = FormGroup({
      'name': FormControl<String>(validators: [Validators.required]),
    });
    Object? bodyForm;
    await _pumpFormModal(
      tester,
      modal: _TestFormModal(
        formGroup: form,
        content: Builder(
          builder: (context) {
            bodyForm = ReactiveForm.of(context);
            return ReactiveTextField<String>(formControlName: 'name');
          },
        ),
        submit: (context) async {},
      ),
    );

    final footerForm = ReactiveForm.of(
      tester.element(find.byType(ReactiveFormConsumer)),
    );
    expect(bodyForm, same(footerForm));
    expect(footerForm, same(form));
    expect(_submitButton(tester, 'Save').onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pump();

    expect(_submitButton(tester, 'Save').onPressed, isNotNull);
  });

  testWidgets('invalid submit can stay enabled and validates before callback', (
    tester,
  ) async {
    final form = FormGroup({
      'name': FormControl<String>(validators: [Validators.required]),
    });
    var submitCount = 0;
    await _pumpFormModal(
      tester,
      modal: _TestFormModal(
        formGroup: form,
        disableSubmitWhenInvalid: false,
        closeOnSuccess: false,
        content: ReactiveTextField<String>(formControlName: 'name'),
        submit: (context) async => submitCount += 1,
      ),
    );

    expect(_submitButton(tester, 'Save').onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(form.control('name').touched, isTrue);
    expect(submitCount, 0);
  });

  testWidgets('valid submission can read current form values and closes', (
    tester,
  ) async {
    final form = FormGroup({
      'name': FormControl<String>(
        value: 'Before',
        validators: [Validators.required],
      ),
      'teamSize': FormControl<int>(value: 3),
    });
    Map<String, Object?>? submittedValues;
    bool? touchedDuringSubmit;
    await _pumpFormModal(
      tester,
      modal: _TestFormModal(
        formGroup: form,
        content: ReactiveTextField<String>(formControlName: 'name'),
        submit: (context) async {
          touchedDuringSubmit = form.control('name').touched;
          submittedValues = Map<String, Object?>.of(form.value);
        },
      ),
    );

    await tester.enterText(find.byType(TextField), 'After');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(touchedDuringSubmit, isTrue);
    expect(submittedValues, {'name': 'After', 'teamSize': 3});
    expect(find.text('Test form'), findsNothing);
  });

  testWidgets('async submission shows loading and prevents more actions', (
    tester,
  ) async {
    final submission = Completer<void>();
    var submitCount = 0;
    await _pumpFormModal(
      tester,
      modal: _TestFormModal(
        formGroup: FormGroup({
          'name': FormControl<String>(value: 'Ada'),
        }),
        content: ReactiveTextField<String>(formControlName: 'name'),
        submit: (context) {
          submitCount += 1;
          return submission.future;
        },
        submittingLabel: 'Saving',
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(submitCount, 1);
    expect(find.widgetWithText(FilledButton, 'Saving'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_submitButton(tester, 'Saving').onPressed, isNull);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Cancel'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Saving'));
    await tester.pump();
    expect(submitCount, 1);

    submission.complete();
    await tester.pumpAndSettle();
    expect(find.text('Test form'), findsNothing);
  });

  testWidgets('custom footer can retain the standard submission flow', (
    tester,
  ) async {
    var submitCount = 0;
    await _pumpFormModal(
      tester,
      modal: _TestFormModal(
        formGroup: FormGroup({
          'name': FormControl<String>(value: 'Ada'),
        }),
        closeOnSuccess: false,
        content: ReactiveTextField<String>(formControlName: 'name'),
        submit: (context) async => submitCount += 1,
        footerBuilder: (context, submitForm, isSubmitting) {
          return BaseModalFooter(
            actions: [
              FilledButton(
                onPressed: submitForm,
                child: const Text('Custom save'),
              ),
            ],
          );
        },
      ),
    );

    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Save'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Custom save'));
    await tester.pump();

    expect(submitCount, 1);
  });

  testWidgets('desktop Enter submits but multiline Enter does not', (
    tester,
  ) async {
    var submitCount = 0;
    await _pumpFormModal(
      tester,
      platform: TargetPlatform.macOS,
      modal: _TestFormModal(
        formGroup: FormGroup({
          'name': FormControl<String>(value: 'Ada'),
          'notes': FormControl<String>(),
        }),
        closeOnSuccess: false,
        content: Column(
          children: [
            ReactiveTextField<String>(
              key: const ValueKey('single-line'),
              formControlName: 'name',
            ),
            ReactiveTextField<String>(
              key: const ValueKey('multiline'),
              formControlName: 'notes',
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
        submit: (context) async => submitCount += 1,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('single-line')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(submitCount, 1);

    await tester.tap(find.byKey(const ValueKey('multiline')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(submitCount, 1);
  });

  testWidgets('desktop Enter submission can be disabled', (tester) async {
    var submitCount = 0;
    await _pumpFormModal(
      tester,
      platform: TargetPlatform.macOS,
      modal: _TestFormModal(
        formGroup: FormGroup({
          'name': FormControl<String>(value: 'Ada'),
        }),
        submitOnEnter: false,
        closeOnSuccess: false,
        content: ReactiveTextField<String>(formControlName: 'name'),
        submit: (context) async => submitCount += 1,
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(submitCount, 0);
  });

  testWidgets('Enter does not submit on mobile platforms', (tester) async {
    var submitCount = 0;
    await _pumpFormModal(
      tester,
      modal: _TestFormModal(
        formGroup: FormGroup({
          'name': FormControl<String>(value: 'Ada'),
        }),
        closeOnSuccess: false,
        content: ReactiveTextField<String>(formControlName: 'name'),
        submit: (context) async => submitCount += 1,
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(submitCount, 0);
  });

  testWidgets('body padding and form state survive adaptive presentation', (
    tester,
  ) async {
    final form = FormGroup({
      'name': FormControl<String>(validators: [Validators.required]),
    });
    await _pumpFormModal(
      tester,
      modal: _TestFormModal(
        formGroup: form,
        bodyPadding: EdgeInsets.zero,
        content: ReactiveTextField<String>(formControlName: 'name'),
        submit: (context) async {},
      ),
    );

    AdaptiveSheetPresentation presentation() {
      return AdaptiveSheetScope.of(
        tester.element(find.byType(_TestFormModal)),
      ).presentation;
    }

    expect(presentation(), AdaptiveSheetPresentation.bottomSheet);
    expect(find.byKey(baseModalDragHandleKey), findsOneWidget);
    expect(
      tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).padding,
      EdgeInsets.zero,
    );

    await tester.enterText(find.byType(TextField), 'Persistent value');
    await tester.pump();
    expect(_submitButton(tester, 'Save').onPressed, isNotNull);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(presentation(), AdaptiveSheetPresentation.dialog);
    expect(find.byKey(baseModalDragHandleKey), findsNothing);
    expect(form.control('name').value, 'Persistent value');
    expect(_submitButton(tester, 'Save').onPressed, isNotNull);
  });
}

typedef _SubmitCallback = Future<void> Function(BuildContext context);

typedef _FooterBuilder =
    Widget Function(
      BuildContext context,
      FormModalSubmitAction? submitForm,
      bool isSubmitting,
    );

class _TestFormModal extends FormModal {
  const _TestFormModal({
    required super.formGroup,
    required this.content,
    required this.submit,
    super.disableSubmitWhenInvalid,
    super.submitOnEnter,
    super.closeOnSuccess,
    super.bodyPadding,
    this.submittingLabel,
    this.footerBuilder,
  });

  final Widget content;
  final _SubmitCallback submit;
  final String? submittingLabel;
  final _FooterBuilder? footerBuilder;

  @override
  String title(BuildContext context) => 'Test form';

  @override
  Widget buildFormContent(BuildContext context) => content;

  @override
  Future<void> onSubmit(BuildContext context) {
    return submit(context);
  }

  @override
  String submittingButtonLabel(BuildContext context) {
    return submittingLabel ?? super.submittingButtonLabel(context);
  }

  @override
  Widget buildModalFooter(
    BuildContext context, {
    required FormModalSubmitAction? submitForm,
    required bool isSubmitting,
  }) {
    final builder = footerBuilder;
    if (builder == null) {
      return super.buildModalFooter(
        context,
        submitForm: submitForm,
        isSubmitting: isSubmitting,
      );
    }
    return builder(context, submitForm, isSubmitting);
  }
}

FilledButton _submitButton(WidgetTester tester, String label) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, label),
  );
}

Future<void> _pumpFormModal(
  WidgetTester tester, {
  required FormModal modal,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  _configureView(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light.copyWith(platform: platform),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => unawaited(modal.show(context)),
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

void _configureView(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(500, 800);
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}
