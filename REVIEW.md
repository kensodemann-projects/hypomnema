## Summary

Reviewed the resulting diff of [PR 50](https://github.com/kensodemann-projects/hypomnema/pull/50) (`general-refactor` against `main`): centralizing the desktop breakpoint, restructuring the journal screen into symmetric phone and desktop helpers, removing unused widget previews, and recording the responsive-layout convention in `.cursor/rules/hypomnema.mdc`. **Request changes.** The production refactor is sound and behavior-preserving, but the new rule is inserted so that unrelated project constraints sit under it, and the tests this change already edits still hard-code viewport widths the same rule forbids. Neither issue is a product defect; both should be fixed before the convention becomes the standing instruction.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     2 |
| 📚 Documentation gaps                      |     1 |
| ✅ Positive feedback                       |     3 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     1 |
| **Total**                                  |     7 |

## Findings

### 🧹 Code cleanup and maintainability

[CLN-001]

**Issue:** The new test convention is only applied to the breakpoint literals this diff happened to touch. The same files still set phone and desktop viewports with raw `400` and `1200`.

`.cursor/rules/hypomnema.mdc` now says every test viewport width is an expression on `kDesktopLayoutMinWidth` (`kDesktopLayoutMinWidth`, `kDesktopLayoutMinWidth + 1`, `kDesktopLayoutMinWidth - 200`, and so on). `shell_test.dart` updates the 600/601 edges and leaves the neighboring layout tests on magic numbers:

```dart
testWidgets(
  'Given a width of 400, when the shell builds, then the phone layout is used',
  (tester) async {
    await pumpShell(tester, size: const Size(400, 800));
    // ...
  },
);

testWidgets(
  'Given a width of 1200, when the shell builds, then the desktop layout is used',
  (tester) async {
    await pumpShell(tester, size: const Size(1200, 800));
    // ...
  },
);
```

The same split shows up in files this PR already edits: `test/features/auth/ui/login_screen_test.dart` (the breakpoint loops were converted; later cases still use `Size(400, 800)`), `test/shared/ui/confirmation_dialog_test.dart` (desktop edge converted; phone cases still `400`), and `test/app/app_test.dart` (one `601` converted; other viewports still `400`). `test/features/journal/ui/journal_editor_test.dart` is outside the diff and still uses `Size(400, 800)` and `Size(1200, 800)`, including an assertion that the editor's size equals `Size(400, 800)`.

**Suggestion:** Derive every viewport width in these files from the constant, and use the same expression on both sides of an equality assertion. Heights can stay `800`; they are not the breakpoint.

```dart
testWidgets(
  'Given a phone width, when the shell builds, then the phone layout is used',
  (tester) async {
    await pumpShell(
      tester,
      size: const Size(kDesktopLayoutMinWidth - 200, 800),
    );

    expectPhoneShellExists();
  },
);

testWidgets(
  'Given a wide desktop width, when the shell builds, then the desktop layout is used',
  (tester) async {
    await pumpShell(
      tester,
      size: const Size(kDesktopLayoutMinWidth + 600, 800),
    );

    expectDesktopShellExists();
  },
);
```

For the editor size assertion, set the surface and expect the same expression:

```dart
const phone = Size(kDesktopLayoutMinWidth - 200, 800);

expect(tester.getSize(find.byKey(_editorKey)), phone);
```

**Why:** `kDesktopLayoutMinWidth` is the only width that is allowed to change. A later edit of `600` will update the boundary tests and leave the `400` / `1200` cases describing a different layout than the names and the rule claim. The rule is about to be always-on guidance, so the tests in this change should already match it.

[CLN-002]

**Issue:** The new helper order does not match `login_screen.dart`, which the rule cites as the pattern. The rule says shells are ordered `_phoneLayout`, then `_desktopLayout`. Login still declares `_desktopLayout` (around line 371) and then `_phoneLayout` (around line 414). Journal follows the rule: `_phoneLayout`, then `_desktopLayout`, then `_entriesBody`, then the pane builders.

**Suggestion:** Reorder the two login helpers so the cited example matches the order the rule states. Names and `build` can stay as they are:

```dart
Widget _phoneLayout() {
  // existing phone tree
}

Widget _desktopLayout() {
  // existing desktop tree
}

@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (desktopLayoutForWidth(constraints.maxWidth)) {
        return _desktopLayout();
      }
      return _phoneLayout();
    },
  );
}
```

**Why:** The next screen will copy either the rule or the login file. Those two sources currently disagree, which is the drift this refactor is trying to stop.

### 📚 Documentation gaps

[DOC-001]

**Issue:** Inserting `## Responsive UI: balanced abstraction` in the middle of the constraint list pulls every following bullet under that heading. Feature layout, test mirroring, shared fixtures, and the commit gate now read as responsive-UI rules.

From `.cursor/rules/hypomnema.mdc`:

```markdown
## Responsive UI: balanced abstraction

Keep the same abstraction level on both form factors and one layer of decision in one place.

- Name shell builders `_phoneLayout` and `_desktopLayout` ...
- Do not leave one branch fully extracted and the other inlined in `build`. ...
- Organize `lib/` feature-first. ...
- Mirror that layout under `test/`. ...
- When the same or very similar test data is used in more than one test file ...
```

The directory tree and the commit-gate bullet that follow are in the same section.

**Suggestion:** End the responsive list after the layout bullets, and give the folder rules their own heading so they stay product-structure constraints.

```markdown
## Responsive UI: balanced abstraction

Keep the same abstraction level on both form factors and one layer of decision in one place.

- Name shell builders `_phoneLayout` and `_desktopLayout`, matching `login_screen.dart`. ...
- Order private helpers top-down: shells (`_phoneLayout`, `_desktopLayout`), then dispatch, then pane builders. ...
- Put cross-screen layout numbers in `lib/core/constants/`. ...
- In tests, derive viewport widths from `kDesktopLayoutMinWidth`. ...
- Do not leave one branch fully extracted and the other inlined in `build`. ...

## Project layout

- Organize `lib/` feature-first. Keep generated `lib/firebase_options.dart` at the package root; FlutterFire writes that path.
- Mirror that layout under `test/`. ...
- When the same or very similar test data is used in more than one test file, ...
```

Leave the directory tree and the commit-gate bullet under that layout section.

**Why:** This file is always-applied agent guidance. A heading that swallows the rest of the document makes folder placement and the commit gate look like layout-abstraction rules, and it hides where the responsive list actually ends.

### ✅ Positive feedback

[POS-001]

**Issue:** The desktop threshold now lives in one place. `lib/core/constants/layout.dart` defines `kDesktopLayoutMinWidth` and the two helpers, and shell, login, journal, mood picker, and the confirmation dialog all go through them. The old `> 600` checks are gone from application code.

**Suggestion:** Keep new breakpoint checks on `desktopLayoutForWidth` or `desktopLayoutFor`. The boundary tests that use `kDesktopLayoutMinWidth` and `kDesktopLayoutMinWidth + 1` (shell, login, mood picker) lock the exclusive comparison, so changing the constant moves those edges with it.

**Why:** A scattered literal is how the phone and desktop layouts drift apart. One constant plus a strict `>` makes the 600-stays-phone / 601-is-desktop behavior explicit and shared.

[POS-002]

**Issue:** `journal_screen.dart` now matches the abstraction level the rule describes. `_phoneLayout` and `_desktopLayout` are peers, `_entriesBody` is the only place that still branches on the `desktop` flag for list versus list-and-detail, and the panes are `_phoneListPane`, `_desktopListPane`, and `_desktopDetailPane`. `build` only chooses the shell and wraps it in `Scaffold`. Loading and watch-error handling stay shared in the dispatcher.

**Suggestion:** Keep that split. Phone detail stays on `_openEntry` because phone pushes a route; it does not need an empty `_phoneDetailPane` to mirror the desktop pane.

**Why:** The previous shape had the phone tree inlined in `build` and a desktop-only `_listPane`. The new shape is the one future journal edits can extend without putting both form factors back into one method.

[POS-003]

**Issue:** The unused `@Preview` harnesses are gone from `journal_editor.dart`, `mood_picker.dart`, `mood_swatch.dart`, and `confirmation_dialog.dart`, along with the `widget_previews` imports and the preview-only theme wrappers. No remaining `Preview(` or `widget_previews` references showed up in the tree.

**Suggestion:** Leave previews out until a screen needs them again. Production widgets are unchanged by the deletion.

**Why:** Those blocks were a second copy of each layout (including their own `width > 600` check in the editor preview) and were not part of the test suite. Removing them is a large, safe deletion.

### 💭 Questions for discussion

[QST-001]

**Issue:** `desktopLayoutForWidth` and `desktopLayoutFor` do not measure the same box. Shell, login, the mood picker, and the confirmation dialog use the `LayoutBuilder` constraints. The journal screen uses `desktopLayoutFor`, which reads `MediaQuery.sizeOf(context).width`, for both the scaffold choice and `_openEditor`.

That preserves the previous journal behavior. It is a different decision once the journal sits in `DesktopScaffold`: the rail takes width, and the journal's box is the expanded remainder, while `MediaQuery` is still the full window. A window just above 600 can select the desktop shell and the desktop journal (380px list plus detail) even when the content slot is narrower than the breakpoint.

**Suggestion:** Confirm which box the journal should use. If it should follow the slot it is given, match the other screens:

```dart
@override
Widget build(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return LayoutBuilder(
    builder: (context, constraints) {
      if (desktopLayoutForWidth(constraints.maxWidth)) {
        return Scaffold(body: _desktopLayout(context, scheme));
      }
      return Scaffold(body: _phoneLayout(context, scheme));
    },
  );
}
```

`_openEditor` can stay on the window size if a wide window should keep the dialog even when the list pane is narrow. If both should stay on `MediaQuery`, a one-line comment on `desktopLayoutFor` stating that it is the window, not the incoming constraints, would keep the next caller from treating the two helpers as interchangeable.

**Why:** The new API makes the two checks look equivalent. They agree for a full-screen route and disagree for a child of the navigation rail. This is the change that should record which one the journal means.
