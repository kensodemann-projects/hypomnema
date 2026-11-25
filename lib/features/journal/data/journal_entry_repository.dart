import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';

abstract interface class JournalEntryRepository {
  Future<JournalEntry> save({
    required String subject,
    required int mood,
    required String text,
    required bool private,
  });

  Future<JournalEntry> update({
    required JournalEntry entry,
    required String subject,
    required int mood,
    required String text,
    required bool private,
  });

  Stream<List<JournalEntry>> watch();
}

class JournalEntryRepositoryException implements Exception {
  const JournalEntryRepositoryException();

  @override
  String toString() => 'Journal entry requires a signed-in user.';
}

class FirestoreJournalEntryRepository implements JournalEntryRepository {
  FirestoreJournalEntryRepository({
    required this._firestore,
    required this._firebaseAuth,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final DateTime Function() _clock;

  @override
  Future<JournalEntry> save({
    required String subject,
    required int mood,
    required String text,
    required bool private,
  }) async {
    final collection = _entries(_uid());
    final entry = JournalEntry.create(
      id: collection.doc().id,
      subject: subject,
      mood: mood,
      text: text,
      private: private,
      now: _clock(),
    );
    await collection.doc(entry.id).set({
      'subject': entry.subject,
      'mood': entry.mood,
      'text': entry.text,
      'private': entry.private,
      'localDateTime': entry.localDateTime,
      'createdAt': Timestamp.fromDate(entry.createdAt),
    });
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
    final uid = _uid();
    final revised = entry.revise(
      subject: subject,
      mood: mood,
      text: text,
      private: private,
    );
    await _entries(uid).doc(entry.id).update({
      'subject': revised.subject,
      'mood': revised.mood,
      'text': revised.text,
      'private': revised.private,
    });
    return revised;
  }

  @override
  Stream<List<JournalEntry>> watch() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      return Stream<List<JournalEntry>>.error(
        const JournalEntryRepositoryException(),
      );
    }
    return _entries(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) _read(doc)]);
  }

  JournalEntry _read(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final subject = data['subject'];
    final mood = data['mood'];
    final text = data['text'];
    final private = data['private'];
    final localDateTime = data['localDateTime'];
    final createdAt = data['createdAt'];
    if (subject is! String ||
        mood is! int ||
        text is! String ||
        private is! bool ||
        localDateTime is! String ||
        createdAt is! Timestamp) {
      throw const InvalidJournalEntryException();
    }
    return JournalEntry.restore(
      id: doc.id,
      subject: subject,
      mood: mood,
      text: text,
      private: private,
      localDateTime: localDateTime,
      createdAt: createdAt.toDate(),
    );
  }

  String _uid() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw const JournalEntryRepositoryException();
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _entries(String uid) {
    return _firestore.collection('users').doc(uid).collection('journalEntries');
  }
}
