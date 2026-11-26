# PLAN-48 — Match sign-in fields to the journal editor

Issue: [#48](https://github.com/kensodemann-projects/hypomnema/issues/48) (OPEN).

Related to [#47](https://github.com/kensodemann-projects/hypomnema/issues/47).

`LoginScreen._emailField` and the password `TextField` in `_form` (`lib/features/auth/ui/login_screen.dart`) use a default Material outline with a floating `labelText`. `_emailError` and `_passwordError` are passed as `InputDecoration.errorText`. Blur, editing, and Forgot password already set and clear those strings through `_emailValidationError` and `_passwordValidationError`. The journal editor (`lib/features/journal/ui/journal_editor.dart`) draws `_RequiredLabel` above `_OutlineField`: a `surface` fill, an 8px radius, a 1px `outline` border or a 2px `primary` border while focused, and content padding that tightens from 14×11 to 13×10 when the border is 2px. The editor label sets a 12px medium weight; this bug does not copy that type.

**Out of scope**

- Font size, weight, line height, and letter spacing on the label, the typed text, and the validation message. Issue #47 owns those.
- Validation rules and the current message wording.
- Sign-in, forgot password, autofill hints, obscure text, and keyboard actions (`textInputAction`, submit-to-next, submit-to-sign-in).
- `lib/features/journal/ui/journal_editor.dart` and its tests. Do not extract a shared field widget.

**Contract**

- Labels are `Email *` and `Password *` above the box. The label text color is `onSurfaceVariant`. The asterisk color is `error`. The label style does not set font size, weight, height, or letter spacing.
- The box is filled with `surface`, radius 8. Unfocused padding is `EdgeInsets.symmetric(horizontal: 14, vertical: 11)`. Padding is `EdgeInsets.symmetric(horizontal: 13, vertical: 10)` while the border width is 2.
- A valid field uses a 1px `outline` border, or a 2px `primary` border while focused.
- An invalid field uses `error` for the border: 2px while focused, 1px otherwise. The message under the box is `Email is required.`, `Enter a valid email address.`, or `Password is required.`, in `error`, with no local font size, weight, height, or letter spacing.
- The typed text style does not set font size, weight, height, or letter spacing. `InputDecoration.errorText` and `labelText` stay unset.

**File order**

| Order | Step       | Status | Files                                                                              |
| ----- | ---------- | ------ | ---------------------------------------------------------------------------------- |
| 1     | [STEP-001] |        | `lib/features/auth/ui/login_screen.dart`, then `test/features/auth/ui/login_screen_test.dart` |

**Commit gate** — the human commits. A spot-check does not replace the gate.

```bash
make web
make check
```

`make check` already runs `format-check`, `analyze`, and `test`. Every commit-gate command must succeed with no warning or error before that commit, except the Firebase CLI notice that another emulator suite is already running for project `kws-hypomnema`. The rules tests start their own emulator on port 8180 while the dev suite stays on port 8080. That notice does not fail the gate.

## [STEP-001] Restyle the sign-in fields

**Status:**

**Acceptance criteria:** On phone and desktop, Email and Password show the label and required asterisk above a surface box with the editor’s radius, padding, and valid borders. An invalid field uses the error border and shows the existing message under the box. Those messages still appear and clear for the same cases as today. The label, typed text, and message do not gain local font metrics. Sign-in, forgot password, autofill, and keyboard actions behave as they do today.

**Files**

1. `lib/features/auth/ui/login_screen.dart` — replace the email and password fields with the editor’s chrome plus an error border and a message under the box.
2. `test/features/auth/ui/login_screen_test.dart` — stop reading `decoration.errorText`, and cover label placement, borders, and the messages under the fields.

**Change**

Add a private field widget in `login_screen.dart` and use it for both fields inside `_form`. Remove `_emailField` and the inline password `TextField`. Keep `AutofillGroup`, the controllers, `_emailFocus`, `_passwordFocus`, the validation functions, and the blur and `onChanged` error updates.

The widget is a column with `CrossAxisAlignment.start` and spacing 4, matching `_Field` in the editor. The first child is a rich-text label: `'$label '` in `onSurfaceVariant`, then `*` in `error`. Set only those colors. Do not set font size, weight, height, or letter spacing.

The box is a `TextField` that keeps the current key, controller, focus node, `keyboardType`, `textInputAction`, `autofillHints`, `obscureText`, `onChanged`, and `onSubmitted`. Do not set `style`, `labelText`, or `errorText`. Decoration is filled with `colorScheme.surface`, content padding as in the contract, and one `OutlineInputBorder` of radius 8 assigned to `border`, `enabledBorder`, `focusedBorder`, and `disabledBorder`. Choose the border side from focus and the error string:

- valid and unfocused: 1px `outline`, padding 14×11
- valid and focused: 2px `primary`, padding 13×10
- invalid and unfocused: 1px `error`, padding 14×11
- invalid and focused: 2px `error`, padding 13×10

`_onEmailFocus` and `_onPasswordFocus` return without `setState` while the field is focused, so the field widget listens to the screen’s focus node and rebuilds the border when focus changes. It does not dispose that node.

When the error string is non-null, add a `Text` under the box in the same column, colored `error` only, with no local font metrics. When the string is null, omit that text.

In `login_screen_test.dart`, update the tests that read `decoration.errorText`:

- `Given empty fields, when a field loses focus, then its required message appears`
- `Given an invalid email that has lost focus, when the user changes the email, then the validation error clears and Sign in stays disabled`
- `Given an empty or malformed email, when Forgot password is tapped, then the email helper is shown and no reset is sent`

Those tests find `Email is required.`, `Enter a valid email address.`, and `Password is required.` as text under the field. `errorText` stays null. Changing the email still removes the message. The invalid-email case no longer expects the floating label `Email` to turn `error`; the rich text `Email *` stays `onSurfaceVariant` with an `error` asterisk.

Add widget coverage, on phone (`kDesktopLayoutMinWidth - 200`) and desktop (`kDesktopLayoutMinWidth + 1`), for light and dark themes, that asserts:

- `Email *` and `Password *` sit above their boxes (`label` bottom at or above the field top).
- Unfocused valid Email uses the 1px `outline` border, 14×11 padding, `surface` fill, and radius 8.
- Focused valid Email uses the 2px `primary` border and 13×10 padding.
- After a field loses focus while invalid, the border is 1px `error` and the message’s top is at or below the field bottom.
- Focusing that invalid field again, without editing, uses the 2px `error` border and 13×10 padding.
- The label span, the asterisk span, `TextField.style`, and the message style leave font size, weight, height, and letter spacing unset.

Leave the existing sign-in, snackbar, and keyboard tests in place. They should still pass, including the `textInputAction` checks.

**Spot-check**

```bash
flutter test test/features/auth/ui/login_screen_test.dart
```

- The updated message tests pass without reading `errorText`.
- The new chrome assertions pass on the phone width and the desktop width.
- The existing keyboard and sign-in tests in that file still pass.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error, except the Firebase CLI notice named above.

**Commit:** the commit-gate commands succeed with no warning or error, except that Firebase CLI notice.
