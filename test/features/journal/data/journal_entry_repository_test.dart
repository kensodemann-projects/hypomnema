import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements FirebaseAuth {
  _FakeFirebaseAuth({this.currentUser});

  @override
  final User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final firstInstant = DateTime(2026, 11, 23, 16, 35, 4);
  final laterInstant = DateTime(2026, 11, 23, 18, 0, 0);

  test('Given a signed-in user, when an entry is saved, then the contract fields are stored under that user', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );

    // When
    final entry = await repository.save(
      subject: '  Note  ',
      mood: 2,
      text: '  hello  ',
      private: true,
    );

    // Then
    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .doc(entry.id)
        .get();
    final data = snapshot.data()!;
    expect(entry.id, snapshot.id);
    expect(data['subject'], 'Note');
    expect(data['mood'], 2);
    expect(data['mood'], isA<int>());
    expect(data['text'], 'hello');
    expect(data['private'], isTrue);
    expect(data['localDateTime'], '2026-11-23T16:35:04');
    expect(data['createdAt'], Timestamp.fromDate(firstInstant));
  });

  test('Given a signed-in user, when two entries are saved, then they have different document ids', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );

    // When
    final first = await repository.save(
      subject: 'One',
      mood: 1,
      text: 'one',
      private: false,
    );
    final second = await repository.save(
      subject: 'Two',
      mood: 2,
      text: 'two',
      private: false,
    );

    // Then
    expect(first.id, isNot(second.id));
    final saved = await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .get();
    expect(saved.docs.map((doc) => doc.id).toSet(), {first.id, second.id});
  });

  test('Given a whitespace subject, when save is called, then InvalidJournalEntryException is thrown and nothing is written', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );

    // When, then
    await expectLater(
      repository.save(subject: '   ', mood: 3, text: 'hello', private: false),
      throwsA(isA<InvalidJournalEntryException>()),
    );
    final users = await firestore.collection('users').get();
    expect(users.docs, isEmpty);
  });

  test('Given a signed-out user, when save is called, then JournalEntryRepositoryException is thrown and nothing is written', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(),
      clock: () => firstInstant,
    );

    // When, then
    await expectLater(
      repository.save(subject: 'Note', mood: 3, text: 'hello', private: false),
      throwsA(isA<JournalEntryRepositoryException>()),
    );
    final users = await firestore.collection('users').get();
    expect(users.docs, isEmpty);
  });

  test('Given a signed-out user, when update is called, then JournalEntryRepositoryException is thrown and nothing is written', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(),
      clock: () => firstInstant,
    );
    final entry = JournalEntry.create(
      id: 'entry-1',
      subject: 'Note',
      mood: 3,
      text: 'hello',
      private: false,
      now: firstInstant,
    );

    // When, then
    await expectLater(
      repository.update(
        entry: entry,
        subject: 'X',
        mood: 3,
        text: 'y',
        private: false,
      ),
      throwsA(isA<JournalEntryRepositoryException>()),
    );
    final users = await firestore.collection('users').get();
    expect(users.docs, isEmpty);
  });

  test('Given a repository exception, when it is converted to a string, then the string names the missing user', () {
    expect(
      const JournalEntryRepositoryException().toString(),
      'Journal entry requires a signed-in user.',
    );
  });

  test('Given a mood outside 1 to 5, when save is called, then InvalidJournalEntryException is thrown and nothing is written', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );

    // When, then
    await expectLater(
      repository.save(subject: 'Note', mood: 0, text: 'hello', private: false),
      throwsA(isA<InvalidJournalEntryException>()),
    );
    final users = await firestore.collection('users').get();
    expect(users.docs, isEmpty);
  });

  test('Given whitespace text, when save is called, then InvalidJournalEntryException is thrown and nothing is written', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );

    // When, then
    await expectLater(
      repository.save(subject: 'Note', mood: 3, text: '   ', private: false),
      throwsA(isA<InvalidJournalEntryException>()),
    );
    final users = await firestore.collection('users').get();
    expect(users.docs, isEmpty);
  });

  test('Given a saved entry, when it is updated, then the mutable fields change, the times stay, and the clock is read only on save', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    var clockCalls = 0;
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () {
        clockCalls += 1;
        return clockCalls == 1 ? firstInstant : laterInstant;
      },
    );
    final saved = await repository.save(
      subject: 'Note',
      mood: 2,
      text: 'hello',
      private: false,
    );

    // When
    final updated = await repository.update(
      entry: saved,
      subject: 'Later',
      mood: 5,
      text: 'updated',
      private: true,
    );

    // Then
    expect(clockCalls, 1);
    expect(updated.localDateTime, saved.localDateTime);
    expect(updated.createdAt, saved.createdAt);
    final savedDocs = await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .get();
    expect(savedDocs.docs, hasLength(1));
    final data = savedDocs.docs.single.data();
    expect(data['subject'], 'Later');
    expect(data['mood'], 5);
    expect(data['text'], 'updated');
    expect(data['private'], isTrue);
    expect(data['localDateTime'], '2026-11-23T16:35:04');
    expect(data['createdAt'], Timestamp.fromDate(firstInstant));
  });

  test('Given a saved entry, when update is called with a whitespace subject, then InvalidJournalEntryException is thrown and the subject stays', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );
    final saved = await repository.save(
      subject: 'Note',
      mood: 2,
      text: 'hello',
      private: false,
    );

    // When, then
    await expectLater(
      repository.update(
        entry: saved,
        subject: '   ',
        mood: 2,
        text: 'hello',
        private: false,
      ),
      throwsA(isA<InvalidJournalEntryException>()),
    );
    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .doc(saved.id)
        .get();
    expect(snapshot.data()!['subject'], 'Note');
  });

  test('Given a signed-in user with no entries, when watch is listened to, then it emits an empty list', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );

    // When
    final entries = await repository.watch().first;

    // Then
    expect(entries, isEmpty);
  });

  test('Given saved entries, when watch is listened to, then they emit newest first and a later save appears', () async {
    // Given
    final newestInstant = DateTime(2026, 11, 23, 19, 5, 6);
    final instants = [firstInstant, laterInstant, newestInstant];
    var clockCalls = 0;
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () {
        final instant = instants[clockCalls];
        clockCalls += 1;
        return instant;
      },
    );
    final older = await repository.save(
      subject: 'Older',
      mood: 2,
      text: 'one',
      private: false,
    );
    final newer = await repository.save(
      subject: 'Newer',
      mood: 4,
      text: 'two',
      private: true,
    );
    final watch = StreamIterator(repository.watch());

    // When
    final hasFirst = await watch.moveNext();
    final first = watch.current;
    final newest = await repository.save(
      subject: 'Newest',
      mood: 5,
      text: 'three',
      private: false,
    );
    final hasSecond = await watch.moveNext();
    final second = watch.current;
    await watch.cancel();

    // Then
    expect(hasFirst, isTrue);
    expect(first.map((entry) => entry.id), [newer.id, older.id]);
    expect(first.first.localDateTime, newer.localDateTime);
    expect(first.first.createdAt, newer.createdAt);
    expect(first.first.createdAt.isUtc, isTrue);
    expect(first.last.localDateTime, older.localDateTime);
    expect(first.last.createdAt, older.createdAt);
    expect(hasSecond, isTrue);
    expect(second.map((entry) => entry.subject), ['Newest', 'Newer', 'Older']);
    expect(second.first.id, newest.id);
    expect(second.first.localDateTime, newest.localDateTime);
    expect(second.first.createdAt, newest.createdAt);
  });

  test('Given an entry stored for another user, when watch is listened to, then that entry is absent', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );
    await firestore
        .collection('users')
        .doc('user-2')
        .collection('journalEntries')
        .doc('theirs')
        .set({
          'subject': 'Theirs',
          'mood': 3,
          'text': 'secret',
          'private': false,
          'localDateTime': '2026-11-23T16:35:04',
          'createdAt': Timestamp.fromDate(laterInstant),
        });
    final saved = await repository.save(
      subject: 'Mine',
      mood: 1,
      text: 'hello',
      private: false,
    );

    // When
    final entries = await repository.watch().first;

    // Then
    expect(entries.map((entry) => entry.id), [saved.id]);
    expect(entries.single.subject, 'Mine');
  });

  test('Given a stored document restore rejects, when watch is listened to, then the stream emits InvalidJournalEntryException', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );
    await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .doc('bad')
        .set({
          'subject': '   ',
          'mood': 3,
          'text': 'hello',
          'private': false,
          'localDateTime': '2026-11-23T16:35:04',
          'createdAt': Timestamp.fromDate(firstInstant),
        });

    // When, then
    await expectLater(
      repository.watch(),
      emitsError(isA<InvalidJournalEntryException>()),
    );
  });

  test('Given a signed-out user, when watch is listened to, then JournalEntryRepositoryException is emitted and nothing is written', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(),
      clock: () => firstInstant,
    );

    // When, then
    await expectLater(
      repository.watch(),
      emitsError(isA<JournalEntryRepositoryException>()),
    );
    final users = await firestore.collection('users').get();
    expect(users.docs, isEmpty);
  });
}
