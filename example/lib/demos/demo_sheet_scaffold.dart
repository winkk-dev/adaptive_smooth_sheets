import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

/// Example-only modal chrome composed from public package primitives.
///
/// Applications can replace this widget entirely with their own header, footer,
/// and styling. It exists here to keep each demo focused on one package API.
class DemoSheetScaffold extends StatelessWidget {
  /// Creates a demo sheet with a fixed header and optional action footer.
  const DemoSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
  });

  /// The label displayed in the fixed header.
  final String title;

  /// Optional supporting text below [title].
  final String? subtitle;

  /// The primary modal content.
  final Widget body;

  /// Widgets displayed in a fixed footer.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final presentation = AdaptiveSheetScope.of(context).presentation;
    final sheetNavigator = AdaptiveSheetNavigator.of(context);
    final presentationLabel = switch (presentation) {
      AdaptiveSheetPresentation.bottomSheet => 'Bottom sheet',
      AdaptiveSheetPresentation.dialog => 'Dialog',
    };

    return AdaptiveSheetScaffold(
      topBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (sheetNavigator.canPop)
                IconButton(
                  onPressed: () => sheetNavigator.pop<void>(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: sheetNavigator.canPop ? 4 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        presentation == AdaptiveSheetPresentation.bottomSheet ? Icons.vertical_align_bottom_outlined : Icons.web_asset_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        presentationLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => sheetNavigator.close<void>(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
      body: body,
      bottomBar: actions.isEmpty
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: actions,
                  ),
                ),
              ),
            ),
    );
  }
}
