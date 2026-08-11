import 'dart:async';

import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'base_modal/base_modal.dart';

/// Runs the standard validation and submission flow for a form modal.
typedef FormModalSubmitAction = Future<void> Function();

/// Overrides the standard close-on-cancel behavior.
typedef FormModalCancelCallback = void Function(BuildContext context);

// TODO(brick): Convert this to HookConsumerWidget, keep submission state in a
// hook, and dispose formGroup from a useEffect keyed by formGroup.
/// Project template for a standard Reactive Forms modal.
///
/// Each modal instance owns [formGroup] and disposes it when removed. Create a
/// fresh modal for every presentation instead of reusing an instance.
abstract class FormModal extends StatefulWidget {
  /// Creates a form modal with project-default behavior.
  const FormModal({
    super.key,
    required this.formGroup,
    this.disableSubmitWhenInvalid = true,
    this.submitOnEnter = true,
    this.showCancelButton = true,
    this.closeOnSuccess = true,
    this.bodyPadding,
    this.showCloseButton = true,
    this.stackActionsOnBottomSheet = true,
    this.onCancel,
  });

  /// The shared form owned by this modal instance.
  final FormGroup formGroup;

  /// Whether an invalid form disables the standard submit action.
  ///
  /// When false, submission stays available but still touches and validates
  /// every control before [onSubmit] can run.
  final bool disableSubmitWhenInvalid;

  /// Whether Enter and numpad Enter submit from desktop single-line content.
  final bool submitOnEnter;

  /// Whether the standard footer includes its cancel action.
  final bool showCancelButton;

  /// Whether the adaptive sheet closes after [onSubmit] completes successfully.
  final bool closeOnSuccess;

  /// Padding for the standard single-child modal body.
  ///
  /// Null uses the project theme default. Set horizontal padding to zero for
  /// edge-to-edge content such as list tiles.
  final EdgeInsetsGeometry? bodyPadding;

  /// Whether the standard header includes its close action.
  final bool showCloseButton;

  /// Whether standard footer actions stack in bottom-sheet presentation.
  final bool stackActionsOnBottomSheet;

  /// Optional replacement for the standard close-on-cancel behavior.
  final FormModalCancelCallback? onCancel;

  /// Returns the modal title.
  String title(BuildContext context);

  /// Returns optional supporting text below [title].
  String? subtitle(BuildContext context) => null;

  // TODO(brick): Add WidgetRef here so implementations can watch providers.
  /// Builds the project-specific form content.
  ///
  /// The content is placed inside one shared [ReactiveForm] and the standard
  /// [BaseModalBody.singleChild] body.
  Widget buildFormContent(BuildContext context);

  // TODO(brick): Add WidgetRef here for provider-backed submission commands.
  /// Handles a valid submission.
  ///
  /// The standard submit action touches and validates [formGroup], manages the
  /// loading state, calls this method, and optionally closes the modal. A
  /// custom [buildModalFooter] must invoke its `submitForm` argument to enter
  /// that flow; otherwise this method is never called. Read submitted controls
  /// and values directly from [formGroup].
  Future<void> onSubmit(BuildContext context);

  // TODO(brick): Use the generated project localization as the default label.
  /// Returns the standard submit action label.
  String submitButtonLabel(BuildContext context) => 'Save';

  /// Returns the submit label shown while [onSubmit] is running.
  String submittingButtonLabel(BuildContext context) {
    return submitButtonLabel(context);
  }

  // TODO(brick): Use the generated project localization as the default label.
  /// Returns the standard cancel action label.
  String cancelButtonLabel(BuildContext context) => 'Cancel';

  /// Returns the icon shown by the standard submit action when idle.
  Widget? submitButtonIcon(BuildContext context) {
    return const Icon(Icons.save_outlined);
  }

  /// Builds optional actions placed before the standard header close button.
  @protected
  List<Widget> buildHeaderActions(BuildContext context) => const [];

  /// Builds the modal body around already prepared form [content].
  ///
  /// Override this for a different [BaseModalBody] strategy. Keep [content] in
  /// the returned body to preserve [buildFormContent] and Enter submission.
  @protected
  BaseModalBody buildModalBody(BuildContext context, Widget content) {
    return BaseModalBody.singleChild(
      padding: bodyPadding,
      child: content,
    );
  }

