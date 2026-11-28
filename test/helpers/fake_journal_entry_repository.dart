import 'dart:async';

import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';

class FakeJournalEntryRepository implements JournalEntryRepository {
  FakeJournalEntryRepository({List<JournalEntry>? entries}) {
    if (entries != null) {
      _stored.addAll(entries);
    }
  }

  final saves = <({String subject, int mood, String text, bool private})>[];
  final updates = <({String subject, int mood, String text, bool private})>[];
  final _stored = <JournalEntry>[];
  final _updates = StreamController<List<JournalEntry>>.broadcast();
  var updateCalls = 0;
  var _nextId = 0;
  Object? saveError;
  Object? watchError;
  Completer<void>? holdWatch;

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
    _nextId += 1;
    final entry = JournalEntry.create(
      id: 'entry-$_nextId',
      subject: subject,
      mood: mood,
      text: text,
      private: private,
      now: DateTime.utc(2026, 11, 24, 18),
    );
    _stored.insert(0, entry);
    _publish();
    return entry;
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
    updates.add((subject: subject, mood: mood, text: text, private: private));
    final revised = entry.revise(
      subject: subject,
      mood: mood,
      text: text,
      private: private,
    );
    final index = _stored.indexWhere((stored) => stored.id == entry.id);
    if (index >= 0) {
      _stored[index] = revised;
    }
    _publish();
    return revised;
  }

  @override
  Stream<List<JournalEntry>> watch() async* {
    final error = watchError;
    if (error != null) {
      throw error;
    }
    final hold = holdWatch;
    if (hold != null) {
      await hold.future;
    }
    yield List<JournalEntry>.unmodifiable(_stored);
    yield* _updates.stream;
  }

  void _publish() {
    if (_updates.hasListener) {
      _updates.add(List<JournalEntry>.unmodifiable(_stored));
    }
  }
}
