import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/constants/layout.dart';
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

const _resetSentMessage = 'Check your email for a password reset link.';

const _resetFailedMessage = 'A reset link could not be sent. Try again.';

Future<void> pumpLoginScreen(
  WidgetTester tester, {
  required AuthService authService,
  required Size size,
  ThemeData? theme,
}) async {
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey(theme?.brightness),
      theme: theme ?? AppTheme.light,
      themeAnimationStyle: AnimationStyle.noAnimation,
      home: LoginScreen(authService: authService),
    ),
  );
}

FilledButton signInButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byKey(const Key('login-sign-in')));
}

TextButton forgotPasswordButton(WidgetTester tester) {
  return tester.widget<TextButton>(
    find.byKey(const Key('login-forgot-password')),
  );
}

const _snackBarKey = Key('login-snackbar');

Finder snackBarFinder() => find.byKey(_snackBarKey);

void expectSnackBarPlacement(WidgetTester tester) {
  final snackBar = snackBarFinder();
  final button = find.byKey(const Key('login-forgot-password'));
  final scaffold = find.ancestor(of: snackBar, matching: find.byType(Scaffold));
  final snackTop = tester.getTopLeft(snackBar).dy;
  final buttonBottom = tester.getBottomLeft(button).dy;
  expect(snackTop, closeTo(buttonBottom + 16, 1));

  final snackSize = tester.getSize(snackBar);
  final snackLeft = tester.getTopLeft(snackBar).dx;
  final scaffoldLeft = tester.getTopLeft(scaffold).dx;
  final scaffoldWidth = tester.getSize(scaffold).width;
  final leftInset = snackLeft - scaffoldLeft;
  final rightInset =
      scaffoldLeft + scaffoldWidth - (snackLeft + snackSize.width);
  expect(leftInset, closeTo(rightInset, 1));
  expect(scaffoldWidth - snackSize.width, greaterThanOrEqualTo(31));

  final textWidth = tester
      .getSize(find.descendant(of: snackBar, matching: find.byType(Text)))
      .width;
  final iconWidth = tester
      .getSize(find.descendant(of: snackBar, matching: find.byType(Icon)))
      .width;
  expect(snackSize.width, closeTo(16 * 2 + iconWidth + 12 + textWidth, 1));
}

Future<void> expectErrorSnackBar(WidgetTester tester, String message) async {
  await tester.pumpAndSettle();
  final scheme = Theme.of(tester.element(find.byType(LoginScreen))).colorScheme;
  final snackBar = snackBarFinder();
  expect(find.text(message), findsOneWidget);
  expect(tester.widget<Material>(snackBar).color, scheme.errorContainer);
  expect(tester.widget<Text>(find.text(message)).style?.color, scheme.error);
  expect(
    find.descendant(of: snackBar, matching: find.byIcon(Icons.error_outline)),
    findsOneWidget,
  );
  expectSnackBarPlacement(tester);
}

void expectInfoSnackBar(WidgetTester tester) {
  final colors = Theme.of(tester.element(find.byType(LoginScreen)))
      .extension<AppColors>()!;
  final snackBar = snackBarFinder();
  expect(find.text(_resetSentMessage), findsOneWidget);
  expect(tester.widget<Material>(snackBar).color, colors.infoContainer);
  expect(
    tester.widget<Text>(find.text(_resetSentMessage)).style?.color,
    colors.info,
  );
  expect(
    find.descendant(of: snackBar, matching: find.byIcon(Icons.info_outline)),
    findsOneWidget,
  );
  expectSnackBarPlacement(tester);
}

Future<void> dismissSnackBar(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

TextField textField(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key)));
}

