# PLAN-47 — Material text roles

Issue: [#47](https://github.com/kensodemann-projects/hypomnema/issues/47) (CLOSED).

`AppTheme` sets the color scheme and `AppColors` and leaves `textTheme` on the Material defaults. Screens then paint with local `TextStyle` values: `JournalScreen` passes `titleSize`, `headingSize`, `headingLetterSpacing`, and `subjectSize`; `JournalEntryList`, `JournalEntryDetail`, and `EmptyState` take those sizes; `JournalEditor`, `MoodPicker`, `ConfirmationDialog`, `LoginScreen`, and `_FieldLabel` set font size, weight, line height, or letter spacing themselves. The journal load error, the editor save error, and the shell sign-out error build a `SnackBar` with `errorContainer` and `TextStyle(color: scheme.error)`. The phone `FloatingActionButton` sets `primaryContainer` and `onPrimaryContainer` on the widget. Pane width 380, header height 72, bar height 64, the list radius 12, the card radius 16, border widths 1 and 2, and the empty-state icon opacity 0.8 are literals in the widgets. `MoodSwatch` draws its digit at 15px and 22px.

## Decisions

- The role is the Material 3 name for that kind of text. Phone and desktop share it. Size, weight, height, and letter spacing stay on the role. A `copyWith` may set color, and the widget may still set italic or uppercase.
- Screen titles use `titleLarge`: "Journal", the phone entry-bar title, and both editor titles ("New entry" and "New journal entry").
- Content headlines use `headlineSmall`: the detail subject, the confirmation title, and "Sign in".
- The list subject uses `titleMedium`. The subject field uses `titleMedium`. Journal body, the journal field, and a field with no caller style use `bodyLarge`.
- Supporting copy uses `bodyMedium`: the empty-state message, "No entries yet.", the confirmation message, and the confirmation warning. Short supporting lines use `bodySmall`: the list "when" line, the editor date note, and field errors. `SnackBarTheme.contentTextStyle` uses `bodyMedium`.
- Labels use `labelMedium`: field labels, the detail "when" line, and the mood captions "Awful" and "Great". Week headings use `labelSmall`, and `JournalEntryList` still uppercases them.
- The sign-in name uses `displaySmall`. The sign-in quotation uses `bodyLarge` with italic set on the widget. The brand panel still sets white, and the desktop quotation still sets white at 0.85 opacity. The phone quotation still uses `onSurfaceVariant`.
- Selected list text still uses `onPrimaryContainer`. Other scheme colors stay only where the text sits on a scheme surface (`onSurfaceVariant`, `error`, `AppColors.warning`).
- `AppMetrics` is a `ThemeExtension` beside `AppColors`. It holds `paneWidth` 380, `headerHeight` 72, `barHeight` 64, `rowRadius` 12, `cardRadius` 16, `borderWidth` 1, `selectedBorderWidth` 2, and `emptyStateIconOpacity` 0.8. Screens read those fields. The numbers are not retuned.
- Error snackbars keep `SnackBarBehavior.floating` at the call site. `SnackBarTheme` supplies `errorContainer` and `bodyMedium` in `onErrorContainer`. Call sites pass `Text` with no style. `floatingActionButtonTheme` supplies `primaryContainer` and `onPrimaryContainer`. The phone button does not set those colors. Its corner radius reads `cardRadius`.

## Out of scope

- `REFACTOR.md` stays as it is.
- `AppTheme` does not replace `textTheme` metrics.
- `MoodSwatch` keeps both digit styles. Its size, radius, and border stay on the widget.
- `LoginSnackBar` already uses `bodyMedium`. It is not one of the three error snackbars.
- Dialog corners stay at 28. The outline field keeps radius 8 and border widths 1 and 2. The warning banner keeps radius 12. Spacing, padding, and icon sizes stay on the widgets.
- Shell placeholder text, navigation labels, and button labels already inherit a component style.
- Phone and desktop layouts stay two layouts.

## Text roles

| Text | Role |
| ---- | ---- |
| "Journal", entry-bar title, "New entry", "New journal entry" | `titleLarge` |
| Detail subject, confirmation title, "Sign in" | `headlineSmall` |
| List subject, subject field | `titleMedium` |
| Journal paragraphs, journal field, default field input | `bodyLarge` |
| Empty-state message, "No entries yet.", confirmation message and warning | `bodyMedium` |
| List "when", date note, field error | `bodySmall` |
| Field label, detail "when", "Awful" / "Great" | `labelMedium` |
| "This week", "Last week" | `labelSmall`, still uppercased in the list |
| Sign-in name | `displaySmall` |
| Sign-in quotation | `bodyLarge`, italic on the widget |
| Error snackbar message | `bodyMedium` from `SnackBarTheme` |
| Mood digit | unchanged on `MoodSwatch` |

## File order

| Order | Step | Status | Files |
| ----- | ---- | ------ | ----- |
| 1 | [STEP-001] | complete | `lib/core/theme/app_theme.dart`, then `test/core/theme/app_theme_test.dart` |
| 2 | [STEP-002] | complete | `lib/shared/ui/form_fields.dart`, then `lib/shared/ui/confirmation_dialog.dart`, then `test/shared/ui/form_fields_test.dart`, then `test/shared/ui/confirmation_dialog_test.dart`, then `test/features/auth/ui/login_screen_test.dart`, then `test/features/journal/ui/journal_editor_test.dart` |
| 3 | [STEP-003] | complete | `lib/shared/ui/empty_state.dart`, then `lib/features/journal/ui/journal_entry_list.dart`, then `lib/features/journal/ui/journal_entry_detail.dart`, then `lib/features/journal/ui/journal_screen.dart`, then `test/shared/ui/empty_state_test.dart`, then `test/features/journal/ui/journal_screen_test.dart` |
| 4 | [STEP-004] | complete | `lib/features/journal/ui/journal_editor.dart`, then `lib/features/journal/ui/mood_picker.dart`, then `test/features/journal/ui/journal_editor_test.dart`, then `test/features/journal/ui/mood_picker_test.dart`, then `test/features/journal/ui/journal_screen_test.dart` |
| 5 | [STEP-005] | | `lib/features/auth/ui/login_screen.dart`, then `test/features/auth/ui/login_screen_test.dart` |
| 6 | [STEP-006] | | `lib/app/shell.dart`, then `test/app/shell_test.dart` |
| 7 | [STEP-007] | | `.cursor/rules/hypomnema.mdc` |

## Commit gate

The human commits. A spot-check does not replace the gate.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit, except one warning that does not fail the gate: the Firebase CLI notice that another emulator suite is already running for project `kws-hypomnema`. The rules tests start their own emulator on port 8180 while the dev suite stays on port 8080.

## [STEP-001] Add snackbar, button, and metric themes

**Status:** complete

**Acceptance criteria:** Light and dark `AppTheme` expose `SnackBarTheme`, `floatingActionButtonTheme`, and `AppMetrics` with the values in Decisions, and `textTheme` metrics still match a default `ThemeData` of the same brightness.

**Files**

1. `lib/core/theme/app_theme.dart` — add `AppMetrics` and the two component themes.
2. `test/core/theme/app_theme_test.dart` — assert those themes and that `textTheme` metrics are unchanged.

**Change**

Add `AppMetrics` next to `AppColors`, with `copyWith`, `lerp`, `==`, and `hashCode`. Register it on light and dark. Build each `ThemeData`, then `copyWith` the component themes from that theme's scheme and `textTheme` so `textTheme` itself is not replaced.

`SnackBarThemeData.backgroundColor` is `colorScheme.errorContainer`. `contentTextStyle` is `textTheme.bodyMedium` with color `onErrorContainer`. `FloatingActionButtonThemeData.backgroundColor` is `primaryContainer` and `foregroundColor` is `onPrimaryContainer`.

Leave every screen on its current styles. This step only adds theme data.

**Spot-check**

```bash
flutter test test/core/theme/app_theme_test.dart
```

- Light and dark themes expose the snackbar colors, the button colors, and each `AppMetrics` value.
- Each `textTheme` role's font size, weight, height, and letter spacing match a default `ThemeData` with the same brightness and color scheme.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-002] Use text roles on fields and the confirmation dialog

**Status:** complete

**Acceptance criteria:** Field labels use `labelMedium`, field errors and the required message use `bodySmall`, an outline field with no caller style uses `bodyLarge`, and the confirmation title, message, and warning use the roles in Text roles on both phone and desktop.

**Files**

1. `lib/shared/ui/form_fields.dart` — label, error, input, and hint roles.
2. `lib/shared/ui/confirmation_dialog.dart` — one title role and one message role.
3. `test/shared/ui/form_fields_test.dart` — expect those roles.
4. `test/shared/ui/confirmation_dialog_test.dart` — expect the same title and message metrics at both widths.
5. `test/features/auth/ui/login_screen_test.dart` — labels, default field style, and the required message follow the field roles.
6. `test/features/journal/ui/journal_editor_test.dart` — required labels follow `labelMedium`. Leave the editor's own font-size expects until [STEP-004].

**Change**

`_FieldLabel` uses `labelMedium` with `onSurfaceVariant`. The required asterisk stays a color-only `TextStyle` in `error`, so its own size, weight, height, and letter spacing stay unset and it inherits the label.

`OutlineTextField` resolves the input style to the caller `style` or `bodyLarge`. The hint uses that resolved style with `onSurfaceVariant`. The error and required message use `bodySmall` with `error`. The outline radius and border widths stay on the field.

`ConfirmationDialog` drops the phone 20 and desktop 22 title sizes. Title uses `headlineSmall` at both widths. Message uses `bodyMedium` with `onSurfaceVariant`. Warning text uses `bodyMedium` with `AppColors.warning`. The banner radius stays 12. Dialog width and the 28 corner stay.

**Spot-check**

```bash
flutter test test/shared/ui/form_fields_test.dart test/shared/ui/confirmation_dialog_test.dart test/features/auth/ui/login_screen_test.dart test/features/journal/ui/journal_editor_test.dart
```

- Label size, weight, height, and letter spacing match `labelMedium`. The asterisk style still has those four fields unset.
- A field with no caller style matches `bodyLarge`. The required message matches `bodySmall` and is `error`.
- Phone and desktop confirmation titles match `headlineSmall`. The message and warning match `bodyMedium`.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-003] Use text roles and metrics on the journal

