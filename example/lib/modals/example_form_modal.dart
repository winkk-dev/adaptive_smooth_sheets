import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'base_modal.dart';

/// Shows the directly composed Reactive Forms example.
///
/// A reusable abstract form-modal API is deliberately deferred to the later
/// “Simplify forms and tabs” task.
Future<void> showExampleFormModal(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    page: const AdaptiveSheetPage<void>(child: ExampleFormModal()),
  );
}

/// A long, keyboard-aware form whose model is shared by body and footer.
class ExampleFormModal extends StatefulWidget {
  /// Creates the example form modal.
  const ExampleFormModal({super.key});

  @override
  State<ExampleFormModal> createState() => _ExampleFormModalState();
}

class _ExampleFormModalState extends State<ExampleFormModal> {
  late final FormGroup _form;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'projectName': FormControl<String>(
        validators: [Validators.required, Validators.minLength(3)],
      ),
      'projectCode': FormControl<String>(
        validators: [Validators.required, Validators.minLength(2)],
      ),
      'ownerEmail': FormControl<String>(
        validators: [Validators.required, Validators.email],
      ),
      'teamSize': FormControl<int>(
        value: 3,
        validators: [Validators.required, Validators.min(1)],
      ),
      'monthlyBudgetK': FormControl<int>(
        value: 15,
        validators: [Validators.required, Validators.min(1)],
      ),
      'projectType': FormControl<String>(validators: [Validators.required]),
      'summary': FormControl<String>(
        validators: [Validators.required, Validators.maxLength(240)],
      ),
      'confidence': FormControl<double>(value: 3),
      'sendUpdates': FormControl<bool>(value: true),
      'acceptReview': FormControl<bool>(
        value: false,
        validators: [Validators.requiredTrue],
      ),
      'successTarget': FormControl<int>(
        value: 1000,
        validators: [Validators.required, Validators.min(1)],
      ),
      'supportContact': FormControl<String>(validators: [Validators.email]),
      'followUpNotes': FormControl<String>(),
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _form.markAllAsTouched();
    if (_form.invalid || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    AdaptiveSheetNavigator.of(context).close();
    messenger.showSnackBar(
      const SnackBar(content: Text('Project brief saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: _form,
      child: BaseModal(
        title: 'Project brief',
        subtitle: 'Reactive form state spans body and footer',
        body: BaseModalBody.scrollable(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReactiveTextField<String>(
                formControlName: 'projectName',
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Project name',
                  prefixIcon: Icon(Icons.rocket_launch_outlined),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => 'A name is required.',
                  ValidationMessage.minLength: (_) => 'Use at least three characters.',
                },
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'projectCode',
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Project code',
                  hintText: 'For example, MKT-241',
                  prefixIcon: Icon(Icons.tag_outlined),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => 'A code is required.',
                  ValidationMessage.minLength: (_) => 'Use at least two characters.',
                },
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'ownerEmail',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Owner email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => 'An email is required.',
                  ValidationMessage.email: (_) => 'Enter a valid email.',
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ReactiveTextField<int>(
                      formControlName: 'teamSize',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Team size',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      validationMessages: {
                        ValidationMessage.required: (_) => 'Enter the team size.',
                        ValidationMessage.min: (_) => 'At least one person is required.',
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReactiveTextField<int>(
                      formControlName: 'monthlyBudgetK',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Budget (€k)',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validationMessages: {
                        ValidationMessage.required: (_) => 'Enter the monthly budget.',
                        ValidationMessage.min: (_) => 'Use a value greater than zero.',
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ReactiveDropdownField<String>(
                formControlName: 'projectType',
                decoration: const InputDecoration(
                  labelText: 'Project type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'mobile',
                    child: Text('Mobile application'),
                  ),
                  DropdownMenuItem(
                    value: 'web',
                    child: Text('Web application'),
                  ),
                  DropdownMenuItem(
                    value: 'service',
                    child: Text('Internal service'),
                  ),
                ],
                validationMessages: {
                  ValidationMessage.required: (_) => 'Choose a project type.',
                },
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'summary',
                minLines: 4,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Success summary',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => 'Add a short summary.',
                  ValidationMessage.maxLength: (_) => 'Keep the summary under 240 characters.',
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Delivery confidence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ReactiveValueListenableBuilder<double>(
                formControlName: 'confidence',
                builder: (context, control, child) {
                  final value = control.value ?? 3;
                  return Text('${value.toStringAsFixed(0)} of 5');
                },
              ),
              ReactiveSlider(
                formControlName: 'confidence',
                min: 1,
                max: 5,
                divisions: 4,
                labelBuilder: (value) => value.toStringAsFixed(0),
              ),
              ReactiveSwitchListTile(
                formControlName: 'sendUpdates',
                contentPadding: EdgeInsets.zero,
                title: const Text('Send weekly progress updates'),
              ),
              ReactiveCheckboxListTile(
                formControlName: 'acceptReview',
                contentPadding: EdgeInsets.zero,
                title: const Text('I will review the generated project plan'),
              ),
              const SizedBox(height: 24),
              Text(
                'After approval',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              ReactiveTextField<int>(
                formControlName: 'successTarget',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'First-month success target',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => 'Enter a target.',
                  ValidationMessage.min: (_) => 'Use a value greater than zero.',
                },
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'supportContact',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Support contact',
                  hintText: 'Optional email address',
                  prefixIcon: Icon(Icons.support_agent_outlined),
                ),
                validationMessages: {
                  ValidationMessage.email: (_) => 'Enter a valid email.',
                },
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'followUpNotes',
                minLines: 3,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Follow-up notes',
                  hintText: 'Optional hand-off details for the team',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                ),
              ),
            ],
          ),
        ),
        footer: BaseModalFooter(
          actions: [
            OutlinedButton(
              onPressed: _isSubmitting ? null : AdaptiveSheetNavigator.of(context).close,
              child: const Text('Cancel'),
            ),
            ReactiveFormConsumer(
              builder: (context, form, child) {
                return FilledButton.icon(
                  onPressed: form.valid && !_isSubmitting ? _submit : null,
                  icon: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSubmitting ? 'Saving' : 'Save brief'),
                );
              },
            ),
          ],
          stackOnBottomSheet: true,
        ),
      ),
    );
  }
}
