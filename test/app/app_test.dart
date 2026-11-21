import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/app/app.dart';
import 'package:hypomnema/app/shell.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/viewport.dart';

void expectPhoneShellExists() {
  expect(find.byType(Shell), findsOneWidget);
  expect(find.byType(PhoneScaffold), findsOneWidget);
  expect(find.byType(DesktopScaffold), findsNothing);
  expect(find.byType(NavigationBar), findsOneWidget);
  expect(find.byType(NavigationRail), findsNothing);
  expect(find.byType(AppBar), findsNothing);
  expect(find.text('Phone'), findsNothing);
  expect(find.text('Desktop'), findsNothing);
}

void expectPhoneShellNotExists() {
  expect(find.byType(Shell), findsNothing);
  expect(find.byType(PhoneScaffold), findsNothing);
  expect(find.byType(NavigationBar), findsNothing);
  expect(find.byType(AppBar), findsNothing);
}

void expectDesktopShellExists() {
  expect(find.byType(Shell), findsOneWidget);
  expect(find.byType(DesktopScaffold), findsOneWidget);
  expect(find.byType(PhoneScaffold), findsNothing);
  expect(find.byType(NavigationRail), findsOneWidget);
  expect(find.byType(NavigationBar), findsNothing);
  expect(find.byType(AppBar), findsNothing);
  expect(find.text('Desktop'), findsNothing);
  expect(find.text('Phone'), findsNothing);
}

void expectDesktopShellNotExists() {
  expect(find.byType(Shell), findsNothing);
  expect(find.byType(DesktopScaffold), findsNothing);
  expect(find.byType(NavigationRail), findsNothing);
}

void expectContent(WidgetTester tester, String label) {
  expect(
    tester.widget<Text>(find.byKey(const Key('shell-content'))).data,
    label,
  );
}

void expectDestinationIcons() {
  expect(find.byIcon(Icons.space_dashboard), findsOneWidget);
  expect(find.byIcon(Icons.menu_book), findsOneWidget);
  expect(find.byIcon(Icons.inventory_2), findsOneWidget);
  expect(find.byIcon(Icons.logout), findsOneWidget);
}

Finder chromeLabel(Key chromeKey, String label) {
  return find.descendant(of: find.byKey(chromeKey), matching: find.text(label));
}

const _signOutTitle = 'Sign out?';
const _signOutMessage = "You'll need your email and password to sign back in.";
const _signOutFailure = 'Failed to sign out.';
const _phoneChrome = Key('shell-navigation-bar');
const _desktopChrome = Key('shell-navigation-rail');

int shellSelectedIndex(WidgetTester tester) {
  final bar = find.byKey(_phoneChrome);
  if (bar.evaluate().isNotEmpty) {
    return tester.widget<NavigationBar>(bar).selectedIndex;
  }
  return tester
      .widget<NavigationRail>(find.byKey(_desktopChrome))
      .selectedIndex!;
}

Future<_FakeAuthService> _openSignOutDialog(
  WidgetTester tester, {
  required Size size,
  required Key chromeKey,
  required String destination,
  bool throwOnSignOut = false,
}) async {
  final auth = _authEmitting(true)..throwOnSignOut = throwOnSignOut;
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(MainApp(authService: auth));
  await tester.pumpAndSettle();
  await tester.tap(chromeLabel(chromeKey, destination));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('shell-sign-out')));
  await tester.pumpAndSettle();
  return auth;
}

void expectSignOutDialog(WidgetTester tester) {
  expect(
    tester.widget<Text>(find.byKey(const Key('confirmation-title'))).data,
    _signOutTitle,
  );
  expect(
    tester.widget<Text>(find.byKey(const Key('confirmation-message'))).data,
    _signOutMessage,
  );
  expect(find.text('Cancel'), findsOneWidget);
  expect(
    find.descendant(
      of: find.byKey(const Key('confirmation-confirm')),
      matching: find.text('Sign out'),
    ),
    findsOneWidget,
  );
  expect(find.byKey(const Key('confirmation-warning')), findsNothing);
  final button = tester.widget<FilledButton>(
    find.byKey(const Key('confirmation-confirm')),
  );
  final scheme = Theme.of(
    tester.element(find.byKey(const Key('confirmation-confirm'))),
  ).colorScheme;
  expect(
    button.style?.backgroundColor?.resolve(<WidgetState>{}),
    scheme.primary,
  );
  expect(
    button.style?.foregroundColor?.resolve(<WidgetState>{}),
    scheme.onPrimary,
  );
}

