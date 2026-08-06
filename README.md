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
- `AdaptiveSheetPage` and `AdaptiveSheetNavigator` for nested modal navigation
  backed by Smooth Sheets' paged-sheet behavior.
- `AdaptiveSheetPopScope` for sheet-aware dismissal guards without leaking the
  underlying route implementation.

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
        nativeBackBehavior:
            AdaptiveSheetNativeBackBehavior.popPageOrCloseSheet,
      ),
    ],
  ),
  home: const HomePage(),
);
```

Show one initial page with optional outer-route overrides:

```dart
await showAdaptiveSheet<void>(
  context: context,
  config: const AdaptiveSheetConfig(
    dialogMaxHeight: 720,
  ),
  page: const AdaptiveSheetPage<void>(
    child: MyModalContent(),
  ),
);
```

Push and pop pages independently from closing the complete modal:

```dart
final sheetNavigator = AdaptiveSheetNavigator.of(context);

await sheetNavigator.push<void>(
  const AdaptiveSheetPage<void>(child: NextModalContent()),
);

sheetNavigator.pop();  // Pops an internal page.
sheetNavigator.close(); // Closes the complete modal.
```

The transition duration and curve in `AdaptiveSheetThemeData` and
`AdaptiveSheetConfig` apply to opening and closing the outer modal. Internal
pages currently use Smooth Sheets' platform-default transitions.

On native platforms, device Back pops an internal page and closes the modal
only from its first page by default. Escape, barrier taps, swipe dismissal, and
`AdaptiveSheetNavigator.close()` close the complete modal. Set
`nativeBackBehavior` on `AdaptiveSheetThemeData` for an application-wide
native policy, or override one modal with `AdaptiveSheetConfig`:

```dart
const AdaptiveSheetConfig(
  nativeBackBehavior: AdaptiveSheetNativeBackBehavior.closeSheet,
)
```

`nativeBackBehavior` has no effect on web builds.

### Web browser Back limitation

Adaptive sheet pages use a nested Flutter `Navigator`; they are not separate
browser-history entries. A `MaterialApp` using Flutter's imperative Navigator
normally relies on Flutter web's single-entry history strategy. Modern Chrome
and Firefox may skip synthetic history entries because of browser
history-manipulation protections. Consequently, toolbar, mouse, and browser
gesture Back actions cannot reliably unwind sheet pages or even reach Flutter.
See the
[Chromium intervention](https://chromium.googlesource.com/chromium/src/+/main/docs/history_manipulation_intervention.md)
and [Mozilla tracking bug](https://bugzilla.mozilla.org/show_bug.cgi?id=1939691).

The package deliberately does not intercept or rewrite application browser
history. On web, visible sheet Back and Close controls are the supported modal
navigation. Applications requiring browser-history-aware modal steps must
model those steps in their root Router or provide a separate opt-in history
integration.

Headers, footers, drag handles, buttons, content padding, forms, and other
application-specific modal chrome intentionally remain consumer concerns.

The [`example`](example/) application shows one way to build that consumer
layer, including project-level modal chrome, tabs, lazy content, guarded
dismissal, global and local theming, and a Reactive Forms modal.
