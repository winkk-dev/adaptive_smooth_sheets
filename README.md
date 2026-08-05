# Adaptive Smooth Sheets

A small Flutter layer on top of `smooth_sheets` that presents modal content as
a bottom sheet on narrow windows and a centered dialog on wide windows.
Already-open routes adapt when the window is resized while preserving the
content element and its widget, form, and scroll state.

## Features

- Live bottom-sheet/dialog switching with a configurable breakpoint or custom
  resolver.
- Global Flutter `ThemeExtension` defaults and focused per-route overrides.
- Configurable dialog geometry, surface styling, barriers, dragging,
  swipe-to-dismiss, transitions, safe areas, and keyboard avoidance.
- `AdaptiveSheetScope` for presentation-aware application chrome.
- `AdaptiveSheetScaffold` for fixed top and bottom bars without importing
  `smooth_sheets` in application code.

## Getting started

Add the package from its Git repository, then import the single public
entrypoint:

```dart
import 'package:adaptive_smooth_sheets/adaptive_smooth_sheets.dart';
```

An `AdaptiveSheetThemeData` extension is optional. Package defaults are used
when no extension is registered.

## Usage

Register global route and surface defaults with the application theme:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      AdaptiveSheetThemeData(
        dialogBreakpoint: 700,
        dialogWidth: 640,
      ),
    ],
  ),
  home: const HomePage(),
);
```

Show content with optional per-route overrides:

```dart
await showAdaptiveSheet<void>(
  context: context,
  config: const AdaptiveSheetConfig(
    dialogMaxHeight: 720,
  ),
  builder: (context) {
    final presentation = AdaptiveSheetScope.of(context).presentation;

    return AdaptiveSheetScaffold(
      topBar: Text('Shown as ${presentation.name}'),
      body: const SingleChildScrollView(
        child: MyModalContent(),
      ),
      bottomBar: const MyModalActions(),
    );
  },
);
```

Headers, footers, drag handles, buttons, content padding, forms, and other
application-specific modal chrome intentionally remain consumer concerns.
