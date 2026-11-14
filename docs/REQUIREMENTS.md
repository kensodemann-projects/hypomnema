# Hypomnema — Requirements Document
**Version:** 1.0 (Draft)
**Status:** For Review

---

## 1. Purpose and Overview

A hypomnema is a note kept so it can be found again: a reminder, a memorandum, an excerpt, or a short record of something worth remembering.

Hypomnema is a personal application that helps each user meet daily, weekly, and monthly goals such as "meditate daily," "exercise four times per week," or "lose twenty pounds by the end of the year." Users record their activity against each goal, see how they are tracking, and keep resources related to each goal. The application also includes a journal with its own journaling goal.

Use of the application is tightly controlled. Only users who have been given an account can sign in.

---

## 2. Users and Accounts

The application has a single role: **User**. Every user has the same capabilities.

- Accounts are created by hand in the Firebase console. The application has no sign-up or self-registration.
- Users sign in with email and password. A user who has forgotten their password can request a password reset email from the sign-in screen.
- All data is fully private. A user can see and change only their own goals, tracking entries, resources, and journal entries. No data is shared between users.
- There is no administrator role and no administrative function inside the application. Administration happens in the Firebase console.

---

## 3. Goals

### 3.1 Goal Records

Each goal carries the following information:

- **Name** — A short name for the goal (e.g., "Exercise daily").
- **Description** — Optional. Longer text in which the user can record their own rules for the goal (e.g., "only count sessions of 30 minutes or more").
- **Type** — One of the four goal types in Section 3.2.
- **Target** — The type-specific target settings described in Section 3.2.
- **Start Date** — The date tracking begins. It defaults to today, and any goal type can start in the future (e.g., in November, a user plans to give up desserts for December). Avoidance goals can also start in the past, so an existing streak is reflected (e.g., a user who has avoided alcohol for two years). Other goal types cannot start in the past.
- **Status** — Upcoming, Active, or Archived (see Section 3.5).
- **Outcome** — For goal types that can end, None, Achieved, or Missed (see Section 3.5).

### 3.2 Goal Types

The first release supports four goal types. Additional types may be added later, based on usage.

**Frequency** — Do something a number of times per period (e.g., "meditate daily," "exercise four times per week").
- Target: a count and a period (day, week, or month).
- An entry records that the activity was done. It has no value.
- A period is met when the number of entries in it reaches the count. Additional entries in the same period are recorded and shown, but they are extra.

**Accumulation** — Reach a total amount per period (e.g., "exercise 30 minutes daily," "read 300 pages per month").
- Target: an amount, a unit (e.g., minutes, miles, pages), and a period (day, week, or month).
- An entry records an amount in the goal's unit.
- A period is met when the sum of the amounts in it reaches the target amount. Additional entries in the same period are recorded and shown, but they are extra.

