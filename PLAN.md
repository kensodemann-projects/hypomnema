# PLAN-21 — Add the navigation shell and confirm sign-out

Issue: [#21](https://github.com/kensodemann-projects/hypomnema/issues/21) (OPEN).
Related to [#17](https://github.com/kensodemann-projects/hypomnema/issues/17).

`Shell` in `lib/app/shell.dart` chooses `DesktopScaffold` when the width is greater than 600 and `PhoneScaffold` otherwise. The desktop body is a 72-wide strip (`shell-side-panel`) with an immediate sign-out `IconButton` (`shell-sign-out`) and the centered text "Desktop". The phone scaffold is an `AppBar` with that same button and the centered text "Phone". `_SignOutButton` calls `AuthService.signOut` and swallows `AuthException`. `MainApp._AuthGate` in `lib/app/app.dart` shows `CircularProgressIndicator` (`auth-gate-progress`) until `signedIn` emits, then `Shell` or `LoginScreen`. `showConfirmationDialog` in `lib/shared/ui/confirmation_dialog.dart` is the shared dialog. `FirebaseAuthService.signOut` already maps `FirebaseAuthException` to `AuthException`. The shell tests are `test/app/app_test.dart`. The issue body names `lib/main.dart`, `test/main_test.dart`, and `lib/data/services/auth_service.dart`; the issue comment records those as the paths from before the layout move.

**Decisions**

- Labels are "Dashboard", "Journal", "Archive", and "Sign out".
- Desktop uses `NavigationRail` with `labelType: NavigationRailLabelType.all`. Dashboard, Journal, and Archive are the rail destinations. Sign out is the trailing control, with `trailingAtBottom: true` and a `Divider` above it.
- Phone uses `NavigationBar` with those four destinations, Sign out last. Choosing Sign out leaves `selectedIndex` on Dashboard, Journal, or Archive.
- Icons are `Icons.space_dashboard`, `Icons.menu_book`, `Icons.inventory_2`, and `Icons.logout`. The mockup journal glyph `book_2` is absent from `material_ui`.
- `Shell` holds the selected destination, shared by both scaffolds, starting at Dashboard. Crossing the 600 breakpoint keeps that selection.
- Sign out calls `showConfirmationDialog` with `ConfirmationStyle.normal` and no `warning`.
- A failed sign-out shows a floating `SnackBar` through `ScaffoldMessenger`. The background is `colorScheme.errorContainer` and the message color is `colorScheme.error`.

**Out of scope**

- Dashboard, Journal, and Archive screens, including the journaling goal, Add Goal, and archive contents.
- A route table, the rail logo, and the page headers in the dashboard mockups.
- Changes to `ConfirmationDialog`, `AuthService`, `lib/main.dart`, `lib/app/app.dart`, or the width breakpoint. The auth-gate progress indicator stays as it is.

**Contract**

- Content text is "Dashboard", "Journal", or "Archive".
- Dialog title is "Sign out?". Message is "You'll need your email and password to sign back in." Actions are "Cancel" and "Sign out".
- The failure snackbar message is "Failed to sign out."

**File order**

| Order | Step       | Status | Files                                              |
| ----- | ---------- | ------ | -------------------------------------------------- |
| 1     | [STEP-001] |        | `lib/app/shell.dart`, then `test/app/app_test.dart` |
| 2     | [STEP-002] |        | `lib/app/shell.dart`, then `test/app/app_test.dart` |

**Commit gate**

The human commits. A spot-check does not replace the gate. `make check` runs `format-check`, `analyze`, and `test`.

```bash
make web
make check
```

Every commit-gate command must succeed with no warning or error before that commit.

## [STEP-001] Show Dashboard, Journal, and Archive in the shell

**Status:**

**Acceptance criteria:** Above a width of 600 the signed-in shell is a navigation rail, and at 600 and below it is a bottom bar. Both offer Dashboard, Journal, Archive, and Sign out. Dashboard is selected on arrival and the content text is "Dashboard". Choosing Journal or Archive selects that destination and shows its name. The content texts "Desktop" and "Phone" are absent. Sign out sits at the bottom of the rail and is the last bottom-bar item. Tapping it still signs out immediately. While `signedIn` has not emitted, the progress indicator still shows.

**Files**

1. `lib/app/shell.dart` — replace the placeholder scaffolds with the rail, the bottom bar, and the destination text.
2. `test/app/app_test.dart` — update the shell finders and cover destination selection.

**Change**

Make `Shell` a `StatefulWidget` that owns the selected destination and passes it, plus destination and sign-out callbacks, into `PhoneScaffold` and `DesktopScaffold`. Keep both scaffold types public and keep the `Shell` constructor taking `authService`. Leave the breakpoint as `constraints.maxWidth > 600`.

Desktop body is a `Row`: a `NavigationRail` keyed `shell-navigation-rail`, then an `Expanded` content area. Rail destinations are Dashboard (`Icons.space_dashboard`), Journal (`Icons.menu_book`), and Archive (`Icons.inventory_2`), with labels always shown. `selectedIndex` is 0, 1, or 2. The trailing control is a `Divider` and a tappable Sign out label with `Icons.logout`, keyed `shell-sign-out`. Set `trailingAtBottom: true`. There is no leading logo and no `AppBar`.

Phone scaffold has no `AppBar`. Its `bottomNavigationBar` is a `NavigationBar` keyed `shell-navigation-bar` with the same three destinations plus Sign out last, using `Icons.logout` keyed `shell-sign-out`. `selectedIndex` stays 0, 1, or 2 when Sign out is chosen. The content area is the same `Expanded` text used on desktop, keyed `shell-content`, showing "Dashboard", "Journal", or "Archive".

Move the current immediate sign-out behavior onto `Shell`. `shell-sign-out` calls `authService.signOut`, and an `AuthException` leaves the person on the current destination with no snackbar. Remove `shell-side-panel`, the 72-wide strip, and the "Desktop" and "Phone" texts.

Update `expectPhoneShellExists`, `expectPhoneShellNotExists`, `expectDesktopShellExists`, and `expectDesktopShellNotExists` for the new chrome: phone finds `NavigationBar` and no `AppBar`; desktop finds `NavigationRail` and no `AppBar`; neither finds "Desktop" or "Phone". Point the existing phone and desktop sign-out tests at `shell-sign-out` inside the bar or the rail. Keep the immediate sign-out success and `AuthException` assertions, including the failure test's check that the visible text stays the same.

Add tests that assert:

- At 400 and at 601, the four labels are present, the content key reads "Dashboard", and `selectedIndex` is 0.
- On each layout, tapping Journal, then Archive, updates `selectedIndex` to 1, then 2, and the content key reads "Journal", then "Archive".
- The rail's Sign out control is below its Archive label, the rail has three destinations, and `trailingAtBottom` is true.
- The bottom bar's last destination label is "Sign out".
- With Journal selected at width 400, widening the viewport to 601 keeps Journal selected and the content text "Journal".

**Spot-check**

`flutter test test/app/app_test.dart`

- Every test in that file passes, including the updated layout, theme, auth-gate, and immediate sign-out tests.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.

## [STEP-002] Confirm sign-out and report failure

**Status:**

**Acceptance criteria:** Sign out opens the confirmation dialog and leaves the selected destination unchanged. The dialog title is "Sign out?", the message is "You'll need your email and password to sign back in.", and the actions are Cancel and Sign out. The dialog has no warning, and the confirm action uses the primary color. Cancel closes the dialog and stays on the current destination. Confirming signs the person out and shows the sign-in screen. A failed sign-out closes the dialog, shows a snackbar that says "Failed to sign out.", and leaves the person signed in on the current destination. The snackbar goes away on its own.

**Files**

1. `lib/app/shell.dart` — open the shared confirmation dialog from Sign out, and show the failure snackbar.
2. `test/app/app_test.dart` — replace the immediate sign-out tests with dialog, cancel, confirm, and failure coverage.

**Change**

Replace the immediate `signOut` call with one path used by the rail trailing control and the bottom-bar Sign out item. That path awaits `showConfirmationDialog` with title "Sign out?", message "You'll need your email and password to sign back in.", confirm label "Sign out", `style: ConfirmationStyle.normal`, and no `warning`. Leave `selectedIndex` and `shell-content` as they were when the dialog opens.

On a false result, return without calling `signOut`. On true, call `authService.signOut`. After a successful call, the existing `signedIn` emission still replaces `Shell` with `LoginScreen`. On `AuthException`, leave the destination in place and show a floating `SnackBar` whose content text is "Failed to sign out.", whose background is `colorScheme.errorContainer`, and whose text color is `colorScheme.error`. Use the default snackbar duration.

Replace the phone success, desktop success, and phone `AuthException` sign-out tests. From Journal, on both width 400 and width 601, tapping `shell-sign-out` finds the dialog title, message, Cancel, and Sign out; finds no `confirmation-warning`; leaves `signOutCalls` at 0; leaves `selectedIndex` at 1; and leaves `shell-content` reading "Journal". The confirm button's background resolves to `colorScheme.primary` and its foreground to `colorScheme.onPrimary`.

Cancel on both widths removes `confirmation-dialog`, leaves `signOutCalls` at 0, and leaves the content reading "Journal".

Confirm on both widths calls `signOut` once, removes the shell, and shows the login form.

From Archive, on both widths, a thrown `AuthException` after confirm removes the dialog, leaves the shell up with `shell-content` reading "Archive", records one `signOut` call, and finds the text "Failed to sign out." Pump the snackbar duration and its exit, and the message is gone while the shell and "Archive" content remain.

**Spot-check**

`flutter test test/app/app_test.dart`

- Every test in that file passes. The immediate sign-out tests are gone. Dialog, cancel, confirm, and failure coverage passes on both layouts.

**Done when:** the acceptance criteria hold, and the commit-gate commands succeed with no warning or error.

**Commit:** the commit-gate commands succeed with no warning or error.