  /// Builds the fixed form footer.
  ///
  /// Overriding this replaces all standard footer actions, so constructor
  /// options such as [showCancelButton] no longer affect them. Wire
  /// [submitForm] to the custom submit action to retain validation, loading,
  /// [onSubmit], and close-on-success behavior. [submitForm] is null while
  /// submitting and, when configured, while the form is invalid.
  @protected
  Widget buildModalFooter(
    BuildContext context, {
    required FormModalSubmitAction? submitForm,
    required bool isSubmitting,
  }) {
    // TODO(brick): Replace the Material actions and manual progress indicator
    // with CustomButton's outlined/filled and loading-state conventions.
    final icon = isSubmitting
        ? const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : submitButtonIcon(context);
    final label = Text(
      isSubmitting ? submittingButtonLabel(context) : submitButtonLabel(context),
    );

    return BaseModalFooter(
      stackOnBottomSheet: stackActionsOnBottomSheet,
      actions: [
        if (showCancelButton)
          OutlinedButton(
            onPressed: isSubmitting ? null : () => _cancel(context),
            child: Text(cancelButtonLabel(context)),
          ),
        if (icon == null)
          FilledButton(onPressed: submitForm, child: label)
        else
          FilledButton.icon(
            onPressed: submitForm,
            icon: icon,
            label: label,
          ),
      ],
    );
  }

  /// Shows this modal as the first page of a new adaptive sheet.
  ///
  /// Create a new modal instance for each call because the route disposes its
  /// owned [formGroup] when it closes.
  Future<void> show(BuildContext context) {
    return showAdaptiveSheet<void>(
      context: context,
      page: AdaptiveSheetPage<void>(child: this),
    );
  }

  void _cancel(BuildContext context) {
    final callback = onCancel;
    if (callback != null) {
      callback(context);
      return;
    }
    AdaptiveSheetNavigator.of(context).close();
  }

  @override
  @nonVirtual
  State<FormModal> createState() => _FormModalState();
}

class _FormModalState extends State<FormModal> {
  // TODO(brick): Replace this State object with useState in HookConsumerWidget.
  var _isSubmitting = false;

  bool get _canSubmit {
    return !_isSubmitting && (!widget.disableSubmitWhenInvalid || widget.formGroup.valid);
  }

  @override
  void didUpdateWidget(FormModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.formGroup, widget.formGroup)) {
      oldWidget.formGroup.dispose();
    }
  }

  @override
  void dispose() {
    widget.formGroup.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final formGroup = widget.formGroup;
    formGroup.markAllAsTouched();
    if (!formGroup.valid) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(context);
      if (mounted && widget.closeOnSuccess) {
        AdaptiveSheetNavigator.of(context).close();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.buildFormContent(context);
    if (widget.submitOnEnter && _supportsEnterSubmission(context)) {
      content = _EnterSubmission(
        canSubmit: () => _canSubmit,
        submit: _submit,
        child: content,
      );
    }

    return ReactiveForm(
      formGroup: widget.formGroup,
      child: BaseModal(
        title: widget.title(context),
        subtitle: widget.subtitle(context),
        headerActions: widget.buildHeaderActions(context),
        showCloseButton: widget.showCloseButton,
        body: widget.buildModalBody(context, content),
        footer: ReactiveFormConsumer(
          builder: (context, form, child) {
            return widget.buildModalFooter(
              context,
              submitForm: _canSubmit ? _submit : null,
              isSubmitting: _isSubmitting,
            );
          },
        ),
      ),
    );
  }
}

bool _supportsEnterSubmission(BuildContext context) {
  return switch (Theme.of(context).platform) {
    TargetPlatform.linux || TargetPlatform.macOS || TargetPlatform.windows => true,
    _ => false,
  };
}

class _SubmitFormIntent extends Intent {
  const _SubmitFormIntent();
}

class _EnterSubmission extends StatelessWidget {
  const _EnterSubmission({
    required this.canSubmit,
    required this.submit,
    required this.child,
  });

  final bool Function() canSubmit;
  final FormModalSubmitAction submit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _SubmitFormIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _SubmitFormIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SubmitFormIntent: CallbackAction<_SubmitFormIntent>(
            onInvoke: (intent) {
              if (!canSubmit() || _focusedEditableIsMultiline()) {
                return null;
              }
              return submit();
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

bool _focusedEditableIsMultiline() {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) {
    return false;
  }
  final focusedWidget = focusContext.widget;
  final editableText = focusedWidget is EditableText ? focusedWidget : focusContext.findAncestorWidgetOfExactType<EditableText>();
  return editableText != null && editableText.maxLines != 1;
}
