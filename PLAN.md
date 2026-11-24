# PLAN-34 — Show each mood as its number and color

Issue: [#34](https://github.com/kensodemann-projects/hypomnema/issues/34) (OPEN).

Related to [#32](https://github.com/kensodemann-projects/hypomnema/issues/32).

A journal mood is an `int` on `JournalEntry` in `lib/features/journal/domain/journal_entry.dart`. `JournalEntry.create` and `revise` keep it only when `_isMood` is true (1 through 5) and throw `InvalidJournalEntryException` otherwise. Nothing draws that number. `AppTheme` in `lib/core/theme/app_theme.dart` has no mood colors, and `lib/` has no journal list, entry details, or editor.

## Decisions

- The swatch and picker live under `lib/features/journal/ui/`. Mood is a journal field, and this issue's consumers are the journal list, entry details, and editor.
- The mood value stays an `int`, the same type as `JournalEntry.mood`.
- `MoodPicker.value` is `int?`. Null means nothing is selected. A non-null value is the selected mood, and a tap reports the new mood through `onChanged`.
- A mood outside 1 through 5 throws `ArgumentError` from `MoodSwatch` and from `MoodPicker` when `value` is non-null.
- Phone and desktop follow the cutoff already used by `AppShell`, `LoginScreen`, and `ConfirmationDialog`: width above 600 is desktop.
- The swatch has two sizes from the journal mock-ups. `regular` is the standalone swatch. `large` is the picker swatch.

## Out of scope

- Journal list, entry details, editor, and mood trend screens, and placing these widgets on any of them.
- The 22×22 swatch used later on the dashboard and goal rows.
- Hover grow on a picker option.
- Rounding an average mood, and painting mood-trend points.
- Changing `JournalEntry` or `AppTheme`.

## Contract

| Mood | Fill |
| --- | --- |
| 1 | `#E5534B` |
| 2 | `#F28C38` |
| 3 | `#F5C842` |
| 4 | `#A8CC4A` |
| 5 | `#4CAF50` |

- The number is the digit `1` through `5`, weight 700, color `#111111`, centered on the fill. Light and dark themes use these same five fills and this same number color.
- `regular`: 28×28, corner radius 7, font size 15. `large`: 48×48, corner radius 12, font size 22.
- In the dark theme, an unselected swatch draws a 1px inside border of white at 18% opacity. The light theme draws no border. The border stays inside the swatch's size.
- A selected picker swatch is scaled to 1.1. A ring sits outside it: 3px of the theme `surface` color, then 2px of the theme `onSurface` color. Unselected picker swatches stay at scale 1 with no ring.
- The picker shows five `large` swatches in order from 1 to 5. Under 1 the label is `Awful`. Under 5 the label is `Great`. Moods 2, 3, and 4 have no label text. Every option still reserves a 16px label line, 12px type, in `onSurfaceVariant`, 6px under the swatch, so the five swatches share one top line.
- Desktop picker: options are 64px wide, in a row, 12px apart, aligned to the start, with no horizontal padding. Phone picker: the same five options spread from the left edge to the right edge with equal gaps and no horizontal padding.

## File order

| Order | Step | Status | Files |
| --- | --- | --- | --- |
| 1 | [STEP-001] | | `lib/features/journal/ui/mood_swatch.dart`, then `test/features/journal/ui/mood_swatch_test.dart` |
| 2 | [STEP-002] | | `lib/features/journal/ui/mood_picker.dart`, then `test/features/journal/ui/mood_picker_test.dart` |

## Commit gate

The human commits. A spot-check does not replace the gate. `make check` already runs `format-check`, `analyze`, and `test`, so the gate has no separate test command.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit, except the Firebase CLI notice that another emulator suite is already running for project `kws-hypomnema`. The rules tests start their own emulator on port 8180 while the dev suite stays on port 8080. That notice does not fail the gate.

## [STEP-001] Add the mood swatch

**Status:**

**Acceptance criteria:** Each mood from 1 through 5 is a square of its contract fill with its digit centered in `#111111`, at the regular size and the large size, in both light and dark themes. The dark theme adds the inside border. A mood outside 1 through 5 throws `ArgumentError`.

**Files**

1. `lib/features/journal/ui/mood_swatch.dart` — `MoodSwatchSize` and `MoodSwatch`, which paint one mood.
2. `test/features/journal/ui/mood_swatch_test.dart` — widget tests for the fills, the number color, both sizes, both themes, and the rejected moods.

**Change**

Add `MoodSwatchSize` with `regular` and `large`, using the contract sizes. Add `MoodSwatch`, a stateless widget with a required `int mood` and a `MoodSwatchSize size` that defaults to `regular`. Import UI widgets from `package:material_ui/material_ui.dart`. In the constructor, throw `ArgumentError` when `mood` is outside 1 through 5.

Paint a centered digit on the contract fill for that mood. Use weight 700 and `#111111` for the digit in both `AppTheme.light` and `AppTheme.dark`. When `Theme.of(context).brightness` is dark, draw the contract's 1px inside border. When it is light, draw no border.

Add phone and desktop widget previews, at `Size(400, 800)` and `Size(1000, 700)`, wrapped in `MaterialApp` with `AppTheme.light` and `AppTheme.dark`, showing moods 1 through 5 at both sizes. Follow the preview shape in `lib/shared/ui/confirmation_dialog.dart`.

The test pumps each mood at both sizes under both themes. For each case it asserts the visible digit, the text color `#111111`, the fill, the font size, and the rendered size. It asserts the dark inside border and the absence of a border in light. It asserts that moods 0 and 6 throw `ArgumentError` before the swatch builds.

**Spot-check**

```bash
flutter test test/features/journal/ui/mood_swatch_test.dart
```

- Those tests pass.

**Done when:** The acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the Firebase CLI emulator notice in the commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the Firebase CLI emulator notice in the commit gate.

## [STEP-002] Add the mood picker

**Status:**

**Acceptance criteria:** The picker offers moods 1 through 5, labels only `Awful` and `Great`, and shows each number on its contract fill in `#111111` in both themes. The selected mood is the scaled swatch with the contract ring. A mood shown as a `MoodSwatch` outside the picker has no labels. Phone and desktop use the contract layouts.

**Files**

1. `lib/features/journal/ui/mood_picker.dart` — `MoodPicker`, which lays out five large swatches and the two end labels.
2. `test/features/journal/ui/mood_picker_test.dart` — widget tests for the five moods, the labels, selection, taps, both themes, and both layouts.

**Change**

Add `MoodPicker`, a stateless widget with `int? value` and `ValueChanged<int> onChanged`. Import UI widgets from `package:material_ui/material_ui.dart`. When `value` is non-null and outside 1 through 5, throw `ArgumentError` in the constructor. Null `value` selects nothing.

Build five options in order. Each option is a column, 6px between the swatch and the label line, keyed `mood-option-1` through `mood-option-5`. The swatch is a `MoodSwatch` of size `large`. The label line is 16px tall and 12px type in `onSurfaceVariant`: `Awful` under 1, `Great` under 5, and empty under 2, 3, and 4. Tapping an option calls `onChanged` with that mood.

When the option's mood equals `value`, scale that swatch to 1.1 and draw the contract ring from `ColorScheme.surface` and `ColorScheme.onSurface`. Leave every other swatch at scale 1 with no ring. The ring does not hide the digit or change the fill.

Choose the layout from the picker's own max width. Above 600, use the desktop contract. At 600 and below, use the phone contract.

Add phone and desktop widget previews at the same sizes as the swatch, showing a picker with mood 3 selected and a standalone `MoodSwatch` for mood 3 at the regular size, with no label beside it.

The test asserts five large swatches, digits `1` through `5` on the contract fills in `#111111`, under both themes. It asserts the texts `Awful` and `Great`, and no other mood-name text. It asserts a standalone `MoodSwatch` renders its digit with no `Awful` or `Great`. With `value` 4, option 4 is scaled to 1.1 and has the ring, and the other four stay at scale 1 with no ring. With `value` null, no option is selected. Tapping option 2 calls `onChanged` with 2. At width 400 the first option's left edge and the last option's right edge meet the picker edges, and the four gaps are equal. At width 1000 each option is 64px wide, neighboring options are 12px apart, and the row starts at the leading edge and stays narrower than the picker. `value` 0 and `value` 6 throw `ArgumentError`.

**Spot-check**

```bash
flutter test test/features/journal/ui/mood_picker_test.dart
```

- Those tests pass.

**Done when:** The acceptance criteria hold, and the commit-gate commands succeed with no warning or error other than the Firebase CLI emulator notice in the commit gate.

**Commit:** the commit-gate commands succeed with no warning or error other than the Firebase CLI emulator notice in the commit gate.
