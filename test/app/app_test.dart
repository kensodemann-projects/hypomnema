import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/app/app.dart';
import 'package:hypomnema/app/shell.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/viewport.dart';

void expectPhoneShellExists() {
  expect(find.byType(Shell), findsOneWidget);
  expect(find.byType(PhoneScaffold), findsOneWidget);
  expect(find.byType(DesktopScaffold), findsNothing);
  expect(find.byType(AppBar), findsOneWidget);
  expect(find.byKey(const Key('shell-side-panel')), findsNothing);
}

void expectPhoneShellNotExists() {
  expect(find.byType(Shell), findsNothing);
  expect(find.byType(PhoneScaffold), findsNothing);
  expect(find.byType(AppBar), findsNothing);
}

void expectDesktopShellExists() {
  expect(find.byType(Shell), findsOneWidget);
  expect(find.byType(DesktopScaffold), findsOneWidget);
  expect(find.byType(PhoneScaffold), findsNothing);
  expect(find.byType(AppBar), findsNothing);
  expect(find.byKey(const Key('shell-side-panel')), findsOneWidget);
}

void expectDesktopShellNotExists() {
  expect(find.byType(Shell), findsNothing);
  expect(find.byType(DesktopScaffold), findsNothing);
  expect(find.byKey(const Key('shell-side-panel')), findsNothing);
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
  bool throwOnSignOut = false;

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
    if (throwOnSignOut) {
      throw const AuthException();
    }
    signedInController.add(false);
  }
}

_FakeAuthService _authEmitting(bool signedIn) {
  final auth = _FakeAuthService();
  auth.signedInController.add(signedIn);
  return auth;
}

class _ContractPalette {
  const _ContractPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.surface,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.scrim,
    required this.scaffoldBackgroundColor,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color surface;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color scrim;
  final Color scaffoldBackgroundColor;
}

const _lightPalette = _ContractPalette(
  primary: Color(0xFF4A55C8),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDFE0FF),
  onPrimaryContainer: Color(0xFF0E1260),
  secondary: Color(0xFF4A55C8),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE2E1F5),
  onSecondaryContainer: Color(0xFF1A1B2C),
  surface: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF8F8FD),
  surfaceContainer: Color(0xFFF1F1F8),
  surfaceContainerHigh: Color(0xFFE9E9F2),
  onSurface: Color(0xFF1B1B21),
  onSurfaceVariant: Color(0xFF46464F),
  outline: Color(0xFF777680),
  outlineVariant: Color(0xFFC7C5D0),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  scrim: Color(0x61000000),
  scaffoldBackgroundColor: Color(0xFFF4F4FA),
);

const _darkPalette = _ContractPalette(
  primary: Color(0xFFBCC2FF),
  onPrimary: Color(0xFF1A237A),
  primaryContainer: Color(0xFF323D9F),
  onPrimaryContainer: Color(0xFFDFE0FF),
  secondary: Color(0xFFBCC2FF),
  onSecondary: Color(0xFF1A237A),
  secondaryContainer: Color(0xFF44455A),
  onSecondaryContainer: Color(0xFFE2E1F5),
  surface: Color(0xFF1C1C22),
  surfaceContainerLow: Color(0xFF202027),
  surfaceContainer: Color(0xFF25252C),
  surfaceContainerHigh: Color(0xFF2E2E36),
  onSurface: Color(0xFFE4E1E9),
  onSurfaceVariant: Color(0xFFC7C5D0),
  outline: Color(0xFF918F9A),
  outlineVariant: Color(0xFF46464F),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  scrim: Color(0x99000000),
  scaffoldBackgroundColor: Color(0xFF131318),
);

void _expectContractColors(ThemeData theme, _ContractPalette palette) {
  final scheme = theme.colorScheme;
  expect(scheme.primary, palette.primary);
  expect(scheme.onPrimary, palette.onPrimary);
  expect(scheme.primaryContainer, palette.primaryContainer);
  expect(scheme.onPrimaryContainer, palette.onPrimaryContainer);
  expect(scheme.secondary, palette.secondary);
  expect(scheme.onSecondary, palette.onSecondary);
  expect(scheme.secondaryContainer, palette.secondaryContainer);
  expect(scheme.onSecondaryContainer, palette.onSecondaryContainer);
  expect(scheme.surface, palette.surface);
  expect(scheme.surfaceContainerLow, palette.surfaceContainerLow);
  expect(scheme.surfaceContainer, palette.surfaceContainer);
  expect(scheme.surfaceContainerHigh, palette.surfaceContainerHigh);
  expect(scheme.onSurface, palette.onSurface);
  expect(scheme.onSurfaceVariant, palette.onSurfaceVariant);
  expect(scheme.outline, palette.outline);
  expect(scheme.outlineVariant, palette.outlineVariant);
  expect(scheme.error, palette.error);
  expect(scheme.onError, palette.onError);
  expect(scheme.errorContainer, palette.errorContainer);
  expect(scheme.onErrorContainer, palette.onErrorContainer);
  expect(scheme.scrim, palette.scrim);
  expect(theme.scaffoldBackgroundColor, palette.scaffoldBackgroundColor);
}

