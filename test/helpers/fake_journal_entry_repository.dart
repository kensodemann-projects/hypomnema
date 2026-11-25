import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';

class FakeJournalEntryRepository implements JournalEntryRepository {
  final saves = <({String subject, int mood, String text, bool private})>[];
  var updateCalls = 0;
  Object? saveError;

  @override
  Future<JournalEntry> save({
    required String subject,
    required int mood,
    required String text,
    required bool private,
  }) async {
    saves.add((subject: subject, mood: mood, text: text, private: private));
    final error = saveError;
    if (error != null) {
      throw error;
    }
    return JournalEntry.create(
      id: 'entry-1',
      subject: subject,
      mood: mood,
      text: text,
      private: private,
      now: DateTime.utc(2026, 11, 24, 18),
    );
  }

  @override
  Future<JournalEntry> update({
    required JournalEntry entry,
    required String subject,
    required int mood,
    required String text,
    required bool private,
  }) async {
    updateCalls += 1;
    return entry.revise(
      subject: subject,
      mood: mood,
      text: text,
      private: private,
    );
  }
}
