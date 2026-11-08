import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
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
    MaterialApp(
      home: LoginScreen(key: ValueKey(size), authService: authService),
    ),
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

Future<Color> pixelColor(WidgetTester tester, Offset position) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final x = position.dx.round().clamp(0, image.width - 1);
  final y = position.dy.round().clamp(0, image.height - 1);
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

void main() {
  testWidgets(
    'Given a phone width, when the login screen builds, then the column is inset by 16 and has no card',
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
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Padding && widget.padding == const EdgeInsets.all(16),
          ),
          findsOneWidget,
        );
        expect(find.text('Phone'), findsNothing);
        expect(find.text('Desktop'), findsNothing);
      }
    },
  );

  testWidgets(
    'Given a desktop width, when the login screen builds, then the form sits in a card padded by 24',
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
        expect(
          find.descendant(
            of: find.byKey(const Key('login-form-card')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Padding &&
                  widget.padding == const EdgeInsets.all(24),
            ),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'Given the sign-in form, when it builds, then the fields and button use the planned gaps',
    (tester) async {
      // Given, when
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(400, 800),
      );

      // Then
      final email = tester.getRect(find.byKey(const Key('login-email')));
      final password = tester.getRect(find.byKey(const Key('login-password')));
      final signIn = tester.getRect(find.byKey(const Key('login-sign-in')));
      expect(password.top - email.bottom, 16);
      expect(signIn.top - password.bottom, 24);
      final forgot = tester.getRect(
        find.byKey(const Key('login-forgot-password')),
      );
      expect(forgot.top - signIn.bottom, 8);
    },
  );

  testWidgets(
    'Given empty fields, when a field loses focus, then its required message appears in the error color',
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
      expect(emailField.decoration?.errorStyle, isNull);
      expect(emailField.decoration?.errorBorder, isNull);
      expect(emailField.decoration?.focusedErrorBorder, isNull);
      final errorColor = Theme.of(
        tester.element(find.byKey(const Key('login-email'))),
      ).colorScheme.error;
      expect(textColor(tester, 'Email is required.'), errorColor);
      expect(textColor(tester, 'Email'), errorColor);
      final emailRect = tester.getRect(find.byKey(const Key('login-email')));
      Color? borderColor;
      for (var y = 0; y < emailRect.height; y++) {
        final color = await pixelColor(
          tester,
          Offset(emailRect.center.dx, emailRect.top + y),
        );
        if (color == errorColor) {
          borderColor = color;
          break;
        }
      }
      expect(borderColor, errorColor);

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
    'Given a FirebaseAuthException, when sign-in fails, then the message or code is shown',
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
      expect(find.text('Wrong password.'), findsOneWidget);

      auth.error = FirebaseAuthException(code: 'invalid-credential');
      await tester.tap(find.byKey(const Key('login-sign-in')));
      await tester.pump();
      expect(find.text('invalid-credential'), findsOneWidget);
      expect(find.text('Wrong password.'), findsNothing);
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
    'Given the reset form, when the email is cleared, then Send reset email does not call AuthService',
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

      // When
      await tester.enterText(find.byKey(const Key('login-email')), '');
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-send-reset')));
      await tester.pump();

      // Then
      expect(auth.resetCalls, isEmpty);
      expect(
        textField(tester, 'login-email').decoration?.errorText,
        'Email is required.',
      );
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
    'Given a FirebaseAuthException, when the reset email fails, then the message is shown and the confirmation is hidden',
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
      expect(find.text('That address is not valid.'), findsOneWidget);
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

  testWidgets(
    'Given the reset form, when the width changes, then the card and the button gaps follow the sign-in layout',
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

      // Then
      expect(find.byKey(const Key('login-form-card')), findsNothing);
      final email = tester.getRect(find.byKey(const Key('login-email')));
      final send = tester.getRect(find.byKey(const Key('login-send-reset')));
      final back = tester.getRect(
        find.byKey(const Key('login-back-to-sign-in')),
      );
      expect(send.top - email.bottom, 24);
      expect(back.top - send.bottom, 8);

      // When
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(601, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();

      // Then
      expect(
        find.descendant(
          of: find.byKey(const Key('login-form-card')),
          matching: find.byKey(const Key('login-send-reset')),
        ),
        findsOneWidget,
      );
    },
  );
}
