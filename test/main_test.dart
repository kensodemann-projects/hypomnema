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

class _FakeAuthService implements AuthService {
  final signedInController = StreamController<bool>();
  final signInCalls = <({String email, String password})>[];

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
  Future<void> signOut() async {}
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
      expect(find.byType(Shell), findsOneWidget);
      expect(find.byType(PhoneScaffold), findsOneWidget);
      expect(find.byType(DesktopScaffold), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byKey(const Key('shell-side-panel')), findsNothing);
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
      expect(find.byType(Shell), findsOneWidget);
      expect(find.byType(PhoneScaffold), findsOneWidget);
      expect(find.byType(DesktopScaffold), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byKey(const Key('shell-side-panel')), findsNothing);
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
      expect(find.byType(Shell), findsOneWidget);
      expect(find.byType(DesktopScaffold), findsOneWidget);
      expect(find.byType(PhoneScaffold), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('shell-side-panel')), findsOneWidget);
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
      expect(find.byType(Shell), findsOneWidget);
      expect(find.byType(DesktopScaffold), findsOneWidget);
      expect(find.byType(PhoneScaffold), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('shell-side-panel')), findsOneWidget);
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
      expect(find.byKey(const Key('login-email')), findsNothing);
      expect(find.byType(Shell), findsNothing);
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
      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(find.byType(Shell), findsNothing);
      expect(find.byKey(const Key('shell-side-panel')), findsNothing);
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
      expect(find.byType(Shell), findsOneWidget);
      expect(find.byType(PhoneScaffold), findsOneWidget);
      expect(find.byKey(const Key('login-sign-in')), findsNothing);
    },
  );
}
