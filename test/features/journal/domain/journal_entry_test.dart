import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';

void main() {
  final now = DateTime(2026, 11, 23, 16, 35, 4);

  test('Given a local clock instant, when an entry is created, then localDateTime is the wall clock and createdAt is that instant in UTC', () {
    // Given
    final instant = now;

    // When
    final entry = JournalEntry.create(
      id: 'entry-1',
      subject: 'Note',
      mood: 3,
      text: 'hello',
      private: false,
      now: instant,
    );

    // Then
    expect(entry.localDateTime, '2026-11-23T16:35:04');
    expect(entry.createdAt, instant.toUtc());
    expect(entry.createdAt.isUtc, isTrue);
  });

  test('Given a subject and text with surrounding spaces, when an entry is created, then both are trimmed', () {
    // Given, when
    final entry = JournalEntry.create(
      id: 'entry-1',
      subject: '  Note  ',
      mood: 3,
      text: '  hello  ',
      private: false,
      now: now,
    );

    // Then
    expect(entry.subject, 'Note');
    expect(entry.text, 'hello');
  });

  test('Given an empty subject, when an entry is created, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.create(
        id: 'entry-1',
        subject: '',
        mood: 3,
        text: 'hello',
        private: false,
        now: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given a whitespace subject, when an entry is created, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.create(
        id: 'entry-1',
        subject: '   ',
        mood: 3,
        text: 'hello',
        private: false,
        now: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test(
    'Given moods 1 and 5, when entries are created, then both are stored',
    () {
      // Given, when
      final low = JournalEntry.create(
        id: 'entry-1',
        subject: 'Note',
        mood: 1,
        text: 'hello',
        private: false,
        now: now,
      );
      final high = JournalEntry.create(
        id: 'entry-2',
        subject: 'Note',
        mood: 5,
        text: 'hello',
        private: true,
        now: now,
      );

      // Then
      expect(low.mood, 1);
      expect(high.mood, 5);
    },
  );

  test('Given a mood outside 1 to 5, when an entry is created, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.create(
        id: 'entry-1',
        subject: 'Note',
        mood: 0,
        text: 'hello',
        private: false,
        now: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
    expect(
      () => JournalEntry.create(
        id: 'entry-1',
        subject: 'Note',
        mood: 6,
        text: 'hello',
        private: false,
        now: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given empty or whitespace text, when an entry is created, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.create(
        id: 'entry-1',
        subject: 'Note',
        mood: 3,
        text: '',
        private: false,
        now: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
    expect(
      () => JournalEntry.create(
        id: 'entry-1',
        subject: 'Note',
        mood: 3,
        text: '   ',
        private: false,
        now: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given an empty id, when an entry is created, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.create(
        id: '',
        subject: 'Note',
        mood: 3,
        text: 'hello',
        private: false,
        now: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given an entry, when it is revised, then subject, mood, text, and private change and the id and times stay', () {
    // Given
    final entry = JournalEntry.create(
      id: 'entry-1',
      subject: 'Note',
      mood: 2,
      text: 'hello',
      private: false,
      now: now,
    );

    // When
    final revised = entry.revise(
      subject: '  Later  ',
      mood: 5,
      text: '  updated  ',
      private: true,
    );

    // Then
    expect(revised.id, entry.id);
    expect(revised.subject, 'Later');
    expect(revised.mood, 5);
    expect(revised.text, 'updated');
    expect(revised.private, isTrue);
    expect(revised.localDateTime, entry.localDateTime);
    expect(revised.createdAt, entry.createdAt);
  });

  test('Given stored fields, when an entry is restored, then the wall-clock string stays and createdAt is that instant in UTC', () {
    // Given
    final createdAt = DateTime(2026, 11, 23, 16, 35, 4);
    const localDateTime = '2026-11-14T08:02:00';

    // When
    final entry = JournalEntry.restore(
      id: 'entry-1',
      subject: '  Note  ',
      mood: 4,
      text: '  hello  ',
      private: true,
      localDateTime: localDateTime,
      createdAt: createdAt,
    );

    // Then
    expect(entry.id, 'entry-1');
    expect(entry.subject, 'Note');
    expect(entry.mood, 4);
    expect(entry.text, 'hello');
    expect(entry.private, isTrue);
    expect(entry.localDateTime, localDateTime);
    expect(entry.createdAt, createdAt.toUtc());
    expect(entry.createdAt.isUtc, isTrue);
  });

  test('Given a blank subject, when an entry is restored, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.restore(
        id: 'entry-1',
        subject: '   ',
        mood: 3,
        text: 'hello',
        private: false,
        localDateTime: '2026-11-14T08:02:00',
        createdAt: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given a mood outside 1 to 5, when an entry is restored, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.restore(
        id: 'entry-1',
        subject: 'Note',
        mood: 0,
        text: 'hello',
        private: false,
        localDateTime: '2026-11-14T08:02:00',
        createdAt: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
    expect(
      () => JournalEntry.restore(
        id: 'entry-1',
        subject: 'Note',
        mood: 6,
        text: 'hello',
        private: false,
        localDateTime: '2026-11-14T08:02:00',
        createdAt: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given an impossible localDateTime, when an entry is restored, then InvalidJournalEntryException is thrown', () {
    // Given, when, then
    expect(
      () => JournalEntry.restore(
        id: 'entry-1',
        subject: 'Note',
        mood: 3,
        text: 'hello',
        private: false,
        localDateTime: '2026-02-31T00:00:00',
        createdAt: now,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given an invalid journal entry exception, when it is converted to a string, then the string names that failure', () {
    expect(
      const InvalidJournalEntryException().toString(),
      'Invalid journal entry.',
    );
  });
}
