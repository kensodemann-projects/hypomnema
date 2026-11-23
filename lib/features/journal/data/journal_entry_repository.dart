import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';

abstract interface class JournalEntryRepository {
  Future<JournalEntry> save({
    String? subject,
    required int mood,
    required String text,
    required bool private,
  });

  Future<JournalEntry> update({
    required JournalEntry entry,
    String? subject,
    required int mood,
    required String text,
    required bool private,
  });
}

class JournalEntryRepositoryException implements Exception {
  const JournalEntryRepositoryException();
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
    String? subject,
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
    final data = <String, dynamic>{
      'mood': entry.mood,
      'text': entry.text,
      'private': entry.private,
      'localDateTime': entry.localDateTime,
      'createdAt': Timestamp.fromDate(entry.createdAt),
    };
    final storedSubject = entry.subject;
    if (storedSubject != null) {
      data['subject'] = storedSubject;
    }
    await collection.doc(entry.id).set(data);
    return entry;
  }

  @override
  Future<JournalEntry> update({
    required JournalEntry entry,
    String? subject,
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
      'mood': revised.mood,
      'text': revised.text,
      'private': revised.private,
      'subject': revised.subject ?? FieldValue.delete(),
    });
    return revised;
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