void expectMainAppTheme(WidgetTester tester, Brightness brightness) {
  final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.themeMode, ThemeMode.system);

  final palette = switch (brightness) {
    Brightness.light => _lightPalette,
    Brightness.dark => _darkPalette,
  };
  final shellTheme = Theme.of(tester.element(find.byType(Shell)));
  final materialAppTheme = switch (brightness) {
    Brightness.light => materialApp.theme!,
    Brightness.dark => materialApp.darkTheme!,
  };

  expect(shellTheme.brightness, brightness);
  expect(materialAppTheme.brightness, brightness);
  _expectContractColors(shellTheme, palette);
  _expectContractColors(materialAppTheme, palette);
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
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
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
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();

      // Then
      expectPhoneShellExists();
      expectMainAppTheme(tester, Brightness.dark);
    },
  );

  testWidgets(
    'Given a width of 400, when MainApp builds, then the phone layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));

      // When
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();

      // Then
      expectPhoneShellExists();
    },
  );

  testWidgets(
    'Given a width of 600, when MainApp builds, then the phone layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(600, 800));

      // When
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();

      // Then
      expectPhoneShellExists();
    },
  );

  testWidgets(
    'Given a width of 601, when MainApp builds, then the desktop layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(601, 800));

      // When
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();

      // Then
      expectDesktopShellExists();
    },
  );

  testWidgets(
    'Given a width of 1200, when MainApp builds, then the desktop layout is used',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(1200, 800));

      // When
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();

      // Then
      expectDesktopShellExists();
    },
  );

  testWidgets(
    'Given the phone shell is showing, when MainApp rebuilds with the same auth service, then the shell stays',
    (tester) async {
      // Given
      final auth = _authEmitting(true);
      setLogicalViewportSize(tester, const Size(400, 800));
      await tester.pumpWidget(MainApp(authService: auth));
      await tester.pumpAndSettle();
      expectPhoneShellExists();

      // When
      await tester.pumpWidget(MainApp(authService: auth));
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
      await tester.pumpWidget(MainApp(authService: auth));

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
      await tester.pumpWidget(MainApp(authService: auth));
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
      await tester.pumpWidget(MainApp(authService: auth));
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
    'Given the phone shell, when Sign out is tapped, then the login screen replaces the shell',
    (tester) async {
      // Given
      final auth = _authEmitting(true);
      setLogicalViewportSize(tester, const Size(400, 800));
      await tester.pumpWidget(MainApp(authService: auth));
      await tester.pumpAndSettle();
      expectPhoneShellExists();
      expect(find.byKey(const Key('shell-sign-out')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(const Key('shell-sign-out')),
        ),
        findsOneWidget,
      );

      // When
      await tester.tap(find.byKey(const Key('shell-sign-out')));
      await tester.pump();

      // Then
      expect(auth.signOutCalls, 1);
      expectLoginFormExists();
      expectPhoneShellNotExists();
    },
  );

  testWidgets(
    'Given the desktop shell, when Sign out is tapped, then the login screen replaces the shell',
    (tester) async {
      // Given
      final auth = _authEmitting(true);
      setLogicalViewportSize(tester, const Size(601, 800));
      await tester.pumpWidget(MainApp(authService: auth));
      await tester.pumpAndSettle();
      expectDesktopShellExists();
      expect(find.byKey(const Key('shell-sign-out')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('shell-side-panel')),
          matching: find.byKey(const Key('shell-sign-out')),
        ),
        findsOneWidget,
      );

      // When
      await tester.tap(find.byKey(const Key('shell-sign-out')));
      await tester.pump();

      // Then
      expect(auth.signOutCalls, 1);
      expectLoginFormExists();
      expectDesktopShellNotExists();
    },
  );

  testWidgets(
    'Given sign-out throws AuthException, when Sign out is tapped, then the phone shell stays',
    (tester) async {
      // Given
      final auth = _authEmitting(true)..throwOnSignOut = true;
      setLogicalViewportSize(tester, const Size(400, 800));
      await tester.pumpWidget(MainApp(authService: auth));
      await tester.pumpAndSettle();
      final textBefore = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList();

      // When
      await tester.tap(find.byKey(const Key('shell-sign-out')));
      await tester.pump();

      // Then
      expect(auth.signOutCalls, 1);
      expectPhoneShellExists();
      expectLoginFormNotExists();
      expect(
        tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
        textBefore,
      );
    },
  );
}
