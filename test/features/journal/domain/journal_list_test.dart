import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/utils/edit_window.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/domain/journal_list.dart';

JournalEntry _entry(String localDateTime) {
  return JournalEntry.restore(
    id: localDateTime,
    subject: 'Note',
    mood: 3,
    text: 'hello',
    private: false,
    localDateTime: localDateTime,
    createdAt: DateTime.utc(2026, 11, 14),
  );
}

void main() {
  final saturday = DateTime(2026, 11, 14, 12);
  final monday = DateTime(2026, 11, 16, 12);

  test('Given the mock-up clock on Saturday, November 14, 2026, when entries are grouped newest first, then row labels and week headings match', () {
    // Given
    const rows = [
      ('2026-11-14T08:02:00', 'Today · 8:02 AM', 'This week'),
      ('2026-11-13T21:40:00', 'Yesterday · 9:40 PM', 'This week'),
      ('2026-11-12T22:15:00', 'Thu, Nov 12 · 10:15 PM', 'This week'),
      ('2026-11-08T18:12:00', 'Sun, Nov 8 · 6:12 PM', 'This week'),
      ('2026-11-06T21:50:00', 'Fri, Nov 6 · 9:50 PM', 'Last week'),
      ('2026-10-25T09:00:00', 'Sun, Oct 25 · 9:00 AM', 'Week of Oct 25'),
      ('2025-12-28T09:00:00', 'Sun, Dec 28 · 9:00 AM', 'Week of Dec 28, 2025'),
    ];
    final entries = [for (final row in rows) _entry(row.$1)];

    // When
    final groups = groupJournalEntries(entries: entries, now: saturday);

    // Then
    for (var index = 0; index < rows.length; index++) {
      expect(journalRowWhen(entries[index], saturday), rows[index].$2);
    }
    expect(groups.map((group) => group.heading), [
      'This week',
      'Last week',
      'Week of Oct 25',
      'Week of Dec 28, 2025',
    ]);
    expect(
      groups[0].entries.map((entry) => entry.localDateTime),
      rows.take(4).map((row) => row.$1),
    );
    expect(groups[1].entries.single.localDateTime, rows[4].$1);
    expect(groups[2].entries.single.localDateTime, rows[5].$1);
    expect(groups[3].entries.single.localDateTime, rows[6].$1);
    for (final group in groups) {
      expect(group.entries, isNotEmpty);
    }
  });

  test('Given the clock on Monday, November 16, 2026, when Sunday and Saturday are grouped, then Sunday is Yesterday in This week and Saturday is Last week', () {
    // Given
    final sunday = _entry('2026-11-15T09:00:00');
    final saturdayEntry = _entry('2026-11-14T08:02:00');

    // When
    final groups = groupJournalEntries(
      entries: [sunday, saturdayEntry],
      now: monday,
    );

    // Then
    expect(journalRowWhen(sunday, monday), 'Yesterday · 9:00 AM');
    expect(journalRowWhen(saturdayEntry, monday), 'Sat, Nov 14 · 8:02 AM');
    expect(groups.map((group) => group.heading), ['This week', 'Last week']);
    expect(groups[0].entries.single.localDateTime, sunday.localDateTime);
    expect(groups[1].entries.single.localDateTime, saturdayEntry.localDateTime);
  });

  test('Given midnight and noon, when the row label is formatted, then the times are 12:00 AM and 12:00 PM', () {
    // Given
    final midnight = _entry('2026-11-14T00:00:00');
    final noon = _entry('2026-11-14T12:00:00');

    // When, then
    expect(journalRowWhen(midnight, saturday), 'Today · 12:00 AM');
    expect(journalRowWhen(noon, saturday), 'Today · 12:00 PM');
  });

  test('Given the mock-up entry, when the detail and phone bar are formatted, then the desktop date includes the year and the phone date does not', () {
    // Given
    final entry = _entry('2026-11-14T08:02:00');

    // When, then
    expect(
      journalDetailWhen(entry, includeYear: true),
      'Saturday, November 14, 2026 · 8:02 AM',
    );
    expect(
      journalDetailWhen(entry, includeYear: false),
      'Saturday, November 14 · 8:02 AM',
    );
    expect(journalEntryBarTitle(entry), 'Sat, Nov 14');
  });

  test(
    'Given no entries, when they are grouped, then there are no headings',
    () {
      // Given, when
      final groups = groupJournalEntries(entries: const [], now: saturday);

      // Then
      expect(groups, isEmpty);
    },
  );

  test('Given an entry created at 8:02 AM on November 14, when it is viewed at noon that day, then the note says 8:02 AM tomorrow', () {
    // Given
    final createdAt = DateTime(2026, 11, 14, 8, 2);
    final now = DateTime(2026, 11, 14, 12);

    // When, then
    expect(
      journalEditableUntilNote(createdAt: createdAt, now: now),
      'Editable until 8:02 AM tomorrow',
    );
  });

  test('Given an entry created at 11:00 PM on November 13, when it is viewed at 10:00 AM the next day, then the note says 11:00 PM today', () {
    // Given
    final createdAt = DateTime(2026, 11, 13, 23);
    final now = DateTime(2026, 11, 14, 10);

    // When, then
    expect(
      journalEditableUntilNote(createdAt: createdAt, now: now),
      'Editable until 11:00 PM today',
    );
  });

  test('Given now equal to a deadline on that same local day, when the note is read, then it is still present and says today', () {
    // Given
    final createdAt = DateTime(2026, 11, 14, 8, 2);
    final now = editWindowDeadline(createdAt);

    // When, then
    expect(
      journalEditableUntilNote(createdAt: createdAt, now: now),
      'Editable until 8:02 AM today',
    );
  });

  test('Given now one microsecond after that deadline, when the note is read, then it is absent', () {
    // Given
    final createdAt = DateTime(2026, 11, 14, 8, 2);
    final now = editWindowDeadline(createdAt)
        .add(const Duration(microseconds: 1));

    // When, then
    expect(journalEditableUntilNote(createdAt: createdAt, now: now), isNull);
  });

  // This simulates situations where the end date is beyond tomorrow. This could happen on a DST change or if we
  // modify the window to be longer than 24 hours.
  test('Given an entry created a day in the future, when the note is read, then the note names the exact day', () {
    // Given
    final createdAt = DateTime(2026, 2, 7, 23, 30);
    final now = DateTime(2026, 2, 6, 23, 30);

    // When, then
    expect(
      journalEditableUntilNote(createdAt: createdAt, now: now),
      'Editable until 11:30 PM Feb 8',
    );
  });

  test('Given a creation instant with seconds, when the note is read, then the displayed time drops the seconds', () {
    // Given
    final createdAt = DateTime(2026, 11, 14, 8, 2, 30);
    final now = DateTime(2026, 11, 14, 12);

    // When, then
    expect(
      journalEditableUntilNote(createdAt: createdAt, now: now),
      'Editable until 8:02 AM tomorrow',
    );
  });

  test('Given a week with no entries, when later weeks are grouped, then that week has no heading', () {
    // Given
    final entries = [
      _entry('2026-11-14T08:02:00'),
      _entry('2026-10-25T09:00:00'),
    ];

    // When
    final groups = groupJournalEntries(entries: entries, now: saturday);

    // Then
    expect(groups.map((group) => group.heading), [
      'This week',
      'Week of Oct 25',
    ]);
  });
}