**Status:** complete

**Acceptance criteria:** `JournalEntryList`, `JournalEntryDetail`, and `EmptyState` take no text-size parameters. Journal titles, week headings, list text, detail text, and empty copy use the Text roles on phone and desktop. Pane, header, bar, radii, borders, and the empty-state icon opacity come from `AppMetrics`. The load error and the phone Write button take their colors from the themes added in [STEP-001].

**Files**

1. `lib/shared/ui/empty_state.dart` — drop `titleSize`; read the icon opacity from `AppMetrics`.
2. `lib/features/journal/ui/journal_entry_list.dart` — drop heading size and letter spacing; use `labelSmall`, `titleMedium`, and `bodySmall`.
3. `lib/features/journal/ui/journal_entry_detail.dart` — drop `subjectSize` and `subjectLetterSpacing`; use `headlineSmall`, `labelMedium`, and `bodyLarge`.
4. `lib/features/journal/ui/journal_screen.dart` — stop passing those parameters; use `titleLarge`, `bodyMedium`, `AppMetrics`, the load snackbar theme, and the button theme.
5. `test/shared/ui/empty_state_test.dart` — expect `titleMedium`, `bodyMedium`, and the extension opacity.
6. `test/features/journal/ui/journal_screen_test.dart` — expect the journal roles, and expect the load snackbar and Write button to use the themes. Leave the editor save-snackbar expects until [STEP-004].

