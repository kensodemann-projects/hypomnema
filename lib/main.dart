import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:hypomnema/app/app.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:material_ui/material_ui.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initializeFirebase =
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS;
  if (initializeFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    }
  }
  runApp(
    MainApp(
      authService: FirebaseAuthService(),
      journalEntries: FirestoreJournalEntryRepository(
        firestore: FirebaseFirestore.instance,
        firebaseAuth: FirebaseAuth.instance,
      ),
    ),
  );
}
