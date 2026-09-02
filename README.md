# Adaptive Smooth Sheets

Adaptive Smooth Sheets extends
[`smooth_sheets`](https://pub.dev/packages/smooth_sheets) with the responsive
presentation behavior familiar from
[`wolt_modal_sheet`](https://pub.dev/packages/wolt_modal_sheet). The same modal
appears as a draggable bottom sheet on compact screens and as a centered dialog
on larger screens.

`smooth_sheets` provides the underlying sheet, scrolling, and navigation
behavior. This package adds the screen-size adaptation that `smooth_sheets`
does not provide on its own—combining its flexible foundation with a responsive
bottom-sheet-to-dialog experience.

An already-open modal switches presentation live when the window crosses its
configured breakpoint, without recreating its page, form, or scroll state.

## Install

```sh
flutter pub add adaptive_smooth_sheets
```

Then import the package's single public entry point:

```dart
import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
```

## First adaptive modal

Register optional application-wide defaults in `ThemeData.extensions`, then
open a modal with `showAdaptiveSheet`.

```dart
import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
import 'package:flutter/material.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        extensions: const [
          AdaptiveSheetThemeData(
            dialogBreakpoint: 720,
            dialogWidth: 640,
          ),
        ],
      ),
      home: Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => showAdaptiveSheet<void>(
              context: context,
              page: const AdaptiveSheetPage<void>(
                child: _AccountSheet(),
              ),
            ),
            child: const Text('Edit account'),
          ),
        ),
      ),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final presentation = AdaptiveSheetScope.of(context).presentation;

    return AdaptiveSheetScaffold(
      topBar: const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Text('Edit account'),
      ),
      body: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              presentation == AdaptiveSheetPresentation.bottomSheet
                  ? 'Bottom-sheet presentation'
                  : 'Dialog presentation',
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Display name'),
            ),
          ],
        ),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => AdaptiveSheetNavigator.of(context).close(),
          child: const Text('Save'),
        ),
      ),
    );
  }
}
```

Resize the app window while the modal is open. The presentation label changes,
but the `TextField` and the modal page remain mounted.

## What the package owns

- Responsive bottom-sheet and dialog presentation, including live resizing.
- Route geometry, barriers, safe areas, keyboard avoidance, dragging, and
  mouse-drag support.
- A primary `AdaptiveSheetScrollController` that bridges scrolling and sheet
  dragging in bottom-sheet presentation.
- An internal, typed page stack through `AdaptiveSheetPage` and
  `AdaptiveSheetNavigator`.
- Presentation-aware configuration through `AdaptiveSheetScope`, global
  `AdaptiveSheetThemeData`, and per-route `AdaptiveSheetConfig`.

Headers, footers, buttons, forms, tabs, and application-specific styling are
deliberately consumer concerns. Compose them with `AdaptiveSheetScaffold` or
with your own widgets.

## Configuration

Use `AdaptiveSheetThemeData` for application defaults. A route can override
only the values it needs with `AdaptiveSheetConfig`.

```dart
await showAdaptiveSheet<void>(
  context: context,
  config: const AdaptiveSheetConfig(
    dialogWidth: 560,
    dialogMaxHeight: 720,
    enableMouseDrag: false,
    bottomSheetPhysics: BouncingSheetPhysics(),
  ),
  page: AdaptiveSheetPage<void>(child: SettingsSheet()),
);
```

The default bottom-sheet physics are `ClampingSheetPhysics`, so a sheet cannot
be dragged beyond its bounds. Use `BouncingSheetPhysics` when elastic overdrag
fits the application.

`AdaptiveSheetPresentationPolicy` can override the breakpoint for one route or
use a custom resolver when width alone is not enough. For example, this policy
uses a dialog only for sufficiently wide landscape windows:

```dart
final config = AdaptiveSheetConfig(
  presentationPolicy: AdaptiveSheetPresentationPolicy(
    resolver: (context) {
      final mediaQuery = MediaQuery.of(context);
      final useDialog = mediaQuery.orientation == Orientation.landscape &&
          mediaQuery.size.width > 840;

      return useDialog
          ? AdaptiveSheetPresentation.dialog
          : AdaptiveSheetPresentation.bottomSheet;
    },
  ),
);
```

A resolver takes precedence over `dialogBreakpoint`. Reading `MediaQuery` from
its context also makes an already-open route react to subsequent window-size or
orientation changes.

## Navigation inside a modal

`AdaptiveSheetNavigator` keeps page navigation separate from closing the outer
modal:

```dart
final sheetNavigator = AdaptiveSheetNavigator.of(context);

await sheetNavigator.push<void>(
  const AdaptiveSheetPage<void>(child: DetailsSheet()),
);

sheetNavigator.pop(); // Pops one internal page when possible.

// Replaces the current page while retaining earlier pages.
await sheetNavigator.replace<void, void>(
  const AdaptiveSheetPage<void>(child: ReviewSheet()),
);

// Replaces the complete stack and creates a new root page.
await sheetNavigator.replaceAll<void>(
  const AdaptiveSheetPage<void>(child: SuccessSheet()),
);

sheetNavigator.close(); // Closes the complete adaptive modal.
```

Page, route, and theme transitions are independently configurable with
`AdaptiveSheetPageTransition`.

On native platforms, the system Back action—such as Android's hardware or
software Back button, or the equivalent platform back gesture—pops the current
internal page first. When the first page is already visible, it closes the modal
by default. Override that policy with `AdaptiveSheetNativeBackBehavior` when
needed.

## Scrolling and dismissal guards

Every `AdaptiveSheetPage` supplies an `AdaptiveSheetScrollController` as its
primary vertical controller. Ordinary primary `ListView` and
`SingleChildScrollView` widgets inherit it automatically. Retrieve it only when
an action needs programmatic scrolling:

```dart
await AdaptiveSheetScrollController.of(context).animateTo(
  600,
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeOut,
);
```

Use `AdaptiveSheetPopScope` to guard outer-modal dismissal, including a barrier
tap, Escape, and a swipe-to-dismiss gesture:

```dart
AdaptiveSheetPopScope<void>(
  canPop: formIsSaved,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
      showDiscardChangesMessage();
    }
  },
  child: const EditProfileSheet(),
)
```

## Example app

Run the included [example](example/) to see the public API in focused demos:

- a minimal adaptive modal;
- primary scrolling and sheet-drag handoff;
- live resize while local widget state is preserved;
- internal page navigation, `replace`, and `replaceAll`;
- guarded dismissal; and
- a route-specific breakpoint and geometry overrides.

```sh
cd example
flutter run
```

## Screenshots

When you create the first media asset, add it under
`screenshots/adaptive-resize.webp` at the package root. Put the rendered image
immediately below this section, then add this metadata to `pubspec.yaml`:

```yaml
screenshots:
  - description: 'An open modal preserves its form state while resizing between a bottom sheet and dialog.'
    path: screenshots/adaptive-resize.webp
```

Use this as the first screenshot so pub.dev uses it as the package thumbnail.
Keep it below 4 MB. A second static desktop screenshot can sit alongside it as
`screenshots/adaptive-dialog.png`.

## Web browser Back

Adaptive-sheet pages use a nested Flutter `Navigator`; they are not browser
history entries. Browser Back cannot reliably unwind those pages in an
imperative Flutter web app. Provide visible Back and Close controls inside the
modal, or model browser-history-aware steps in the root Router.