**Change**

Remove `titleSize` from `EmptyState`. Title is `titleMedium`. Message is `bodyMedium` with `onSurfaceVariant`. The icon color is `primary` at `AppMetrics.emptyStateIconOpacity`. `iconSize` stays a parameter.

Remove `headingSize` and `headingLetterSpacing` from `JournalEntryList`. The heading is `group.heading.toUpperCase()` in `labelSmall` with `onSurfaceVariant`. The subject is `titleMedium`, with `onPrimaryContainer` when the row is selected. The "when" line is `bodySmall` with `onSurfaceVariant`, or `onPrimaryContainer` when selected. Row radius, resting border, and selected border come from `AppMetrics`. `headingPadding` stays a parameter.

Remove `subjectSize` and `subjectLetterSpacing` from `JournalEntryDetail`. The "when" line is `labelMedium` with `onSurfaceVariant`. The subject is `headlineSmall`. Paragraphs are `bodyLarge`. The detail card uses `cardRadius` and `borderWidth`.

`JournalScreen` stops passing the removed arguments. "Journal" and the phone entry-bar title are `titleLarge` on both layouts. "No entries yet." is `bodyMedium` with `onSurfaceVariant`. The phone title bar, the entry bar, and the desktop header use `barHeight` and `headerHeight`. The list pane width and the desktop empty-state max width use `paneWidth`. Pane and header dividers use `borderWidth`. The load snackbar sets only `behavior: SnackBarBehavior.floating` and `content: Text(_loadFailed)`. The phone `FloatingActionButton.extended` does not set background or foreground. Its shape uses `cardRadius`.

**Spot-check**

```bash
flutter test test/shared/ui/empty_state_test.dart test/features/journal/ui/journal_screen_test.dart
```

- Empty title matches `titleMedium`. Empty message matches `bodyMedium`. The icon opacity matches `AppMetrics`.
- Phone and desktop week headings match `labelSmall` and stay uppercase. The list subject matches `titleMedium`. The desktop and phone detail subjects match `headlineSmall`.
- The load snackbar does not set its own background or text color. The theme background is `errorContainer`, the effective text color is `onErrorContainer`, and the behavior is floating.
- The phone Write button does not set its own background or foreground. The button theme holds `primaryContainer` and `onPrimaryContainer`.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-004] Use text roles on the editor and mood captions

**Status:** complete

