# Hypomnema — High-Level Plan

This plan breaks the first release in [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) into features, in the order to build them. Each feature runs through the workflow in [CONTRIBUTING.md](CONTRIBUTING.md#workflow):

1. Feed the feature's intent sentence to **capture-intent**, which interviews you and writes `INTENT.md`.
2. File the issue with **create-feature** (or **create-task** for the small ones noted below).
3. Break a feature into tasks with **create-tasks**, then plan and implement each task with **plan-implementation** and **implement-next-step**.

Mock-ups are in [docs/ui-mockups](docs/ui-mockups). Open `desktop/index.html` or `phone/index.html` to browse them. Product features build both layouts (phone and desktop), light and dark themes, and Firestore security rules for any data they add. Feature 3 is the exception: it is the personal release process, not a product screen.

## Order at a glance

| # | Feature | Depends on | Likely issue type | Status |
| --- | --- | --- | --- | --- |
| 1 | App shell, sign-in, and sign-out | — | Feature | Complete |
| 2 | Journal entries | 1 | Feature | |
| 3 | Release planning | 1 | Feature | |
| 4 | Journaling goal and dashboard | 2 | Feature | |
| 5 | Mood trend | 2 | Task | |
| 6 | Frequency goals | 4 | Feature | |
| 7 | Editing goals | 6 | Feature | |
| 8 | Accumulation goals | 6 | Feature | |
| 9 | Target value goals | 6, 5 (chart) | Feature | |
| 10 | Avoidance goals | 6 | Feature | |
| 11 | Resources | 6 | Task | |
| 12 | Archive and delete goals | 6 | Feature | |

**Why this order:** The journal comes first because it is self-contained and sets up the patterns every later feature uses: a Firestore collection with security rules, a list-and-detail screen in both layouts, and the 24-hour edit window. The personal release process comes next, once there is a usable feature to install, and before the rest of the product, so later features can be built and installed on personal devices. It depends on the app from feature 1, not on the journal's data. The journaling goal then adds the calendar period engine (day, week, month) and the dashboard, which frequency goals reuse. Frequency goals introduce goal records, the entry form, and entry corrections, so the other goal types only add what is unique to them. After feature 6, features 7 through 12 can be worked on in parallel, except that target value goals reuse the chart from the mood trend.

## Shared pieces

Each shared piece is built with the first feature that needs it, and later features reuse it.

| Shared piece | Built in |
| --- | --- |
| Theme (indigo palette, light and dark), layout breakpoint, navigation rail and bottom bar | 1 |
| Confirmation dialog (title, message, optional warning, Cancel and confirm actions, danger style) | 1 |
| Mood swatch and mood picker (colors in §6.2) | 2 |
| 24-hour edit window and local date and time handling (§4.2, §9 Time) | 2 |
| Empty-state layout | 2 |
| Calendar period engine and streaks of met periods (§3.3) | 4 |
| Dashboard panel layout and the dashboard "Today" indicator | 4 |
| Time chart (calendar-time axis, target lines, line breaks) | 5 |
| Goal records, goal details layout, phone goal tabs, entry form, entry list | 6 |
| Upcoming status (no logging until the start date) | 6 |
| Outcome badges and the closed state (§3.5) | 9 |
| Day-by-day streak calendar | 10 |

## Features

### 1. App shell, sign-in, and sign-out

**Status:** Complete

**Intent:** I want a signed-out user to see the redesigned sign-in screen and a signed-in user to land in a navigation shell with Dashboard, Journal, Archive, and Sign Out (a rail on desktop and a bottom bar on phone), where Sign Out asks for confirmation, so that every later feature has a place to live (§2, §7.5, §9).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `sign-in.html` | `sign-in.html` |
| `dialog-sign-out.html` | `dialog-sign-out.html` |
| Navigation rail on any screen, e.g. `dashboard-empty.html` | Bottom bar on any screen, e.g. `dashboard-empty.html` |

**Notes:**
- `lib/ui/auth/login_screen.dart`, `AuthService`, and the placeholder phone and desktop scaffolds already exist. This feature restyles the login screen to match the mock-up, switches between it and the shell on auth state, and replaces the placeholder shells.
- Dashboard, Journal, and Archive can be placeholders until their features land.
- Sets up the app theme from the mock-ups and the baseline Firestore rules (each user reads and writes only their own data), with emulator tests for the rules.
- Builds the shared confirmation dialog.

### 2. Journal entries

**Intent:** I want to write, list, view, and edit journal entries with a subject, a 1–5 mood, and text, make entries private or public with Show Content, and get a random I'm Stuck prompt while writing, so that I can capture how I feel in the moment (§6.1–§6.4, §7.3).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `journal.html` | `journal.html`, `journal-entry.html` |
| `journal-private.html` | `journal-private.html` |
| `journal-editor.html` | `journal-editor.html` |
| `journal-empty.html` | `journal-empty.html` |

**Notes:**
- Builds the mood swatch and picker, the 24-hour edit window, and the empty-state layout.
- Includes the shared prompt list in Firestore (read-only to signed-in users) and the at least 100 starting prompts. How the prompts are loaded into the emulator and production is a question for capture-intent.
- No backdating and no deleting of journal entries (§6.3).
- The journaling goal pill in the Journal header arrives with feature 4.

### 3. Release planning

**Intent:** I want a versioning process that stamps the app, production Android and macOS builds I can install on my own devices, and a generated `CHANGELOG.md`, so that I can release this app to myself without submitting it to a store.

**Mock-ups:** None. Version stamping is the only part that may show in the UI, and there is no mock-up for it yet.

**Notes:**
- This is a release process for this app, not a product screen. It adds no Firestore data.
- Personal install only. No Play Store or Mac App Store submission, and no public distribution.
- Versioning includes stamping the build. Showing that version is the only part that may appear in the UI. Where it appears is a question for capture-intent. An account or settings page stays out of scope (§10).
- Production builds for Android and macOS, installable on personal devices. Signing only as far as those devices need, not for store review.
- Generates `CHANGELOG.md`. How the changelog is produced is a question for capture-intent.
- `pubspec.yaml` already has a version (`0.1.0+1`). This feature defines how that version is chosen, stamped, and shown.
- Any skills this needs are local to this repository and can be created when the work starts.

### 4. Journaling goal and dashboard

**Intent:** I want every user to get a once-per-day journaling goal on first sign-in, see its progress as the first panel on a dashboard, and change its count and period on the Journaling Goal page with the history rules for interrupted periods, so that journaling becomes a habit I can track (§3.3, §6.5, §7.1).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `dashboard-empty.html` | `dashboard-empty.html` |
| `dashboard.html` (journaling panel only) | `dashboard.html` (journaling panel only) |
| `journaling-goal.html` | `journaling-goal.html` |

**Notes:**
- Builds the calendar period engine: day, week (Sunday through Saturday), and month periods in local time, partial first periods, in-progress periods, and streaks of met periods. Frequency and accumulation goals reuse it.
- Builds the dashboard page, the panel layout, and the "Today" indicator.
- Adds the goal pill to the Journal header.
- The Add Goal button can be hidden or disabled until feature 6.
- Revisit using `provider` for dependency injection when the goals repository is created. The journal repository is still passed through constructors.

### 5. Mood trend

**Intent:** I want a mood trend chart with 30-day, 90-day, and one-year ranges that plots daily or weekly average moods in their colors on a calendar-time axis, with gaps and line breaks after 7 or more empty days, so that I can see how my mood changes over time (§6.2, §7.3).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `mood-trend.html` | `mood-trend.html` |
| `mood-trend-empty.html` | `mood-trend-empty.html` |

**Notes:**
- Builds the shared time chart, which target value goals reuse.
- On phone, the 30-day and one-year views scroll sideways with the mood axis pinned.
- Small enough to file as a single task.

### 6. Frequency goals

**Intent:** I want to add a frequency goal (a count per day, week, or month), log it from its dashboard panel with Done or Add details, open its details to see period history, streaks, and entries, and edit or delete an entry within 24 hours with confirmation, so that I can track habits like "exercise 4 times per week" (§3.1–§3.3, §4, §7.1, §7.2).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `goal-add-frequency.html` | `goal-add-frequency.html` |
| `dashboard.html` (frequency and upcoming panels) | `dashboard.html` (frequency and upcoming panels) |
| `goal-frequency.html` | `goal-frequency.html` |
| `dialog-entry-details.html` | `entry-details.html` |
| `dialog-entry-edit.html` (shown for an accumulation entry) | `entry-edit.html` (shown for an accumulation entry) |
| `goal-upcoming.html` (the upcoming state; the day strip comes with feature 10) | `goal-upcoming.html` |

**Notes:**
- Builds goal records, the Add Goal form (frequency fields only, with the other type cards disabled or hidden until their features), the goal details layout, the phone goal tabs, the entry form, and the entry list.
- Entries store the local date and time as entered plus an absolute creation timestamp (§9 Time). Period results are calculated from raw entries, never stored (§8).
- Includes the date and time limits (no future entries, at most 7 days back, not before the start date) and the upcoming status.
- Deleting an entry uses the shared confirmation dialog. There's no separate mock-up for it.

### 7. Editing goals

**Intent:** I want to edit a goal according to its status, changing every field while it is upcoming and only the name, description, and target going forward while it is active, with past periods judged against the target in effect at the time, so that I can adjust goals without rewriting my history (§3.4, §8 Target history).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `goal-edit.html` | `goal-edit.html` |
| `goal-edit-upcoming.html` | `goal-edit-upcoming.html` |
| — | `goal-menu.html` (Edit item) |

**Notes:**
- Adds the target history that the period engine uses to judge each period.
- Closed and archived goals can't be edited (§3.4). Those states arrive in features 9, 10, and 12, so each of those confirms that Edit is hidden.

### 8. Accumulation goals

**Intent:** I want to add an accumulation goal (an amount and unit per day, week, or month), log amounts from a short entry form with the value focused, and see each period's total against the target in its details, so that I can track goals like "read 300 pages per month" (§3.2, §7.1, §7.2).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `goal-add-accumulation.html` | `goal-add-accumulation.html` |
| `dashboard.html` (accumulation panel) | `dashboard.html` (accumulation panel) |
| `dialog-log-entry.html` | `entry-form.html` |
| `goal-accumulation.html` | `goal-accumulation.html` |
| `dialog-entry-edit.html` | `entry-edit.html` |

**Notes:**
- Adds the value field to the entry form, with decimals allowed and values greater than 0 (§3.2 Number rules).

### 9. Target value goals

**Intent:** I want to add a target value goal (a starting value, target value, unit, and target date), log values, see progress and a chart with the target and date marked, and have the goal become Achieved when it reaches the target or Missed and closed when the date passes, so that I can track goals like "lose 20 pounds by Dec 31" (§3.2, §3.5, §7.1, §7.2).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `goal-add.html` | `goal-add.html` |
| `dashboard.html` (target value and closed Missed panels) | `dashboard.html` (target value and closed Missed panels) |
| `goal-target-value.html` | `goal-target-value.html` |
| `goal-closed-missed.html` | `goal-closed-missed.html` |
| `dialog-log-entry.html` (with the goal's unit) | `entry-form.html` (with the goal's unit) |

**Notes:**
- Builds outcome badges and the closed state: no logging, no Edit, and entries keep their 24-hour window, with the outcome recalculated after a correction.
- Reuses the time chart from feature 5.
- The latest value comes from the entry with the latest date and time, not the most recently saved one.

### 10. Avoidance goals

**Intent:** I want to add an avoidance goal, open-ended or with a streak target and optionally starting in the past, answer "Did you slip today?" on its panel, record slips with the three slip options when the goal has a target, and see current and longest streaks with a day-by-day calendar, so that I can track goals like "no alcohol" or "Dry January" (§3.2, §3.5, §7.1, §7.2).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `goal-add-avoidance.html` | `goal-add-avoidance.html` |
| `dashboard.html` (avoidance panels and the "No" snackbar) | `dashboard.html` (avoidance panels) |
| `dialog-slip.html` | `dialog-slip.html` |
| `goal-avoidance.html` | `goal-avoidance.html` |
| `dialog-slip-edit.html` | `slip-edit.html` |
| `goal-closed.html` | `goal-closed.html` |
| `goal-upcoming.html` (day strip) | `goal-upcoming.html` (day strip) |

**Notes:**
- Builds the day-by-day streak calendar.
- Covers all slip cases: open-ended (confirm only), targeted with no outcome (three options), and Missed by option 2 (later slips reset the streak without asking). Only the targeted case has a mock-up.
- Deleting a slip restores the streak and can reopen a closed goal.
- The phone mock-ups don't show the "No" affirmation yet. Use the desktop wording as the guide.

### 11. Resources

**Intent:** I want to add, view, edit, and delete resources on a goal (a required subject, an optional URL, and an optional description), newest first and read-only once the goal is archived, so that I can keep reference material next to each goal (§5, §7.2).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `dialog-resource.html` | `resource-form.html` |
| Resources card in `goal-frequency.html` | Resources tab in `goal-frequency.html` |

**Notes:**
- Deleting a resource uses the shared confirmation dialog.
- Small enough to file as a single task.

### 12. Archive and delete goals

**Intent:** I want to archive a goal permanently, after a warning that it can't be undone, and browse archived goals read-only in the Archive, and to delete any upcoming, active, or archived goal after confirming, so that my dashboard holds only the goals I'm working on (§3.5, §7.2, §7.4).

**Mock-ups:**

| Desktop | Phone |
| --- | --- |
| `dialog-archive.html` | `dialog-archive.html` |
| `dialog-delete.html` | `dialog-delete.html` |
| — | `goal-menu.html` (Archive and Delete items) |
| `archive.html` | `archive.html`, `archive-goal.html` |
| `dialog-delete-archived.html` | `dialog-delete-archived.html` |
| `archive-empty.html` | `archive-empty.html` |

**Notes:**
- Deleting removes the goal with all of its entries and resources.
- The journaling goal can't be archived or deleted (§6.5).
- Closed goals show Archive as their main action (features 9 and 10).

## Non-functional requirements

There's no separate styling feature. Feature 3 is the personal release process. Each requirement in §8 and §9 is built into the features above:

| Requirement | Where it's handled |
| --- | --- |
| Flutter client with `package:material_ui/material_ui.dart` | Every feature |
| Phone and desktop layouts, light and dark themes | Theme and shells in 1, then every feature |
| Android and macOS builds, web for development only | Checked on both platforms as features land; production builds for personal install are feature 3 |
| Firebase Auth and Cloud Firestore | 1 (Auth and baseline rules), then each feature's collections |
| Security rules enforce privacy, prompts read-only | 1 (baseline), 2 (prompts), then each feature's collections, with emulator tests |
| No offline-specific work | Nothing to build. Use Firestore's default caching |
| Local time for periods and limits, with an absolute creation timestamp | 2 (journal timestamps), 4 (period engine), 6 (entries) |
| Raw entries and target history, no stored results | 4 and 6 (calculated results), 7 (target history) |
| Shared prompt list stored separately from user data | 2 |
| Data kept indefinitely, no purging | Nothing to build |
| Usability: logging in very few interactions | 6, 8, 9, and 10 (panel logging) |