**Target Value** — Reach a value by a date (e.g., "lose twenty pounds by the end of the year").
- Target: a unit (e.g., lb), a starting value, a target value, and a target date. Whether the goal is to increase or to decrease follows from comparing the starting value with the target value.
- An entry records the current value (e.g., today's weight).
- Progress is the share of the distance from the starting value to the target value covered by the most recently recorded value. For example, with a start of 200 lb, a target of 180 lb, and a latest value of 190 lb, progress is 50%.

**Avoidance** — Avoid doing something (e.g., "no alcohol").
- Target: optional. A goal with no target is open-ended (e.g., someone who wants to stop drinking for good). A goal with a target is a number of consecutive days (e.g., "Dry January," 31 days).
- The user records only slips. An entry records that a slip happened.
- The streak counts up automatically from the goal's start date, or from the most recent slip. A slip resets the streak, and the goal keeps running.
- The streak counts only completed days without a slip. The current day counts once it ends, at midnight. A slip resets the streak to 0, and the day of the slip does not count. For example, a 31-day goal that starts December 1 with no slips shows a streak of 0 during December 1, shows 1 starting at midnight, and becomes Achieved at midnight after December 31.

### 3.3 Periods

Frequency, accumulation, and journaling goals are measured in calendar periods based on the device's local time:

- **Day** — Midnight to midnight.
- **Week** — Sunday through Saturday.
- **Month** — The calendar month.

### 3.4 Changing a Goal

- **Name and description** can be changed at any time.
- **Type and period** cannot be changed after the goal is created. To change either, the user creates a new goal. (The journaling goal is an exception; see Section 6.5.)
- **Targets** can be changed. This covers the count, the amount, the target value, the target date, and the avoidance streak target. A target change applies to the current period and all later ones. Past periods keep the target that was in effect at the time, so the application must keep a history of each goal's targets.

### 3.5 Goal Lifecycle and Outcomes

A goal with a future start date is **Upcoming**. It is not yet in effect, so no entries can be created for it, and its start date can still be changed. On the start date it becomes **Active**, and its start date can no longer be changed.

A goal stays Active until the user archives it or deletes it. Recurring goals (frequency, accumulation, and open-ended avoidance) have no end date.

Some goals reach a natural end and get an outcome:

- **Target value goal reaches its target before the target date** — The goal is marked **Achieved**. It stays active and continues to accept entries, so the user can confirm the result holds (e.g., that their weight has stabilized) before archiving it.
- **Target value goal's date passes without reaching the target** — The goal is marked **Missed** and accepts no further entries. To try again, the user creates a new goal.
- **Avoidance goal with a target reaches its target streak** — The goal is marked **Achieved**.

Outcomes are always calculated from the goal's entries and target history. They are never stored as a separate fact that could disagree with the entries. As a result:

- Achieved means the target was reached at some point. Later entries do not undo it. For example, a target value goal stays Achieved when later weigh-ins drift away from the target, and a slip on January 5 does not undo a completed Dry January.
- A correction can change an outcome. If the user backdates a slip into a completed streak, or edits or deletes the entry that reached a target value, the outcome is recalculated and may no longer be Achieved.

A goal with an Achieved or Missed outcome stays on the dashboard with an outcome badge until the user archives it.

The user can take two actions on a goal:

- **Archive** — Stops tracking the goal and keeps its history for viewing. Archiving is permanent. Before archiving, the application warns the user that it cannot be undone and gives them a chance to cancel. An archived goal, its tracking entries, and its resources are read-only. Archived goals cannot be unarchived.
- **Delete** — Permanently removes the goal and all of its tracking entries and resources. The application asks the user to confirm before deleting.

---

## 4. Tracking Entries

### 4.1 Entry Records

Every goal type uses the same entry structure:

- **Date** — Defaults to today. The user can backdate an entry by up to 7 days.
- **Time** — Defaults to now. The user can change it, but not to a time later than now.
- **Value** — A number with no other text. It is required for accumulation goals (the amount) and target value goals (the current value). Frequency entries and avoidance slips have no value.
- **Memo** — Optional. A short single line describing the entry (e.g., "Boxing," "Vigorous walk," "Bob kicked my butt"). Entries do not have long-form text.

### 4.2 Entry Rules

Mistakes should be easy to correct, but only within limits:

- **Backdating** — An entry's date can be up to 7 days in the past, but not before the goal's start date.
- **Editing** — An entry can be edited within 24 hours of when it was created.
- **Deleting** — An entry, including an avoidance slip, can be deleted within 24 hours of when it was created. A deleted entry no longer counts toward the goal. Deleting a mistaken slip restores the streak.

---

## 5. Resources

Each goal can have **Resources**. These are reference material the user finds useful for the goal, such as a link to boxing techniques, a workout routine, or an article about alternating heavy and light workouts. Resources belong to the goal, not to individual tracking entries.

Each resource has:

- **Subject** — Required.
- **URL** — Optional.
- **Description** — Optional. Long-form text.

The application stores the date and time each resource was created and uses it to sort resources newest first. The timestamp is not displayed.

While a goal is active, the user can create, view, edit, and delete its resources at any time. Once the goal is archived, its resources are read-only.

---

## 6. Journaling

Journaling is a separate feature from goals. Each user has one journal and one journaling goal.

### 6.1 Journal Entry Records

- **Date/Time** — Set automatically when the entry is first saved. It is not changed when the entry is edited.
- **Subject** — Optional. When it is blank, lists show the first line of the journal text, shortened to fit.
- **Mood** — Required. A value from 1 to 5 (see Section 6.2).
- **Journal** — Required. Long-form text.
- **Private** — Whether the entry is private (see Section 6.3).

### 6.2 Mood

- Mood is a whole number from 1 to 5, shown as a number.
- When entering a mood, only the ends are labeled: 1 is "Awful" and 5 is "Great." The values in between mean whatever the user wants them to mean.
- Each mood value has a color on a gradient from red (1), through yellow (3), to green (5). Values 2 and 4 use the colors in between (orange and yellow-green). The exact colors will be chosen during the mock-up session.
- The number must be easy to read against its color in both light and dark themes.
- Color is never the only indicator of mood. The number is always shown, so moods stay readable for users with red-green color blindness.
- Wherever a mood is displayed, it uses the same look as in the mood picker (e.g., a yellow square containing a 3), without the labels.
- Any average mood is rounded to the nearest whole number and displayed the same way.

### 6.3 Journal Entry Rules

Journaling is meant to capture the moment:

- **No backdating** — The date and time are always set by the system.
- **Editing** — An entry can be edited within 24 hours of when it was created.
- **No deletion** — Instead of deleting an entry, the user can make it private.

**Private entries** keep sensitive content off the screen until the user feels safe viewing it:

- In the journal list, a private entry shows its date, time, and mood, with a private indicator in place of the subject.
- On the entry's details page, only the date, time, and mood are shown. The subject and journal text are replaced by a private indicator.
- **Show Content** reveals the subject and text for that viewing only. It does not change the private setting.
- The user can switch an entry between private and public at any time.
- A private entry still counts toward the journaling goal, and its mood is included in the mood trend.
- A private entry that is still within its 24-hour editing window can be edited after the user selects Show Content.

### 6.4 "I'm Stuck" Prompts

While writing a journal entry, the user can select **I'm Stuck** to get a random prompt to write about.

- Selecting I'm Stuck again shows a different random prompt.
- The current prompt stays visible in the editor for the rest of the editing session. It is not saved with the entry.
- Prompts come from a single list shared by all users and stored in Cloud Firestore. For now the list is maintained through the Firebase console. The way prompts are stored must not prevent a future in-app admin page from managing them, but no admin feature is planned.
- Repeats are kept rare by starting with a large enough list and picking prompts with a uniform random choice.
- The starting list has at least 100 prompts. They are written as part of building this feature, not listed in this document.

### 6.5 Journaling Goal

- Every user has exactly one journaling goal. It is required, and it cannot be archived or deleted.
- It works like a frequency goal: a count and a period (day, week, or month), using the calendar periods in Section 3.3.
- The default is once per day.
- The user changes the journaling goal on the **Journaling Goal** page. Unlike other goals, both the count and the period can be changed.
- A change starts with the period that contains the moment of the change, and every journal entry already in that period counts toward the new setting. For example, if a user who has journaled daily changes the goal on the 15th to "20 times per month," the entries from the first 15 days of that month count toward the 20. Periods that ended before the change keep their results under the old setting.
- The journaling goal's history lists each period, newest first, under the setting that judged it. A marker at the point of change shows the new setting and the date it took effect. In the example above, the history shows November (20 per month) in progress, then "Goal changed to 20 per month on Nov 15," then the daily results for November 14, 13, and earlier. Entries from November 1 through 14 appear both in those daily results and in the November total. The marker explains the overlap.

---

## 7. Views

### 7.1 Dashboard

The dashboard is the home screen, and it is where tracking happens in the first release. It shows one panel per goal, in this order:

1. The journaling goal.
2. Every upcoming and active goal, in the order the goals were created. The user cannot reorder panels.

This includes goals with an Achieved or Missed outcome that have not been archived. An upcoming goal's panel shows its start date (e.g., "Starts Dec 1") and has no progress or logging controls. Each panel shows an indicator when the goal has an entry with today's date. Each panel shows progress for the current period and offers a quick way to log:

| Goal type | Progress shown | Logging from the panel |
| --- | --- | --- |
| Frequency | Entries in the current period against the count (e.g., "3 of 4 this week") | **Done** logs an entry for now in one tap. **Add details** opens the entry form for a memo, a different time, or a backdated date. |
| Accumulation | Amount in the current period against the target (e.g., "105 of 150 minutes this week") | Opens a short entry form with the value field focused, the date and time prefilled, and an optional memo. |
| Target Value | Latest value against the target, percentage progress, and time remaining | Same as accumulation. |
| Avoidance | Current streak (e.g., "12 days"), or streak against the target (e.g., "12 of 31") | Asks "Did you slip today?" **Yes** asks the user to confirm, because a slip resets the streak, then records the slip with an optional memo. **No** shows a brief affirmation and records nothing. |
| Journaling | Entries in the current period against the count, plus the most recent mood | **Write** opens the journal editor. |

The dashboard also has an **Add Goal** action. Selecting a goal panel opens that goal's details.

### 7.2 Goal Details

- **Header** — Name, description, type, current target, current progress (the same summary as the panel), and any outcome badge.
- **History**
  - Frequency and accumulation: a list of past periods showing whether each was met (e.g., "Week of Nov 1: 4 of 4 ✓"), plus the current and longest streaks of met periods.
  - Target value: a line chart of recorded values over time, with the target value and target date marked.
  - Avoidance: the current streak, the longest streak, and a list of slips.
- **Entries** — All tracking entries, newest first, showing date, time, value, and memo. Edit and delete are offered only while the entry is within its 24-hour window.
- **Resources** — The goal's resources, newest first, with add, edit, and delete. They are read-only once the goal is archived.
- **Actions** — Edit goal (name, description, and targets), Archive (with confirmation), and Delete (with confirmation).

### 7.3 Journal

- **Journal List** — Entries newest first, each showing date, time, mood, and subject (or the first line of the text). Private entries show a private indicator in place of the subject.
- **Entry Details** — The full entry, an Edit option while within the 24-hour window, Make Private or Make Public, and Show Content for private entries.
- **Journal Editor** — Subject, mood picker, journal text, and I'm Stuck.
- **Mood Trend** — A chart of mood over time, with a choice of range (e.g., the last 30 days, 90 days, or year). Private entries are included.
- **Journaling Goal** — Progress toward the journaling goal and access to the Journaling Goal page.

### 7.4 Archive

A list of archived goals. Selecting one opens its goal details, which are read-only.

### 7.5 Navigation and Layout

Phone and desktop each have their own layout. A phone layout stretched to desktop width does not meet this requirement. The top-level areas are **Dashboard**, **Journal**, and **Archive**. A **Sign Out** action is part of the navigation in both layouts.

- **Phone** — A bottom navigation bar for the top-level areas. Goal details, the entry form, and the journal editor open as full-screen pages.
- **Desktop** — A side navigation rail with list-and-detail layouts. For example, the dashboard shows panels in a grid and opens a goal's details beside them, and the journal shows the entry list beside the selected entry. Forms open in dialogs or side panels instead of full pages.

This layout is a concept. It will be refined in a separate mock-up session and may change.

---

## 8. Data Design Constraints

These constraints keep the first release from blocking planned or likely future work:

- **Raw entries** — Tracking entries are stored as raw, timestamped records. Period results (met or not met, totals, streaks) and outcomes are calculated from the entries and the target history, not stored as summary values. This avoids edge cases where a stored result disagrees with the entries, and keeps nested goals possible later (e.g., "30 minutes per day, 5 days per week"). If calculating these results becomes a performance problem, storing them may be reconsidered.
- **Target history** — Each goal keeps the history of its targets, so every period is judged against the target that was in effect at the time.
- **Shared prompts** — The prompt list is stored separately from user data, in a structure that a future admin page could manage.

---

## 9. Non-Functional Requirements

- **Client** — The client is a Flutter application. UI widgets come from `package:material_ui/material_ui.dart`.
- **Platforms** — The primary builds are Android (phone) and macOS (desktop). The web build is for development only.
- **Backend** — The application uses Firebase. Authentication uses Firebase Auth with email and password. Persistent data lives in Cloud Firestore.
- **Offline** — The application relies on Firestore's built-in offline behavior. Users can read their data and record entries while offline, and changes sync when the connection returns.
- **Time** — All dates, periods, and time limits (the 7-day backdating limit and the 24-hour edit and delete windows) use the device's local time.
- **Security** — Firestore security rules enforce privacy on the server. Each user can read and write only their own data. The prompt list is read-only to all signed-in users. Privacy is a security boundary, not a UI convenience.
- **Data retention** — All data is kept indefinitely, with no automatic archiving or purging. Purging may be needed in a later release.
- **Usability** — Workflows must be clear without training. Recording a typical entry should take very few interactions.

---

## 10. Out of Scope

The following are out of scope for the first release:

- Self-registration and account deletion in the application
- An account or settings page, including changing the password in the app
- An administrator role or administrative pages, including managing prompts in the app
- Sharing data between users
- Reminders or notifications of any kind
- Search
- A separate tracking page (tracking happens on the dashboard)
- Goal types other than frequency, accumulation, target value, and avoidance
- Nested goals (e.g., "30 minutes per day, 5 days per week")
- End dates on recurring goals
- Pausing goals, unarchiving goals, or a separate Complete action
- Backdating journal entries, or deleting journal entries
- Saving the "I'm Stuck" prompt with a journal entry
- Data export and data purging
- iOS, Windows, and Linux builds, and the web as a production platform

---

## 11. Open Questions

None at this time.
