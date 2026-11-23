# PR #41 — Make desktop Sign out a focusable button

## Summary

Reviewed the full PR diff against `main`: `lib/app/shell.dart` (desktop rail Sign out control), `test/app/shell_test.dart` (semantics, keyboard, and divider placement), and `PLAN.md` (ignored per merge practice). The change correctly replaces an `InkWell` with a `TextButton` so screen readers and keyboard users get a proper button role and activation path, while preserving the existing confirmation dialog flow and selected destination. New widget tests align with the issue contract; `flutter test test/app/shell_test.dart` passes locally (17 tests). **Recommendation: approve.**

## Finding counts

| Category                                   | Count |
| ------------------------------------------ | ----: |
| 🔒 Security concerns (immediate attention) |     0 |
| ⚡ Performance issues/optimizations        |     0 |
| 🧹 Code cleanup and maintainability        |     1 |
| 📚 Documentation gaps                      |     0 |
| ✅ Positive feedback                       |     2 |
| 🚨 Critical blockers                       |     0 |
| 💭 Questions for discussion                |     1 |
| **Total**                                  |     4 |

## Findings

### Security

*(none)*

### Performance

*(none)*

### Code cleanup and maintainability

**[CLN-001]**

**Status:** complete

**Issue:** The new semantics test asserts `data.flagsCollection.isFocused` is `isNot(Tristate.none)` to mean the control can receive focus. That matches current Flutter semantics modeling (focusability is encoded in the `isFocused` tristate), but the assertion reads as “currently focused” rather than “focusable,” which may confuse the next maintainer.

**Suggestion:** Add a short comment above the expectation, or assert via the transitional API if your team still prefers the name:

```dart
// Focusable nodes expose isFocused as true/false; Tristate.none means not focusable.
expect(data.flagsCollection.isFocused, isNot(Tristate.none));
```

**Why:** The PR’s own plan text still says `SemanticsFlag.isFocusable`; aligning the test with a clarifying comment keeps the contract obvious without changing behavior.

### Documentation

*(none)*

### Positive feedback

**[POS-001]**

**Issue:** N/A

**Suggestion:** Replacing the rail `InkWell` with a styled `TextButton` (`isButton`, tap action, visible label `Sign out`) is the right Material pattern for this affordance and directly addresses the accessibility gap described in the PR summary.

**Why:** Screen readers and platform accessibility APIs expect interactive controls that activate flows like sign-out to expose button semantics, consistent with interactive control guidance.

**Documentation:** https://www.w3.org/WAI/ARIA/apg/

**[POS-002]**

**Issue:** N/A

**Suggestion:** Test additions are well targeted: widget type check, semantics label/flags/actions, keyboard Enter after `requestFocus`, and vertical ordering of the divider vs. Sign out. Reusing existing helpers (`expectSignOutDialog`, `shellSelectedIndex`) keeps the suite consistent.

**Why:** Regression coverage matches the stated contract (dialog copy, no premature `signOut`, Journal stays selected).

### Critical blockers

*(none)*

### Questions for discussion

**[QST-001]**

**Issue:** `TextButton.styleFrom` sets `tapTargetSize: MaterialTapTargetSize.shrinkWrap` and `minimumSize: Size.zero`, which minimizes the hit target to the icon/column footprint.

**Suggestion:** No change required if desktop-only; optionally confirm in manual QA that focus rings and clickable area still feel acceptable on the rail (some users use trackpads or assistive switching on desktop).

**Why:** Smaller targets are usually acceptable on dense desktop chrome but are worth a conscious product/a11y choice.

**Documentation:** https://www.w3.org/WAI/ARIA/apg/