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
          return Shell(authService: authService);
        }
        return LoginScreen(authService: authService);
      },
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return DesktopScaffold(authService: authService);
        } else {
          return PhoneScaffold(authService: authService);
        }
      },
    );
  }
}

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({required this.authService, super.key});

  final AuthService authService;

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
              child: Align(
                alignment: Alignment.topCenter,
                child: _SignOutButton(authService: authService),
              ),
            ),
          ),
          const Expanded(child: Center(child: Text('Desktop'))),
        ],
      ),
    );
  }
}

class PhoneScaffold extends StatelessWidget {
  const PhoneScaffold({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [_SignOutButton(authService: authService)]),
      body: const Center(child: Text('Phone')),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('shell-sign-out'),
      tooltip: 'Sign out',
      onPressed: () async {
        try {
          await authService.signOut();
        } on AuthException {
          // Stay on the shell. signedIn does not emit false.
        }
      },
      icon: const Icon(Icons.logout),
    );
  }
}
