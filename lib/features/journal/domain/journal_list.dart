import 'package:hypomnema/core/utils/edit_window.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';

class JournalWeekGroup {
  const JournalWeekGroup({required this.heading, required this.entries});

  final String heading;
  final List<JournalEntry> entries;
}

List<JournalWeekGroup> groupJournalEntries({
  required List<JournalEntry> entries,
  required DateTime now,
}) {
  final today = now.toLocal();
  final groups = <JournalWeekGroup>[];
  List<JournalEntry>? currentEntries;
  DateTime? currentSunday;

  for (final entry in entries) {
    final sunday = _sunday(DateTime.parse(entry.localDateTime));
    if (currentSunday == null || !_sameDay(sunday, currentSunday)) {
      final entriesInWeek = <JournalEntry>[];
      currentEntries = entriesInWeek;
      currentSunday = sunday;
      groups.add(
        JournalWeekGroup(
          heading: _weekHeading(sunday, today),
          entries: entriesInWeek,
        ),
      );
    }
    currentEntries!.add(entry);
  }
  return groups;
}

String journalRowWhen(JournalEntry entry, DateTime now) {
  final local = DateTime.parse(entry.localDateTime);
  final today = _date(now.toLocal());
  final day = _date(local);
  final label = switch (day) {
    _ when _sameDay(day, today) => 'Today',
    _ when _sameDay(day, _dayBefore(today)) => 'Yesterday',
    _ =>
      '${_weekdayAbbreviations[local.weekday - 1]}, '
          '${_monthAbbreviations[local.month - 1]} ${local.day}',
  };
  return '$label · ${_time(local)}';
}

String journalDetailWhen(JournalEntry entry, {required bool includeYear}) {
  final local = DateTime.parse(entry.localDateTime);
  final weekday = _weekdays[local.weekday - 1];
  final month = _months[local.month - 1];
  final date = includeYear
      ? '$weekday, $month ${local.day}, ${local.year}'
      : '$weekday, $month ${local.day}';
  return '$date · ${_time(local)}';
}

String journalEntryBarTitle(JournalEntry entry) {
  final local = DateTime.parse(entry.localDateTime);
  return '${_weekdayAbbreviations[local.weekday - 1]}, '
      '${_monthAbbreviations[local.month - 1]} ${local.day}';
}

/// Returns the "Editable until" sentence for [createdAt], or `null` when closed.
///
/// The clock time is the local time of the absolute deadline. The day word is
/// `today` on [now]'s local calendar day, `tomorrow` on the next day, and the
/// month and day when the deadline falls later.
String? journalEditableUntilNote({
  required DateTime createdAt,
  required DateTime now,
}) {
  if (!isWithinEditWindow(createdAt: createdAt, now: now)) {
    return null;
  }
  final deadline = editWindowDeadline(createdAt).toLocal();
  final day = _deadlineDayWord(deadline, now.toLocal());
  return 'Editable until ${_time(deadline)} $day';
}

String _deadlineDayWord(DateTime deadlineLocal, DateTime nowLocal) {
  final today = _date(nowLocal);
  final deadlineDay = _date(deadlineLocal);
  if (_sameDay(deadlineDay, today)) {
    return 'today';
  }
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  if (_sameDay(deadlineDay, tomorrow)) {
    return 'tomorrow';
  }
  final month = _monthAbbreviations[deadlineDay.month - 1];
  return '$month ${deadlineDay.day}';
}

const _weekdayAbbreviations = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

DateTime _date(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _dayBefore(DateTime day) {
  return DateTime(day.year, day.month, day.day - 1);
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _sunday(DateTime local) {
  final day = _date(local);
  return DateTime(day.year, day.month, day.day - (day.weekday % 7));
}

String _weekHeading(DateTime sunday, DateTime today) {
  final thisSunday = _sunday(today);
  if (_sameDay(sunday, thisSunday)) {
    return 'This week';
  }
  if (_sameDay(
    sunday,
    DateTime(thisSunday.year, thisSunday.month, thisSunday.day - 7),
  )) {
    return 'Last week';
  }
  final month = _monthAbbreviations[sunday.month - 1];
  if (sunday.year == today.year) {
    return 'Week of $month ${sunday.day}';
  }
  return 'Week of $month ${sunday.day}, ${sunday.year}';
}

String _time(DateTime local) {
  final hour = local.hour % 12;
  final shown = hour == 0 ? 12 : hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$shown:$minute $suffix';
}
