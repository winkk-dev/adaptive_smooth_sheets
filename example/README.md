# Adaptive Smooth Sheets example

This is a deliberately small Flutter app that demonstrates the package's
public API with ordinary Material widgets. It does not copy the internal Winkk
`BaseModal`, tab, or Reactive Forms abstractions.

Run it from this directory:

```sh
flutter run
```

Resize the window across the configured 720 px breakpoint while any demo is
open. The same route changes from a bottom sheet to a dialog without losing
local state.

The launcher covers:

- a minimal `showAdaptiveSheet` call;
- `AdaptiveSheetScrollController` with a lazy list;
- state preservation during live resizing;
- `AdaptiveSheetNavigator` page operations;
- `AdaptiveSheetPopScope`; and
- a route-specific breakpoint and geometry through `AdaptiveSheetConfig`.

The reusable example-only header/footer composition is in
`lib/demos/demo_sheet_scaffold.dart`. It intentionally stays outside the
published package API.
