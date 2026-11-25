import 'package:hypomnema/app/shell.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:hypomnema/features/auth/ui/login_screen.dart';
import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:material_ui/material_ui.dart';

class MainApp extends StatelessWidget {
  const MainApp({
    required this.authService,
    required this.journalEntries,
    super.key,
  });

  final AuthService authService;
  final JournalEntryRepository journalEntries;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: _AuthGate(authService: authService, journalEntries: journalEntries),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.authService, required this.journalEntries});

  final AuthService authService;
  final JournalEntryRepository journalEntries;

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
          return Shell(
            authService: authService,
            journalEntries: journalEntries,
          );
        }
        return LoginScreen(authService: authService);
      },
    );
  }
}
