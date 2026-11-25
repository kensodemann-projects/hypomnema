import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/app/app.dart';
import 'package:hypomnema/app/shell.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_journal_entry_repository.dart';
import '../helpers/viewport.dart';

void expectPhoneShellExists() {
  expect(find.byType(Shell), findsOneWidget);
  expect(find.byType(PhoneScaffold), findsOneWidget);
  expect(find.byType(DesktopScaffold), findsNothing);
  expect(find.byType(NavigationBar), findsOneWidget);
  expect(find.byType(NavigationRail), findsNothing);
  expect(find.byType(AppBar), findsNothing);
}

void expectPhoneShellNotExists() {
  expect(find.byType(Shell), findsNothing);
  expect(find.byType(PhoneScaffold), findsNothing);
  expect(find.byType(NavigationBar), findsNothing);
  expect(find.byType(AppBar), findsNothing);
}

void expectDesktopShellNotExists() {
  expect(find.byType(Shell), findsNothing);
  expect(find.byType(DesktopScaffold), findsNothing);
  expect(find.byType(NavigationRail), findsNothing);
}

void expectLoginFormExists() {
  expect(find.byKey(const Key('login-email')), findsOneWidget);
  expect(find.byKey(const Key('login-sign-in')), findsOneWidget);
}

void expectLoginFormNotExists() {
  expect(find.byKey(const Key('login-email')), findsNothing);
  expect(find.byKey(const Key('login-sign-in')), findsNothing);
}

class _FakeAuthService implements AuthService {
  final signedInController = StreamController<bool>();
  final signInCalls = <({String email, String password})>[];
  int signOutCalls = 0;

  @override
  Stream<bool> get signedIn => signedInController.stream;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email: email, password: password));
    signedInController.add(true);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    signedInController.add(false);
  }
}

_FakeAuthService _authEmitting(bool signedIn) {
  final auth = _FakeAuthService();
  auth.signedInController.add(signedIn);
  return auth;
}

Finder _chromeLabel(Key chromeKey, String label) {
  return find.descendant(of: find.byKey(chromeKey), matching: find.text(label));
}

Future<_FakeAuthService> _openSignOutDialog(
  WidgetTester tester, {
  required Size size,
  required Key chromeKey,
}) async {
  final auth = _authEmitting(true);
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MainApp(authService: auth, journalEntries: FakeJournalEntryRepository()),
  );
  await tester.pumpAndSettle();
  await tester.tap(_chromeLabel(chromeKey, 'Journal'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('shell-sign-out')));
  await tester.pumpAndSettle();
  return auth;
}

void expectMainAppTheme(WidgetTester tester, Brightness brightness) {
  final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.themeMode, ThemeMode.system);

  final expected = switch (brightness) {
    Brightness.light => AppTheme.light,
    Brightness.dark => AppTheme.dark,
  };
  final shellTheme = Theme.of(tester.element(find.byType(Shell)));
  final materialAppTheme = switch (brightness) {
    Brightness.light => materialApp.theme!,
    Brightness.dark => materialApp.darkTheme!,
  };

  expect(shellTheme.brightness, brightness);
  expect(materialAppTheme.brightness, brightness);
  expect(shellTheme.colorScheme, expected.colorScheme);
  expect(shellTheme.scaffoldBackgroundColor, expected.scaffoldBackgroundColor);
  expect(shellTheme.extension<AppColors>(), expected.extension<AppColors>());
  expect(materialAppTheme.colorScheme, expected.colorScheme);
  expect(
    materialAppTheme.scaffoldBackgroundColor,
    expected.scaffoldBackgroundColor,
  );
  expect(
    materialAppTheme.extension<AppColors>(),
    expected.extension<AppColors>(),
  );
}

void main() {
  testWidgets(
    'Given light platform brightness, when MainApp builds, then the theme is light',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

      // When
      await tester.pumpWidget(
        MainApp(
          authService: _authEmitting(true),
          journalEntries: FakeJournalEntryRepository(),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expectPhoneShellExists();
      expectMainAppTheme(tester, Brightness.light);
    },
  );

  testWidgets(
    'Given dark platform brightness, when MainApp builds, then the theme is dark',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;

      // When
      await tester.pumpWidget(
        MainApp(
          authService: _authEmitting(true),
          journalEntries: FakeJournalEntryRepository(),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expectPhoneShellExists();
      expectMainAppTheme(tester, Brightness.dark);
    },
  );

  testWidgets(
    'Given the phone shell is showing, when MainApp rebuilds with the same auth service, then the shell stays',
    (tester) async {
      // Given
      final auth = _authEmitting(true);
      setLogicalViewportSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        MainApp(
          authService: auth,
          journalEntries: FakeJournalEntryRepository(),
        ),
      );
      await tester.pumpAndSettle();
      expectPhoneShellExists();

      // When
      await tester.pumpWidget(
        MainApp(
          authService: auth,
          journalEntries: FakeJournalEntryRepository(),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byKey(const Key('auth-gate-progress')), findsNothing);
      expectPhoneShellExists();
      expectLoginFormNotExists();
    },
  );

  testWidgets(
    'Given signedIn has not emitted, when MainApp builds, then the progress indicator is shown',
    (tester) async {
      // Given
      final auth = _FakeAuthService();
      setLogicalViewportSize(tester, const Size(400, 800));

      // When
      await tester.pumpWidget(
        MainApp(
          authService: auth,
          journalEntries: FakeJournalEntryRepository(),
        ),
      );

      // Then
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget(find.byKey(const Key('auth-gate-progress'))),
        isA<CircularProgressIndicator>(),
      );
      expectLoginFormNotExists();
      expectPhoneShellNotExists();
      expectDesktopShellNotExists();
    },
  );

  testWidgets(
    'Given signedIn emits false, when MainApp builds, then the login screen is shown',
    (tester) async {
      // Given
      final auth = _authEmitting(false);
      setLogicalViewportSize(tester, const Size(400, 800));

      // When
      await tester.pumpWidget(
        MainApp(
          authService: auth,
          journalEntries: FakeJournalEntryRepository(),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expectLoginFormExists();
      expectPhoneShellNotExists();
      expectDesktopShellNotExists();
    },
  );

  testWidgets(
    'Given the login screen, when email and password sign-in succeeds, then the phone shell is shown',
    (tester) async {
      // Given
      final auth = _authEmitting(false);
      setLogicalViewportSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        MainApp(
          authService: auth,
          journalEntries: FakeJournalEntryRepository(),
        ),
      );
      await tester.pumpAndSettle();

      // When
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.enterText(find.byKey(const Key('login-password')), 'secret');
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-sign-in')));
      await tester.pump();

      // Then
      expect(auth.signInCalls, [
        (email: 'person@example.com', password: 'secret'),
      ]);
      expectPhoneShellExists();
      expectLoginFormNotExists();
    },
  );

  testWidgets(
    'Given the phone sign-out dialog, when Sign out is confirmed, then the login screen is shown',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: const Key('shell-navigation-bar'),
      );

      // When
      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

      // Then
      expect(auth.signOutCalls, 1);
      expect(find.byType(Shell), findsNothing);
      expectLoginFormExists();
    },
  );

  testWidgets(
    'Given the desktop sign-out dialog, when Sign out is confirmed, then the login screen is shown',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(601, 800),
        chromeKey: const Key('shell-navigation-rail'),
      );

      // When
      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

      // Then
      expect(auth.signOutCalls, 1);
      expect(find.byType(Shell), findsNothing);
      expectLoginFormExists();
    },
  );
}
