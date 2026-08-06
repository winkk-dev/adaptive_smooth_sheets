# Adaptive Smooth Sheets example

This application demonstrates a project-owned modal UI layer on top of
`adaptive_smooth_sheets`. It intentionally imports only the adaptive package;
the Smooth Sheets implementation stays behind the package boundary.

Run it from this directory with:

```sh
flutter run
```

The launcher includes compact content, a lazy list, live state preservation,
tabs, a multi-step nested navigation flow, guarded dismissal, global and
per-route themes, and a long Reactive Forms modal. Resize the window across the
configured 720 px breakpoint while a modal is open to switch between
bottom-sheet and dialog presentation.

The reusable application-side pieces are split into:

- `lib/modals/base_modal.dart` for project chrome and explicit body scrolling.
- `lib/modals/base_tab_modal.dart` for the current concrete tab composition.
- `lib/modals/base_modal_theme.dart` for application-only styling.
- `lib/theme/app_theme.dart` for Material, package, and modal theme setup.

The form and tab abstractions are deliberately modest. Their shared API will be
revisited in the later “Simplify forms and tabs” task.