void expectSignOutFailureSnackBar(WidgetTester tester) {
  final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
  final scheme = Theme.of(tester.element(find.byType(SnackBar))).colorScheme;
  expect(snackBar.behavior, SnackBarBehavior.floating);
  expect(snackBar.backgroundColor, scheme.errorContainer);
  expect(
    tester.widget<Text>(find.text(_signOutFailure)).style?.color,
    scheme.error,
  );
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
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
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
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
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
  warning: Color(0xFF8A5000),
  warningContainer: Color(0xFFFFDDB3),
  info: Color(0xFF0C5DA8),
  infoContainer: Color(0xFFD4E3FF),
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
  warning: Color(0xFFFFB86B),
  warningContainer: Color(0xFF6A3C00),
  info: Color(0xFFA5C8FF),
  infoContainer: Color(0xFF00468A),
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
  final colors = theme.extension<AppColors>()!;
  expect(colors.warning, palette.warning);
  expect(colors.warningContainer, palette.warningContainer);
  expect(colors.info, palette.info);
  expect(colors.infoContainer, palette.infoContainer);
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
    'Given a width of 400, when the shell builds, then Dashboard is selected',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));

      // When
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();

      // Then
      expectPhoneShellExists();
      expectContent(tester, 'Dashboard');
      final bar = tester.widget<NavigationBar>(
        find.byKey(const Key('shell-navigation-bar')),
      );
      expect(bar.selectedIndex, 0);
      expect(bar.destinations, hasLength(4));
      expect(
        (bar.destinations.last as NavigationDestination).label,
        'Sign out',
      );
      expect(
        chromeLabel(const Key('shell-navigation-bar'), 'Dashboard'),
        findsOneWidget,
      );
      expect(
        chromeLabel(const Key('shell-navigation-bar'), 'Journal'),
        findsOneWidget,
      );
      expect(
        chromeLabel(const Key('shell-navigation-bar'), 'Archive'),
        findsOneWidget,
      );
      expect(
        chromeLabel(const Key('shell-navigation-bar'), 'Sign out'),
        findsOneWidget,
      );
      expectDestinationIcons();
    },
  );

  testWidgets(
    'Given a width of 601, when the shell builds, then Dashboard is selected',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(601, 800));

      // When
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();

      // Then
      expectDesktopShellExists();
      expectContent(tester, 'Dashboard');
      final rail = tester.widget<NavigationRail>(
        find.byKey(const Key('shell-navigation-rail')),
      );
      expect(rail.selectedIndex, 0);
      expect(rail.destinations, hasLength(3));
      expect(rail.trailingAtBottom, isTrue);
      expect(
        chromeLabel(const Key('shell-navigation-rail'), 'Dashboard'),
        findsOneWidget,
      );
      expect(
        chromeLabel(const Key('shell-navigation-rail'), 'Journal'),
        findsOneWidget,
      );
      expect(
        chromeLabel(const Key('shell-navigation-rail'), 'Archive'),
        findsOneWidget,
      );
      expect(
        chromeLabel(const Key('shell-navigation-rail'), 'Sign out'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('shell-sign-out'))).dy,
        greaterThan(
          tester
              .getTopLeft(
                chromeLabel(const Key('shell-navigation-rail'), 'Archive'),
              )
              .dy,
        ),
      );
      expectDestinationIcons();
    },
  );

  testWidgets(
    'Given the phone shell, when Journal and Archive are tapped, then each destination is selected',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();
      expectContent(tester, 'Dashboard');

      // When
      await tester.tap(
        chromeLabel(const Key('shell-navigation-bar'), 'Journal'),
      );
      await tester.pumpAndSettle();

      // Then
      expectContent(tester, 'Journal');
      expect(
        tester
            .widget<NavigationBar>(
              find.byKey(const Key('shell-navigation-bar')),
            )
            .selectedIndex,
        1,
      );

      // When
      await tester.tap(
        chromeLabel(const Key('shell-navigation-bar'), 'Archive'),
      );
      await tester.pumpAndSettle();

      // Then
      expectContent(tester, 'Archive');
      expect(
        tester
            .widget<NavigationBar>(
              find.byKey(const Key('shell-navigation-bar')),
            )
            .selectedIndex,
        2,
      );
    },
  );

  testWidgets(
    'Given the desktop shell, when Journal and Archive are tapped, then each destination is selected',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(601, 800));
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();
      expectContent(tester, 'Dashboard');

      // When
      await tester.tap(
        chromeLabel(const Key('shell-navigation-rail'), 'Journal'),
      );
      await tester.pumpAndSettle();

      // Then
      expectContent(tester, 'Journal');
      expect(
        tester
            .widget<NavigationRail>(
              find.byKey(const Key('shell-navigation-rail')),
            )
            .selectedIndex,
        1,
      );

      // When
      await tester.tap(
        chromeLabel(const Key('shell-navigation-rail'), 'Archive'),
      );
      await tester.pumpAndSettle();

      // Then
      expectContent(tester, 'Archive');
      expect(
        tester
            .widget<NavigationRail>(
              find.byKey(const Key('shell-navigation-rail')),
            )
            .selectedIndex,
        2,
      );
    },
  );

  testWidgets(
    'Given Journal is selected on the phone shell, when the width becomes 601, then Journal stays selected',
    (tester) async {
      // Given
      setLogicalViewportSize(tester, const Size(400, 800));
      await tester.pumpWidget(MainApp(authService: _authEmitting(true)));
      await tester.pumpAndSettle();
      await tester.tap(
        chromeLabel(const Key('shell-navigation-bar'), 'Journal'),
      );
      await tester.pumpAndSettle();
      expectContent(tester, 'Journal');

      // When
      tester.view.physicalSize = const Size(601, 800);
      await tester.pumpAndSettle();

      // Then
      expectDesktopShellExists();
      expectContent(tester, 'Journal');
      expect(
        tester
            .widget<NavigationRail>(
              find.byKey(const Key('shell-navigation-rail')),
            )
            .selectedIndex,
        1,
      );
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
    'Given Journal is selected on the phone shell, when Sign out is tapped, then the confirmation dialog opens',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: _phoneChrome,
        destination: 'Journal',
      );

      // Then
      expectPhoneShellExists();
      expectSignOutDialog(tester);
      expect(auth.signOutCalls, 0);
      expect(shellSelectedIndex(tester), 1);
      expectContent(tester, 'Journal');
    },
  );

  testWidgets(
    'Given Journal is selected on the desktop shell, when Sign out is tapped, then the confirmation dialog opens',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(601, 800),
        chromeKey: _desktopChrome,
        destination: 'Journal',
      );

      // Then
      expectDesktopShellExists();
      expectSignOutDialog(tester);
      expect(auth.signOutCalls, 0);
      expect(shellSelectedIndex(tester), 1);
      expectContent(tester, 'Journal');
    },
  );

  testWidgets(
    'Given the phone sign-out dialog, when Cancel is tapped, then Journal stays selected',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: _phoneChrome,
        destination: 'Journal',
      );

      // When
      await tester.tap(find.byKey(const Key('confirmation-cancel')));
      await tester.pumpAndSettle();

      // Then
      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(auth.signOutCalls, 0);
      expectContent(tester, 'Journal');
      expect(shellSelectedIndex(tester), 1);
      expectPhoneShellExists();
    },
  );

  testWidgets(
    'Given the desktop sign-out dialog, when Cancel is tapped, then Journal stays selected',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(601, 800),
        chromeKey: _desktopChrome,
        destination: 'Journal',
      );

      // When
      await tester.tap(find.byKey(const Key('confirmation-cancel')));
      await tester.pumpAndSettle();

      // Then
      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(auth.signOutCalls, 0);
      expectContent(tester, 'Journal');
      expect(shellSelectedIndex(tester), 1);
      expectDesktopShellExists();
    },
  );

  testWidgets(
    'Given the phone sign-out dialog, when Sign out is confirmed, then the login screen is shown',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: _phoneChrome,
        destination: 'Journal',
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
        chromeKey: _desktopChrome,
        destination: 'Journal',
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
    'Given Archive is selected on the phone shell, when sign-out fails, then the error snackbar is shown and then dismissed',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: _phoneChrome,
        destination: 'Archive',
        throwOnSignOut: true,
      );

      // When
      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

      // Then
      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(auth.signOutCalls, 1);
      expectPhoneShellExists();
      expectContent(tester, 'Archive');
      expect(shellSelectedIndex(tester), 2);
      expectSignOutFailureSnackBar(tester);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      await tester.pump(snackBar.duration);
      await tester.pumpAndSettle();

      expect(find.text(_signOutFailure), findsNothing);
      expectPhoneShellExists();
      expectContent(tester, 'Archive');
    },
  );

  testWidgets(
    'Given Archive is selected on the desktop shell, when sign-out fails, then the error snackbar is shown and then dismissed',
    (tester) async {
      // Given
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(601, 800),
        chromeKey: _desktopChrome,
        destination: 'Archive',
        throwOnSignOut: true,
      );

      // When
      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

      // Then
      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(auth.signOutCalls, 1);
      expectDesktopShellExists();
      expectContent(tester, 'Archive');
      expect(shellSelectedIndex(tester), 2);
      expectSignOutFailureSnackBar(tester);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      await tester.pump(snackBar.duration);
      await tester.pumpAndSettle();

      expect(find.text(_signOutFailure), findsNothing);
      expectDesktopShellExists();
      expectContent(tester, 'Archive');
    },
  );
}
