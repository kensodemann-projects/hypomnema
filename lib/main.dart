import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:hypomnema/data/services/auth_service.dart';
import 'package:hypomnema/ui/auth/login_screen.dart';
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
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final authService = this.authService ?? FirebaseAuthService();
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: _AuthGate(authService: authService),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: authService.signedIn,
      builder: (context, snapshot) {
        final signedIn = snapshot.data;
        if (signedIn == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(key: Key('auth-gate-progress')),
            ),
          );
        }
        if (signedIn) {
          return const Shell();
        }
        return LoginScreen(authService: authService);
      },
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const DesktopScaffold();
        } else {
          return const PhoneScaffold();
        }
      },
    );
  }
}

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            key: const Key('shell-side-panel'),
            width: 72,
            height: double.infinity,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
          const Expanded(child: Center(child: Text('Desktop'))),
        ],
      ),
    );
  }
}

class PhoneScaffold extends StatelessWidget {
  const PhoneScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Phone')),
    );
  }
}
