import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/data/services/auth_service.dart';
import 'package:hypomnema/main.dart';
import 'package:material_ui/material_ui.dart';

void setLogicalViewportSize(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

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
      expect(
        Theme.of(tester.element(find.byType(Shell))).brightness,
        Brightness.light,
      );
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
      expect(
        Theme.of(tester.element(find.byType(Shell))).brightness,
        Brightness.dark,
      );
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