Future<void> unfocus(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

TextStyle effectiveStyle(WidgetTester tester, Finder finder) {
  final widget = tester.widget<Text>(finder);
  return DefaultTextStyle.of(tester.element(finder)).style.merge(widget.style);
}

Color textColor(WidgetTester tester, String text) {
  final finder = find.text(text);
  final widget = tester.widget<Text>(finder);
  return widget.style?.color ??
      DefaultTextStyle.of(tester.element(finder)).style.color!;
}

void expectUnsetTypeMetrics(TextStyle? style) {
  expect(style?.fontSize, isNull);
  expect(style?.fontWeight, isNull);
  expect(style?.height, isNull);
  expect(style?.letterSpacing, isNull);
}

void expectMessageUnder(WidgetTester tester, String key, String message) {
  final messageFinder = find.text(message);
  expect(messageFinder, findsOneWidget);
  expect(
    tester.getRect(messageFinder).top,
    greaterThanOrEqualTo(tester.getRect(find.byKey(Key(key))).bottom),
  );
  final decoration = textField(tester, key).decoration;
  expect(decoration?.errorText, isNull);
  expect(decoration?.labelText, isNull);
}

void expectLabelAbove(WidgetTester tester, String label, String key) {
  expect(
    tester.getRect(find.text('$label *')).bottom,
    lessThanOrEqualTo(tester.getRect(find.byKey(Key(key))).top),
  );
}

void expectOutline(
  WidgetTester tester,
  String key, {
  required Color color,
  required double width,
  required EdgeInsets padding,
  required Color fill,
}) {
  final decoration = textField(tester, key).decoration!;
  for (final side in [
    decoration.border,
    decoration.enabledBorder,
    decoration.focusedBorder,
    decoration.disabledBorder,
  ]) {
    final border = side! as OutlineInputBorder;
    expect(border.borderRadius, const BorderRadius.all(Radius.circular(8)));
    expect(border.borderSide.color, color);
    expect(border.borderSide.width, width);
  }
  expect(decoration.filled, isTrue);
  expect(decoration.fillColor, fill);
  expect(decoration.contentPadding, padding);
  expect(decoration.errorText, isNull);
  expect(decoration.labelText, isNull);
  expectUnsetTypeMetrics(textField(tester, key).style);
}

void expectRequiredLabel(
  WidgetTester tester,
  String label,
  ColorScheme scheme,
) {
  final text = tester.widget<Text>(find.text('$label *'));
  final span = text.textSpan! as TextSpan;
  expect(span.style?.color, scheme.onSurfaceVariant);
  expectUnsetTypeMetrics(span.style);
  final asterisk = span.children!.single as TextSpan;
  expect(asterisk.text, '*');
  expect(asterisk.style?.color, scheme.error);
  expectUnsetTypeMetrics(asterisk.style);
}

void main() {
  testWidgets(
    'Given a phone width, when the login screen builds, then the brand stacks above the form',
    (tester) async {
      for (final width in [
        kDesktopLayoutMinWidth - 200,
        kDesktopLayoutMinWidth,
      ]) {
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
      for (final width in [
        kDesktopLayoutMinWidth + 1,
        kDesktopLayoutMinWidth + 400,
      ]) {
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
          final nameStyle = effectiveStyle(tester, find.text('Hypomnema'));
          final quoteStyle = effectiveStyle(tester, find.text(_desktopQuote));
          expect(
            nameStyle.decoration ?? TextDecoration.none,
            TextDecoration.none,
          );
          expect(nameStyle.fontWeight, FontWeight.w400);
          expect(
            quoteStyle.decoration ?? TextDecoration.none,
            TextDecoration.none,
          );
          expect(
            quoteStyle.fontWeight,
            Theme.of(tester.element(find.text(_desktopQuote)))
                .textTheme
                .bodyMedium
                ?.fontWeight,
          );
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
    'Given the sign-in form, when Email and Password render, then the labels sit above the editor chrome',
    (tester) async {
      const relaxed = EdgeInsets.symmetric(horizontal: 14, vertical: 11);
      const tight = EdgeInsets.symmetric(horizontal: 13, vertical: 10);

      for (final width in [
        kDesktopLayoutMinWidth - 200,
        kDesktopLayoutMinWidth + 1,
      ]) {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          // Given
          await pumpLoginScreen(
            tester,
            authService: _RecordingAuthService(),
            size: Size(width, 800),
            theme: theme,
          );
          final scheme = theme.colorScheme;

          // Then
          expectLabelAbove(tester, 'Email', 'login-email');
          expectLabelAbove(tester, 'Password', 'login-password');
          expectRequiredLabel(tester, 'Email', scheme);
          expectRequiredLabel(tester, 'Password', scheme);
          expectOutline(
            tester,
            'login-email',
            color: scheme.outline,
            width: 1,
            padding: relaxed,
            fill: scheme.surface,
          );
          expectOutline(
            tester,
            'login-password',
            color: scheme.outline,
            width: 1,
            padding: relaxed,
            fill: scheme.surface,
          );

          // When
          await tester.tap(find.byKey(const Key('login-email')));
          await tester.pump();

          // Then
          expectOutline(
            tester,
            'login-email',
            color: scheme.primary,
            width: 2,
            padding: tight,
            fill: scheme.surface,
          );

          // When
          await unfocus(tester);

          // Then
          expectMessageUnder(tester, 'login-email', 'Email is required.');
          expectOutline(
            tester,
            'login-email',
            color: scheme.error,
            width: 1,
            padding: relaxed,
            fill: scheme.surface,
          );
          final message = tester.widget<Text>(find.text('Email is required.'));
          expect(message.style?.color, scheme.error);
          expectUnsetTypeMetrics(message.style);

          // When
          await tester.tap(find.byKey(const Key('login-email')));
          await tester.pump();

          // Then
          expect(find.text('Email is required.'), findsOneWidget);
          expectOutline(
            tester,
            'login-email',
            color: scheme.error,
            width: 2,
            padding: tight,
            fill: scheme.surface,
          );
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
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );
      expect(textField(tester, 'login-email').decoration?.errorText, isNull);
      expect(textField(tester, 'login-password').decoration?.errorText, isNull);
      expect(find.text('Email is required.'), findsNothing);
      expect(find.text('Password is required.'), findsNothing);

      // When
      await tester.tap(find.byKey(const Key('login-email')));
      await tester.pump();
      await unfocus(tester);
      await tester.pump(const Duration(milliseconds: 200));

      // Then
      expectMessageUnder(tester, 'login-email', 'Email is required.');
      final errorColor = Theme.of(
        tester.element(find.byKey(const Key('login-email'))),
      ).colorScheme.error;
      expect(textColor(tester, 'Email is required.'), errorColor);

      await tester.tap(find.byKey(const Key('login-password')));
      await tester.pump();
      await unfocus(tester);
      expectMessageUnder(tester, 'login-password', 'Password is required.');
      expect(textColor(tester, 'Password is required.'), errorColor);
    },
  );

  testWidgets(
    'Given an invalid email that has lost focus, when the user changes the email, then the validation error clears and Sign in stays disabled',
    (tester) async {
      // Given
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );
      await tester.enterText(find.byKey(const Key('login-email')), 'person');
      await unfocus(tester);
      expectMessageUnder(tester, 'login-email', 'Enter a valid email address.');
      final scheme = Theme.of(
        tester.element(find.byKey(const Key('login-email'))),
      ).colorScheme;
      expectRequiredLabel(tester, 'Email', scheme);

      // When
      await tester.enterText(find.byKey(const Key('login-email')), 'p');
      await tester.pump();

      // Then
      expect(find.text('Enter a valid email address.'), findsNothing);
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
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
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
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
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
      expect(find.byKey(const Key('login-snackbar')), findsNothing);
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
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
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
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
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
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
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
      await expectErrorSnackBar(tester, 'Authentication failed.');

      await dismissSnackBar(tester);
      expect(find.text('Authentication failed.'), findsNothing);
      expect(find.byKey(const Key('login-snackbar')), findsNothing);
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
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
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
    'Given the sign-in screen, when it first builds, then no reset message is shown',
    (tester) async {
      // Given, when
      await pumpLoginScreen(
        tester,
        authService: _RecordingAuthService(),
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );

      // Then
      expect(find.byKey(const Key('login-snackbar')), findsNothing);
      expect(find.text(_resetSentMessage), findsNothing);
      expect(find.byKey(const Key('login-password')), findsOneWidget);
      expect(find.byKey(const Key('login-sign-in')), findsOneWidget);
      expect(find.byKey(const Key('login-forgot-password')), findsOneWidget);
    },
  );

  testWidgets(
    'Given an empty or malformed email, when Forgot password is tapped, then the email helper is shown and no reset is sent',
    (tester) async {
      // Given
      final auth = _RecordingAuthService();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );
      final forgot = find.byKey(const Key('login-forgot-password'));
      expect(tester.widget<TextButton>(forgot).onPressed, isNotNull);

      // When
      await tester.tap(forgot);
      await tester.pump();

      // Then
      expectMessageUnder(tester, 'login-email', 'Email is required.');
      expect(find.byKey(const Key('login-snackbar')), findsNothing);
      expect(auth.resetCalls, isEmpty);

      // When
      await tester.enterText(find.byKey(const Key('login-email')), 'person');
      await tester.pump();
      expect(tester.widget<TextButton>(forgot).onPressed, isNotNull);
      await tester.tap(forgot);
      await tester.pump();

      // Then
      expectMessageUnder(tester, 'login-email', 'Enter a valid email address.');
      expect(find.byKey(const Key('login-snackbar')), findsNothing);
      expect(auth.resetCalls, isEmpty);
    },
  );

  testWidgets(
    'Given a valid email with surrounding spaces, when Forgot password is tapped, then the trimmed email is sent and the info snackbar is shown',
    (tester) async {
      for (final size in const [
        Size(kDesktopLayoutMinWidth - 200, 800),
        Size(kDesktopLayoutMinWidth + 400, 800),
      ]) {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          // Given
          final auth = _RecordingAuthService();
          await pumpLoginScreen(
            tester,
            authService: auth,
            size: size,
            theme: theme,
          );
          await tester.enterText(
            find.byKey(const Key('login-email')),
            ' person@example.com ',
          );
          await tester.pump();

          // When
          await tester.tap(find.byKey(const Key('login-forgot-password')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 80));
          final movingTop = tester.getTopLeft(snackBarFinder()).dy;
          await tester.pumpAndSettle();

          // Then
          expect(
            movingTop,
            greaterThan(tester.getTopLeft(snackBarFinder()).dy),
          );
          expect(auth.resetCalls, ['person@example.com']);
          expect(find.byKey(const Key('login-password')), findsOneWidget);
          expect(find.byKey(const Key('login-sign-in')), findsOneWidget);
          expect(
            find.byKey(const Key('login-forgot-password')),
            findsOneWidget,
          );
          expectInfoSnackBar(tester);
        }
      }
    },
  );

  testWidgets(
    'Given the auth service throws an AuthException, when Forgot password is tapped, then the reset failure snackbar is shown and then dismissed',
    (tester) async {
      // Given
      final auth = _RecordingAuthService()..error = const AuthException();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
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
      await expectErrorSnackBar(tester, _resetFailedMessage);
      expect(find.text(_resetSentMessage), findsNothing);
      expect(find.byKey(const Key('login-password')), findsOneWidget);
      expect(find.byKey(const Key('login-sign-in')), findsOneWidget);

      await dismissSnackBar(tester);
      expect(find.text(_resetFailedMessage), findsNothing);
      expect(find.byKey(const Key('login-snackbar')), findsNothing);
    },
  );

  testWidgets(
    'Given the reset call has not completed, when Forgot password is tapped, then Sign in and Forgot password stay disabled until it finishes',
    (tester) async {
      // Given
      final auth = _RecordingAuthService()..pending = Completer<void>();
      await pumpLoginScreen(
        tester,
        authService: auth,
        size: const Size(kDesktopLayoutMinWidth - 200, 800),
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'person@example.com',
      );
      await tester.enterText(find.byKey(const Key('login-password')), 'secret');
      await tester.pump();

      // When
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pump();

      // Then
      expect(signInButton(tester).onPressed, isNull);
      expect(forgotPasswordButton(tester).onPressed, isNull);
      expect(auth.resetCalls, ['person@example.com']);
      expect(find.byKey(const Key('login-snackbar')), findsNothing);

      auth.pending!.complete();
      await tester.pump();
      expect(signInButton(tester).onPressed, isNotNull);
      expect(forgotPasswordButton(tester).onPressed, isNotNull);
    },
  );
}
