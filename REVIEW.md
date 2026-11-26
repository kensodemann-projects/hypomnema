## Summary

Reviewed the resulting diff of [PR 50](https://github.com/kensodemann-projects/hypomnema/pull/50) (`general-refactor` against `main`): centralizing the desktop breakpoint, restructuring the journal screen into symmetric phone and desktop helpers, removing unused widget previews, and recording the responsive-layout convention in `.cursor/rules/hypomnema.mdc`. **Request changes.** The production refactor is sound and behavior-preserving. CLN-001 and CLN-002 are resolved: test viewport widths derive from `kDesktopLayoutMinWidth`, and `login_screen.dart` now declares `_phoneLayout` before `_desktopLayout`. The new rule is still inserted so that unrelated project constraints sit under it.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     0 |
| 📚 Documentation gaps                      |     1 |
| ✅ Positive feedback                       |     3 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     1 |
| **Total**                                  |     5 |

## Findings

### 🧹 Code cleanup and maintainability

[CLN-001]

**Issue:** Resolved. Viewport widths in the tests called out here now derive from `kDesktopLayoutMinWidth`. Phone cases use `kDesktopLayoutMinWidth - 200` (and the boundary uses the constant itself). Desktop cases use `kDesktopLayoutMinWidth + 1`, `+ 150`, `+ 400`, or `+ 600`. No remaining `Size(400, …)`, `Size(600, …)`, `Size(601, …)`, or `Size(1200, …)` viewport literals.

Checked `shell_test.dart`, `app_test.dart`, `login_screen_test.dart`, `confirmation_dialog_test.dart`, `journal_screen_test.dart`, `journal_editor_test.dart`, and `mood_picker_test.dart`. The editor assertion expects the same expression it sets: `Size(kDesktopLayoutMinWidth - 200, 800)`. Widget sizes such as `Size(48, 48)`, `Size(72, 72)`, and the dialog width `720` are measured chrome, not viewports.

**Suggestion:** None for the widths. One test title in `shell_test.dart` still reads “Given a width of above the desktop layout minimum” for the `kDesktopLayoutMinWidth + 150` case. Drop the word “of” if you touch that name.

**Why:** A later change to the breakpoint constant now moves these viewports with it, which is what the rule asks for.

[CLN-002]

**Issue:** Resolved. `login_screen.dart` now declares `_phoneLayout` (line 371) and then `_desktopLayout` (line 421), matching the rule and `journal_screen.dart`. The uncommitted diff only moves `_desktopLayout` below `_phoneLayout`. The method bodies are unchanged.

**Suggestion:** None. `build` still chooses with `desktopLayoutForWidth` and returns `_desktopLayout()` or `_phoneLayout()` in that order.

**Why:** The cited example and the journal screen now agree on helper order, so the next screen can copy either one.

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
