import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:hypomnema/features/auth/ui/login_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/viewport.dart';

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

  @override
  Future<void> signOut() async {}

  @override
  Stream<bool> get signedIn => const Stream<bool>.empty();
}

const _desktopQuote =
    'A note kept so it can be found again: a reminder, a memorandum, '
    'a short record of something worth remembering.';

const _phoneQuote = 'A note kept so it can be found again.';

Future<void> pumpLoginScreen(
  WidgetTester tester, {
  required AuthService authService,
  required Size size,
  ThemeData? theme,
}) async {
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      themeAnimationStyle: AnimationStyle.noAnimation,
      home: LoginScreen(authService: authService),
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

void main() {
  testWidgets(
    'Given a phone width, when the login screen builds, then the brand stacks above the form',
    (tester) async {
      for (final width in [400.0, 600.0]) {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          // Given, when
          await pumpLoginScreen(
            tester,
            authService: _RecordingAuthService(),
            size: Size(width, 800),
            theme: theme,
          );

          // Then
          expect(find.byKey(const Key('login-brand')), findsNothing);
          expect(find.byKey(const Key('login-heading')), findsNothing);
          expect(find.text(_desktopQuote), findsNothing);
          expect(find.text('Hypomnema'), findsOneWidget);
          expect(
            tester.widget<Text>(find.text('Hypomnema')).style?.fontSize,
            28,
          );
          expect(find.text(_phoneQuote), findsOneWidget);
          final quote = tester.widget<Text>(find.text(_phoneQuote));
          expect(quote.style?.fontSize, 15);
          expect(quote.style?.fontStyle, FontStyle.italic);
          expect(quote.style?.color, theme.colorScheme.onSurfaceVariant);
          expect(
            tester.getSize(find.byKey(const Key('login-logo'))),
            const Size(72, 72),
          );
          expect(find.byKey(const Key('login-sign-in')), findsOneWidget);
        }
      }
    },
  );

  testWidgets(
    'Given a desktop width, when the login screen builds, then the brand panel sits beside the form',
    (tester) async {
      for (final width in [601.0, 1200.0]) {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          // Given, when
          await pumpLoginScreen(
            tester,
            authService: _RecordingAuthService(),
            size: Size(width, 800),
            theme: theme,
          );

          // Then
          expect(find.text(_phoneQuote), findsNothing);
          expect(find.text(_desktopQuote), findsOneWidget);
          final quote = tester.widget<Text>(find.text(_desktopQuote));
          expect(quote.style?.fontSize, 18);
          expect(quote.style?.fontStyle, FontStyle.italic);
          expect(
            quote.style?.color,
            const Color(0xFFFFFFFF).withValues(alpha: 0.85),
          );
          final name = tester.widget<Text>(find.text('Hypomnema'));
          expect(name.style?.fontSize, 40);
          expect(name.style?.color, const Color(0xFFFFFFFF));
          final heading = tester.widget<Text>(
            find.byKey(const Key('login-heading')),
          );
          expect(heading.data, 'Sign in');
          expect(heading.style?.fontSize, 26);
          expect(
            tester.getSize(find.byKey(const Key('login-logo'))),
            const Size(72, 72),
          );
          expect(
            tester.getSize(find.byKey(const Key('login-form-side'))).width,
            520,
          );
          expect(
            tester
                .widget<ConstrainedBox>(
                  find.byKey(const Key('login-form-column')),
                )
                .constraints
                .maxWidth,
            360,
          );
          final brand = tester.widget<DecoratedBox>(
            find.byKey(const Key('login-brand')),
          );
          final gradient =
              (brand.decoration as BoxDecoration).gradient! as LinearGradient;
          expect(
            gradient.colors,
            theme.brightness == Brightness.light
                ? const [Color(0xFF4A55C8), Color(0xFF2E3694)]
                : const [Color(0xFF2B3290), Color(0xFF151A55)],
          );
          expect(find.byKey(const Key('login-sign-in')), findsOneWidget);
        }
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
    'Given an invalid email that has lost focus, when the user changes the email, then the validation error clears and Sign in stays disabled',
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
    'Given the sign-in form, when it is first shown or the user enters an incomplete or invalid pair, then Sign in stays disabled',
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
    'Given a valid email and an empty password, when the user presses Enter in the password field, then sign-in is not attempted, and when the user enters a password and presses Enter, then the credentials are forwarded',
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
    'Given the auth service throws an AuthException, when the user taps the sign-in button, then the authentication failed message is shown',
    (tester) async {
      // Given
      final auth = _RecordingAuthService()..error = const AuthException();
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
    },
  );

  testWidgets(
    'Given the auth service has not completed sign-in, when the user taps the sign-in button, then Sign in and Forgot password are disabled, and when the call completes, then Sign in is enabled',
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
    'Given the sign-in form, when the user enters an empty, invalid, or valid email, then Forgot password is enabled only for a valid email',
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
    'Given the reset form, when the user clears the email or enters an invalid email, then Send reset email stays disabled, and when the user enters a valid email, then Send reset email is enabled',
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
    'Given the reset form, when the user presses Enter on an invalid email, then no reset email is sent, and when the user presses Enter on a valid email, then the trimmed address is sent',
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
    'Given an email with surrounding spaces on the reset form, when the user taps Send reset email, then the trimmed email is forwarded and the confirmation is shown',
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
    'Given the auth service throws an AuthException, when the user taps Send reset email, then an error message is shown and the confirmation is hidden',
    (tester) async {
      // Given
      final auth = _RecordingAuthService()..error = const AuthException();
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
    'Given the auth service has not completed the password reset, when the user taps Send reset email, then Back to sign in is disabled, and when the call completes, then Back to sign in is enabled',
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
      await tester.pump();
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-send-reset')));
      await tester.pump();

      // Then
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('login-back-to-sign-in')))
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const Key('login-back-to-sign-in')));
      await tester.pump();

      auth.pending!.complete();
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('login-back-to-sign-in')))
            .onPressed,
        isNotNull,
      );
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
