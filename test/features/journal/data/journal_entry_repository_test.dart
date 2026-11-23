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
    final first = await repository.save(mood: 1, text: 'one', private: false);
    final second = await repository.save(mood: 2, text: 'two', private: false);

    // Then
    expect(first.id, isNot(second.id));
    final saved = await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .get();
    expect(saved.docs.map((doc) => doc.id).toSet(), {first.id, second.id});
  });

  test('Given a whitespace subject, when an entry is saved, then the subject field is omitted', () async {
    // Given
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreJournalEntryRepository(
      firestore: firestore,
      firebaseAuth: _FakeFirebaseAuth(currentUser: _FakeUser('user-1')),
      clock: () => firstInstant,
    );

    // When
    final entry = await repository.save(
      subject: '   ',
      mood: 3,
      text: 'hello',
      private: false,
    );

    // Then
    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .doc(entry.id)
        .get();
    expect(snapshot.data()!.containsKey('subject'), isFalse);
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
      repository.save(mood: 3, text: 'hello', private: false),
      throwsA(isA<JournalEntryRepositoryException>()),
    );
    final users = await firestore.collection('users').get();
    expect(users.docs, isEmpty);
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
      repository.save(mood: 0, text: 'hello', private: false),
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
      repository.save(mood: 3, text: '   ', private: false),
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

  test('Given a saved entry with a subject, when update clears the subject, then the subject field is removed', () async {
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

    // When
    await repository.update(
      entry: saved,
      mood: 2,
      text: 'hello',
      private: false,
    );

    // Then
    final snapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('journalEntries')
        .doc(saved.id)
        .get();
    expect(snapshot.data()!.containsKey('subject'), isFalse);
  });
}
