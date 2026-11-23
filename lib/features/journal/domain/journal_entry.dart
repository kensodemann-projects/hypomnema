class InvalidJournalEntryException implements Exception {
  const InvalidJournalEntryException();
}

class JournalEntry {
  const JournalEntry._({
    required this.id,
    required this.subject,
    required this.mood,
    required this.text,
    required this.private,
    required this.localDateTime,
    required this.createdAt,
  });

  final String id;
  final String? subject;
  final int mood;
  final String text;
  final bool private;
  final String localDateTime;
  final DateTime createdAt;

  static JournalEntry create({
    required String id,
    String? subject,
    required int mood,
    required String text,
    required bool private,
    required DateTime now,
  }) {
    final trimmedText = text.trim();
    if (id.isEmpty || !_isMood(mood) || trimmedText.isEmpty) {
      throw const InvalidJournalEntryException();
    }
    return JournalEntry._(
      id: id,
      subject: _subject(subject),
      mood: mood,
      text: trimmedText,
      private: private,
      localDateTime: _formatLocalDateTime(now.toLocal()),
      createdAt: now.toUtc(),
    );
  }

  JournalEntry revise({
    String? subject,
    required int mood,
    required String text,
    required bool private,
  }) {
    final trimmedText = text.trim();
    if (!_isMood(mood) || trimmedText.isEmpty) {
      throw const InvalidJournalEntryException();
    }
    return JournalEntry._(
      id: id,
      subject: _subject(subject),
      mood: mood,
      text: trimmedText,
      private: private,
      localDateTime: localDateTime,
      createdAt: createdAt,
    );
  }
}

bool _isMood(int mood) => mood >= 1 && mood <= 5;

String? _subject(String? subject) {
  if (subject == null) {
    return null;
  }
  final trimmed = subject.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _formatLocalDateTime(DateTime local) {
  String two(int value) => value.toString().padLeft(2, '0');
  final year = local.year.toString().padLeft(4, '0');
  return '$year-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