**Acceptance criteria:** Both editor titles use `titleLarge`. The date note, subject field, journal field, and mood captions use the Text roles. The editor save error uses `SnackBarTheme`. The phone editor bar uses `AppMetrics.barHeight`.

**Files**

1. `lib/features/journal/ui/journal_editor.dart` — titles, date note, field styles, bar height, and save snackbar.
2. `lib/features/journal/ui/mood_picker.dart` — caption role.
3. `test/features/journal/ui/journal_editor_test.dart` — expect those roles and the theme snackbar.
4. `test/features/journal/ui/mood_picker_test.dart` — expect `labelMedium` for "Awful" and "Great".
5. `test/features/journal/ui/journal_screen_test.dart` — the save-failure snackbar expects the theme colors.

**Change**

"New entry" and "New journal entry" both use `titleLarge`. `_DateNote` uses `bodySmall` with `onSurfaceVariant`. The subject field passes `titleMedium`. The journal field passes `bodyLarge`. Drop the local 14px, 16px, and height 1.7 styles. The phone top bar's minimum height is `AppMetrics.barHeight`. The save snackbar sets only floating behavior and `Text(_saveFailed)`.

Mood captions use `labelMedium` with `onSurfaceVariant`. Drop the local 12px style and `height: 1`. The swatch digits stay in `MoodSwatch`.

**Spot-check**

```bash
flutter test test/features/journal/ui/journal_editor_test.dart test/features/journal/ui/mood_picker_test.dart test/features/journal/ui/journal_screen_test.dart
```

- Both editor titles match `titleLarge`. The date note matches `bodySmall`. The subject field matches `titleMedium`. The journal field matches `bodyLarge`, including that role's height.
- "Awful" and "Great" match `labelMedium`.
- The save snackbar does not set its own background or text color. The theme background is `errorContainer` and the effective text color is `onErrorContainer`.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-005] Use text roles on the sign-in screen

**Status:**

**Acceptance criteria:** The sign-in name uses `displaySmall` on phone and desktop. Both quotations use `bodyLarge` and stay italic. "Sign in" uses `headlineSmall`. The brand panel still sets the colors that keep its text legible.

**Files**

1. `lib/features/auth/ui/login_screen.dart` — name, quotation, and heading roles.
2. `test/features/auth/ui/login_screen_test.dart` — expect those roles instead of 28, 15, 40, 18, and 26.

**Change**

Phone and desktop "Hypomnema" use `displaySmall`. The desktop name still sets white. Phone and desktop quotations use `bodyLarge` with `FontStyle.italic`. The phone quotation still sets `onSurfaceVariant`. The desktop quotation still sets white at 0.85 opacity. "Sign in" uses `headlineSmall`. Drop the local font sizes, weights, letter spacing, and line heights. Field labels and field text already follow [STEP-002].

**Spot-check**

```bash
flutter test test/features/auth/ui/login_screen_test.dart
```

- Phone and desktop names match `displaySmall`. The desktop name stays white.
- Both quotations match `bodyLarge`, stay italic, and keep their current colors.
- "Sign in" matches `headlineSmall`.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-006] Use the snackbar theme for sign-out errors

**Status:**

**Acceptance criteria:** The shell sign-out error uses `SnackBarTheme`: `onErrorContainer` text on `errorContainer`, with floating behavior still set at the call site.

**Files**

1. `lib/app/shell.dart` — sign-out snackbar content and colors.
2. `test/app/shell_test.dart` — expect the theme colors instead of `scheme.error` on the text.

**Change**

The sign-out `SnackBar` sets only `behavior: SnackBarBehavior.floating` and `content: Text('Failed to sign out.')`. It does not set `backgroundColor` or a text color.

**Spot-check**

```bash
flutter test test/app/shell_test.dart
```

- The snackbar does not set its own background or text color.
- The theme background is `errorContainer`, the effective text color is `onErrorContainer`, and the behavior is floating.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

## [STEP-007] Record the text-role rule

**Status:**

**Acceptance criteria:** `.cursor/rules/hypomnema.mdc` tells later UI work to use the Material `textTheme` role for the kind of text, to keep that role's metrics, to keep transforms in the widget, and to leave the mood digit styles in `MoodSwatch`.

**Files**

1. `.cursor/rules/hypomnema.mdc` — add that text-role practice.

**Change**

Add a short section to the always-applied rule. It covers text roles only: choose the `textTheme` role that names the kind of text, use the role as Material defines it, use the same role on phone and desktop, keep uppercase and italic in the widget, and leave the mood digit styles in `MoodSwatch`. Snackbar, floating action button, and `AppMetrics` details stay in the theme code and out of this rule.

**Spot-check**

```bash
flutter test test/core/theme/app_theme_test.dart
```

- The rule file is present and the theme test still passes. This step does not change Dart code.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the emulator notice in Commit gate.
