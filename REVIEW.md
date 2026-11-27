## Summary

Reviewed the resulting diff for [#51](https://github.com/kensodemann-projects/hypomnema/pull/51): the sign-in email and password fields in `lib/features/auth/ui/login_screen.dart` and the widget coverage in `test/features/auth/ui/login_screen_test.dart`. Request changes. The box, external label, focus and error borders, and the messages under the fields match the journal editor chrome, and the tests exercise phone, desktop, and both themes. Moving the label and the validation message out of `InputDecoration` drops the accessible name and the error announcement those fields had before. `lib/features/journal/ui/journal_editor.dart` already uses that same external label, and its text fields are unnamed too, so `_Field` and `_OutlineField` should not be shared until the text field node carries the name.

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     2 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     1 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     0 |
| **Total**                                  |     **3** |

## Findings

### 🧹 Code cleanup and maintainability

[CLN-001]

**Issue:** Email and Password are no longer named text fields, and the validation message is no longer announced with the field. `_LoginField` draws the label as a sibling `Text.rich` and the message as a sibling `Text`, and it leaves `InputDecoration.labelText` and `errorText` unset. `InputDecorator` only merges a label into the text field when that label is the decoration's label, and it only exposes the validation message as the field's semantics hint when `errorText` is set. A screen-reader user who lands on the control hears an unnamed text field (an obscured one, for Password). The message under the box is ordinary text: it is not the field's hint, and it is not a live region, so it is not announced when blur or Forgot password shows it. The shell already treats a named control as required behavior (`test/app/shell_test.dart` asserts the Sign out button's semantics label).

**Suggestion:** Keep the visible label and the single message under the box. Keep `labelText` and `errorText` unset: `labelText` would draw the label inside the box, and `errorText` would draw a second message and would select `errorBorder` / `focusedErrorBorder`, which are unset, so the error chrome would fall back to the theme border. Put the name, the required state, and the current message on the text field node, and announce the visible message the same way `InputDecorator` announces `errorText`.

```dart
final error = widget.error;

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 4,
  children: [
    ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          text: '${widget.label} ',
          style: TextStyle(color: scheme.onSurfaceVariant),
          children: [
            TextSpan(
              text: '*',
              style: TextStyle(color: scheme.error),
            ),
          ],
        ),
      ),
    ),
    Semantics(
      container: true,
      explicitChildNodes: false,
      label: widget.label,
      isRequired: true,
      hint: error,
      validationResult: error == null
          ? SemanticsValidationResult.none
          : SemanticsValidationResult.invalid,
      child: TextField(
        // existing key, controller, focus node, and decoration
      ),
    ),
    if (error != null)
      Semantics(
        container: true,
        liveRegion: !MediaQuery.supportsAnnounceOf(context),
        child: Text(error, style: TextStyle(color: scheme.error)),
      ),
  ],
);
```

Assert the text field node, not only a parent group, next to the chrome test. Follow the Sign out semantics test: `tester.ensureSemantics()`, then `getSemantics` on `login-email` / `login-password`. Expect `label` `Email` or `Password`, a text-field flag, and, once the message is showing, `hint` equal to that message and `validationResult` `SemanticsValidationResult.invalid`. `find.text` still sees the visible label and message, so the existing chrome assertions stay as they are.

**Why:** Sign-in is a form. The accessible name has to travel with the control that takes focus, and the validation message has to be announced when it appears and again when the user returns to the field. The editor fields need that same name on the text field; see CLN-002. They have no validation message today, so they do not need the live region yet.

**Documentation:** https://www.w3.org/WAI/ARIA/apg/

[CLN-002]

**Issue:** `lib/features/journal/ui/journal_editor.dart` does not name its text fields. `_Field` draws `_RequiredLabel` as a sibling above `_OutlineField`, and the `TextField` sets no `labelText` and no `Semantics` label. Subject has no `hintText`, so that field node has no accessible name. Journal's `hintText` (`Write whatever is on your mind…`) is placeholder copy; `InputDecorator` can expose it as the hint, not as the name "Journal", and not as required. Neither field sets `isRequired`. These fields show no validation message, so the live-region part of CLN-001 does not apply here yet. `_Field`, `_RequiredLabel`, and `_OutlineField` look like the helpers to share with sign-in, and Mood also goes through `_Field`, but the outline field does not put the name on the control. Extracting them as they stand would copy the unnamed field onto both screens.

**Suggestion:** Use the same text-field semantics as CLN-001 on Subject and Journal. Keep the visible label above the box, keep `labelText` unset, and put `label` (`Subject` or `Journal`) and `isRequired: true` on the text field node. Leave `decoration.hintText` as the journal placeholder only. `InputDecorator` already merges that hint into the field, so a second `Semantics.hint` with the same string would be read twice. Sign-in still passes its validation message as `hint`, sets `validationResult`, and wraps the message in the live region; the editor adds those only if it starts showing a message. After both screens name the text field this way, share one required-label column and one outline field. Mood can use the shared label column; it is not a `TextField`.

**Why:** Sign-in and the editor should name the control that takes focus in the same way. The shared widget is the outline field plus the label above it, built with that semantics contract, not the current private helpers copied out of the editor.

**Documentation:** https://www.w3.org/WAI/ARIA/apg/

### ✅ Positive feedback

[POS-001]

**Issue:** The shared field keeps the sign-in behavior that was already correct, and the new tests lock the chrome to the editor's contract on both form factors.

**Suggestion:** `_LoginField` is used for both controls and preserves the keys, controllers, focus nodes, autofill hints, `obscureText`, `textInputAction`, and submit callbacks. The screen still owns and disposes the focus nodes; the field only listens, swaps the listener in `didUpdateWidget`, and removes it in `dispose`. Blur still runs `_emailValidationError` / `_passwordValidationError`, and editing still clears the message. Padding tightens from 14×11 to 13×10 when the border grows to 2px, on the valid primary border and the error border. `login_screen_test.dart` checks that chrome for light and dark at `kDesktopLayoutMinWidth - 200` and `kDesktopLayoutMinWidth + 1`, and it checks that the label, the typed text, and the message leave font size, weight, height, and letter spacing unset.

**Why:** The two fields cannot drift, keyboard and autofill behavior stay put, and the width expressions match the layout constant the rest of the login tests already use.
