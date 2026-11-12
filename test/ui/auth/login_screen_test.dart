import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/data/services/auth_service.dart';
import 'package:hypomnema/ui/auth/login_screen.dart';
import 'package:material_ui/material_ui.dart';

void setLogicalViewportSize(WidgetTester tester, Size size) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
}

class _RecordingAuthService implements AuthService {
  Object? error;
  Completer<void>? pending;
  final signInCalls = <({String email, String password})>[];
  final resetCalls = <String>[];

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email: email, password: password));
    final pending = this.pending;
    if (pending != null) {
      await pending.future;
    }
    final error = this.error;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetCalls.add(email);
    final pending = this.pending;
    if (pending != null) {
      await pending.future;
    }
    final error = this.error;
    if (error != null) {
      throw error;
    }
  }
}

Future<void> pumpLoginScreen(
  WidgetTester tester, {
  required AuthService authService,
  required Size size,
}) async {
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(home: LoginScreen(authService: authService)),
  );
}

FilledButton signInButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byKey(const Key('login-sign-in')));
}

TextField textField(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key)));
}

Future<void> unfocus(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

Color textColor(WidgetTester tester, String text) {
  final finder = find.text(text);
  final widget = tester.widget<Text>(finder);
  return widget.style?.color ??
      DefaultTextStyle.of(tester.element(finder)).style.color!;
}

void main() {
  testWidgets(
    'Given a phone width, when the login screen builds, then the column has no card',
    (tester) async {
      for (final width in [400.0, 600.0]) {
        // Given, when
        await pumpLoginScreen(
          tester,
          authService: _RecordingAuthService(),
          size: Size(width, 800),
        );

        // Then
        expect(find.byKey(const Key('login-form-card')), findsNothing);
      }
    },
  );

  testWidgets(
    'Given a desktop width, when the login screen builds, then the form sits in a card',
    (tester) async {
      for (final width in [601.0, 1200.0]) {
        // Given, when
        await pumpLoginScreen(
          tester,
          authService: _RecordingAuthService(),
          size: Size(width, 800),
        );

        // Then
        expect(find.byKey(const Key('login-form-card')), findsOneWidget);
        final box = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.byKey(const Key('login-form-card')),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(box.constraints.maxWidth, 400);
      }
    },
  );

  testWidgets(
    'Given empty fields, when a field loses focus, then its required message appears',
    (tester) async {
      // Given
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(400, 800),
      );
      expect(textField(tester, 'login-email').decoration?.errorText, isNull);
      expect(textField(tester, 'login-password').decoration?.errorText, isNull);

      // When
      await tester.tap(find.byKey(const Key('login-email')));
      await tester.pump();
      await unfocus(tester);
      await tester.pump(const Duration(milliseconds: 200));

      // Then
      final emailField = textField(tester, 'login-email');
      expect(emailField.decoration?.errorText, 'Email is required.');
      final errorColor = Theme.of(
        tester.element(find.byKey(const Key('login-email'))),
      ).colorScheme.error;
      expect(textColor(tester, 'Email is required.'), errorColor);
      expect(textColor(tester, 'Email'), errorColor);

      await tester.tap(find.byKey(const Key('login-password')));
      await tester.pump();
      await unfocus(tester);
      expect(
        textField(tester, 'login-password').decoration?.errorText,
        'Password is required.',
      );
    },
  );

  testWidgets(
    'Given an invalid email, when the field loses focus and then changes, then the error clears while sign-in stays disabled',
    (tester) async {
      // Given
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(400, 800),
      );
      await tester.enterText(find.byKey(const Key('login-email')), 'person');
      await unfocus(tester);
      expect(
        textField(tester, 'login-email').decoration?.errorText,
        'Enter a valid email address.',
      );

      // When
      await tester.enterText(find.byKey(const Key('login-email')), 'p');
      await tester.pump();

      // Then
      expect(textField(tester, 'login-email').decoration?.errorText, isNull);
      expect(signInButton(tester).onPressed, isNull);
    },
  );

  testWidgets(
    'Given the current field text, when it is not a valid pair, then Sign in is disabled',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );

      // Then
      expect(signInButton(tester).onPressed, isNull);

      // When
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();

      // Then
      expect(signInButton(tester).onPressed, isNull);

      // When
      await tester.enterText(find.byKey(const Key('login-email')), 'person');
      await tester.enterText(find.byKey(const Key('login-password')), 'secret');
      await tester.pump();

      // Then
      expect(signInButton(tester).onPressed, isNull);
      expect(auth.signInCalls, isEmpty);
    },
  );

  testWidgets(
    'Given two valid accounts, when Sign in is tapped, then each trimmed email and raw password is forwarded',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );

      // When
      await tester.enterText(
        find.byKey(const Key('login-email')),
        ' person@example.com ',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        ' secret ',
      );
      await tester.pump();
      expect(signInButton(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('login-sign-in')));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'second@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'other-password',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-sign-in')));
      await tester.pump();

      // Then
      expect(auth.signInCalls, [
        (email: 'person@example.com', password: ' secret '),
        (email: 'second@example.com', password: 'other-password'),
      ]);
      expect(find.byKey(const Key('login-error')), findsNothing);
      expect(
        find.text('Check your email for a password reset link.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Given the sign-in form, when Enter is pressed in the email field, then the password field is focused',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      expect(
        textField(tester, 'login-email').textInputAction,
        TextInputAction.next,
      );

      // When
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Then
      expect(textField(tester, 'login-password').focusNode!.hasFocus, isTrue);
      expect(auth.signInCalls, isEmpty);
    },
  );

  testWidgets(
    'Given the password field, when Enter is pressed, then sign-in runs only for a valid pair',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      expect(
        textField(tester, 'login-password').textInputAction,
        TextInputAction.done,
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.showKeyboard(find.byKey(const Key('login-password')));

      // When
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Then
      expect(auth.signInCalls, isEmpty);

      // When
      await tester.enterText(find.byKey(const Key('login-password')), 'secret');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Then
      expect(auth.signInCalls, [
        (email: 'person@example.com', password: 'secret'),
      ]);
    },
  );

  testWidgets(
    'Given a FirebaseAuthException, when sign-in fails, then the authentication failed message is shown',
    (tester) async {
      // Given
      final auth = _RecordingAuthService()
        ..error = FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Wrong password.',
        );
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.enterText(find.byKey(const Key('login-password')), 'secret');
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-sign-in')));
      await tester.pump();

      // Then
      expect(find.byKey(const Key('login-error')), findsOneWidget);
      expect(find.text('Authentication failed.'), findsOneWidget);

      auth.error = FirebaseAuthException(code: 'invalid-credential');
      await tester.tap(find.byKey(const Key('login-sign-in')));
      await tester.pump();
      expect(find.text('Authentication failed.'), findsOneWidget);
    },
  );

  testWidgets(
    'Given a sign-in request in progress, when the form is waiting, then Sign in is disabled',
    (tester) async {
      // Given
      final auth = _RecordingAuthService()..pending = Completer<void>();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.enterText(find.byKey(const Key('login-password')), 'secret');
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-sign-in')));
      await tester.pump();

      // Then
      expect(signInButton(tester).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('login-forgot-password')))
            .onPressed,
        isNull,
      );
      expect(auth.signInCalls, hasLength(1));

      auth.pending!.complete();
      await tester.pump();
      expect(signInButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Given the email field, when it is not a valid address, then Forgot password is disabled',
    (tester) async {
      // Given
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(400, 800),
      );
      final forgot = find.byKey(const Key('login-forgot-password'));

      // Then
      expect(tester.widget<TextButton>(forgot).onPressed, isNull);

      // When
      await tester.enterText(find.byKey(const Key('login-email')), 'person');
      await tester.pump();

      // Then
      expect(tester.widget<TextButton>(forgot).onPressed, isNull);

      // When
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();

      // Then
      expect(tester.widget<TextButton>(forgot).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Given a valid email, when Forgot password is tapped, then the reset form keeps that email',
    (tester) async {
      // Given
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();

      // Then
      expect(find.byKey(const Key('login-password')), findsNothing);
      expect(find.byKey(const Key('login-sign-in')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('login-email')))
            .controller
            ?.text,
        'person@example.com',
      );
      expect(find.byKey(const Key('login-send-reset')), findsOneWidget);
      expect(find.byKey(const Key('login-back-to-sign-in')), findsOneWidget);
    },
  );

  testWidgets(
    'Given the reset form, when the email is not valid, then Send reset email is disabled',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();
      final send = find.byKey(const Key('login-send-reset'));
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);

      // When
      await tester.enterText(find.byKey(const Key('login-email')), '');
      await tester.pump();

      // Then
      expect(tester.widget<FilledButton>(send).onPressed, isNull);

      // When
      await tester.enterText(find.byKey(const Key('login-email')), 'person');
      await tester.pump();

      // Then
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      expect(auth.resetCalls, isEmpty);

      // When
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();

      // Then
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Given the reset form, when Enter is pressed in the email field, then a reset email is sent only for a valid address',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();
      expect(
        textField(tester, 'login-email').textInputAction,
        TextInputAction.done,
      );

      // When
      await tester.enterText(find.byKey(const Key('login-email')), 'person');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Then
      expect(auth.resetCalls, isEmpty);

      // When
      await tester.enterText(
        find.byKey(const Key('login-email')),
        ' person@example.com ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Then
      expect(auth.resetCalls, ['person@example.com']);
    },
  );

  testWidgets(
    'Given a valid email, when Send reset email succeeds, then the trimmed email is forwarded and the confirmation is shown',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        ' person@example.com ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-send-reset')));
      await tester.pump();

      // Then
      expect(auth.resetCalls, ['person@example.com']);
      expect(find.byKey(const Key('login-reset-confirmation')), findsOneWidget);
      expect(
        find.text('Check your email for a password reset link.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('login-error')), findsNothing);
    },
  );

  testWidgets(
    'Given a FirebaseAuthException, when the reset email fails, then an error message is shown and the confirmation is hidden',
    (tester) async {
      // Given
      final auth = _RecordingAuthService()
        ..error = FirebaseAuthException(
          code: 'invalid-email',
          message: 'That address is not valid.',
        );
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-send-reset')));
      await tester.pump();

      // Then
      expect(find.text('Failed to send password reset email.'), findsOneWidget);
      expect(find.byKey(const Key('login-reset-confirmation')), findsNothing);
    },
  );

  testWidgets(
    'Given the reset form, when Back to sign in is tapped, then the password field returns without an error',
    (tester) async {
      // Given
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(400, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-back-to-sign-in')));
      await tester.pump();

      // Then
      expect(textField(tester, 'login-password').decoration?.errorText, isNull);
      expect(signInButton(tester).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('login-password')), 'secret');
      await tester.pump();
      expect(signInButton(tester).onPressed, isNotNull);
    },
  );
}
