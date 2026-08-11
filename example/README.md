# Adaptive Smooth Sheets example

This application demonstrates a project-owned modal UI layer on top of
`adaptive_smooth_sheets`. It never imports Smooth Sheets directly, so the
responsive implementation stays behind the package boundary.

Run it from this directory with:

```sh
flutter run
```

The launcher includes compact content, lazy lists, live state preservation,
content-sized and full-height tabs, shared and per-tab footers, a multi-step
nested navigation flow, guarded dismissal, themes, and a long Reactive Forms
modal. Resize the window across the configured 720 px breakpoint while a modal
is open to switch between bottom-sheet and dialog presentation.

The reusable application-side pieces are split into:

- `lib/modals/base_modal/base_modal.dart` for the project chrome entry point.
- `lib/modals/base_modal/base_modal_body.dart` for explicit `singleChild`,
  `list`, `slivers`, and `custom` body strategies.
- `lib/modals/base_modal/base_tab_modal.dart` for naturally sized tabs and a
  `.fill` mode for lazy scrollables, with shared or per-tab footers.
- `lib/modals/base_modal/base_modal_theme.dart` for application-only styling.
- `lib/theme/app_theme.dart` for Material, package, and modal theme setup.

The form composition remains deliberately modest and project-owned.
