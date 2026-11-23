import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

class _FakeAuthService implements AuthService {
  int signOutCalls = 0;
  bool throwOnSignOut = false;

  @override
  Stream<bool> get signedIn => const Stream.empty();

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    if (throwOnSignOut) {
      throw const AuthException();
    }
  }
}

int shellSelectedIndex(WidgetTester tester) {
  final bar = find.byKey(_phoneChrome);
  if (bar.evaluate().isNotEmpty) {
    return tester.widget<NavigationBar>(bar).selectedIndex;
  }
  return tester
      .widget<NavigationRail>(find.byKey(_desktopChrome))
      .selectedIndex!;
}

Future<void> pumpShell(
  WidgetTester tester, {
  required Size size,
  AuthService? authService,
}) async {
  setLogicalViewportSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Shell(authService: authService ?? _FakeAuthService()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<_FakeAuthService> _openSignOutDialog(
  WidgetTester tester, {
  required Size size,
  required Key chromeKey,
  required String destination,
  bool throwOnSignOut = false,
}) async {
  final auth = _FakeAuthService()..throwOnSignOut = throwOnSignOut;
  await pumpShell(tester, size: size, authService: auth);
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

void main() {
  testWidgets(
    'Given a width of 400, when the shell builds, then the phone layout is used',
    (tester) async {
      await pumpShell(tester, size: const Size(400, 800));

      expectPhoneShellExists();
    },
  );

  testWidgets(
    'Given a width of 600, when the shell builds, then the phone layout is used',
    (tester) async {
      await pumpShell(tester, size: const Size(600, 800));

      expectPhoneShellExists();
    },
  );

  testWidgets(
    'Given a width of 601, when the shell builds, then the desktop layout is used',
    (tester) async {
      await pumpShell(tester, size: const Size(601, 800));

      expectDesktopShellExists();
    },
  );

  testWidgets(
    'Given a width of 1200, when the shell builds, then the desktop layout is used',
    (tester) async {
      await pumpShell(tester, size: const Size(1200, 800));

      expectDesktopShellExists();
    },
  );

  testWidgets(
    'Given a width of 400, when the shell builds, then Dashboard is selected',
    (tester) async {
      await pumpShell(tester, size: const Size(400, 800));

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
      await pumpShell(tester, size: const Size(601, 800));

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
      expect(
        tester.getTopLeft(find.byKey(const Key('shell-sign-out'))).dy,
        greaterThan(
          tester
              .getTopLeft(
                find.descendant(
                  of: find.byKey(const Key('shell-navigation-rail')),
                  matching: find.byType(Divider),
                ),
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
      await pumpShell(tester, size: const Size(400, 800));
      expectContent(tester, 'Dashboard');

      await tester.tap(
        chromeLabel(const Key('shell-navigation-bar'), 'Journal'),
      );
      await tester.pumpAndSettle();

      expectContent(tester, 'Journal');
      expect(
        tester
            .widget<NavigationBar>(
              find.byKey(const Key('shell-navigation-bar')),
            )
            .selectedIndex,
        1,
      );

      await tester.tap(
        chromeLabel(const Key('shell-navigation-bar'), 'Archive'),
      );
      await tester.pumpAndSettle();

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
      await pumpShell(tester, size: const Size(601, 800));
      expectContent(tester, 'Dashboard');

      await tester.tap(
        chromeLabel(const Key('shell-navigation-rail'), 'Journal'),
      );
      await tester.pumpAndSettle();

      expectContent(tester, 'Journal');
      expect(
        tester
            .widget<NavigationRail>(
              find.byKey(const Key('shell-navigation-rail')),
            )
            .selectedIndex,
        1,
      );

      await tester.tap(
        chromeLabel(const Key('shell-navigation-rail'), 'Archive'),
      );
      await tester.pumpAndSettle();

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
      await pumpShell(tester, size: const Size(400, 800));
      await tester.tap(
        chromeLabel(const Key('shell-navigation-bar'), 'Journal'),
      );
      await tester.pumpAndSettle();
      expectContent(tester, 'Journal');

      tester.view.physicalSize = const Size(601, 800);
      await tester.pumpAndSettle();

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
    'Given Journal is selected on the phone shell, when Sign out is tapped, then the confirmation dialog opens',
    (tester) async {
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: _phoneChrome,
        destination: 'Journal',
      );

      expectPhoneShellExists();
      expectSignOutDialog(tester);
      expect(auth.signOutCalls, 0);
      expect(shellSelectedIndex(tester), 1);
      expectContent(tester, 'Journal');
    },
  );

  testWidgets(
    'Given the desktop shell, when Sign out is built, then it is a button named Sign out',
    (tester) async {
      await pumpShell(tester, size: const Size(601, 800));
      final handle = tester.ensureSemantics();

      expect(find.byKey(const Key('shell-sign-out')), findsOneWidget);
      expect(
        tester.widget(find.byKey(const Key('shell-sign-out'))),
        isA<TextButton>(),
      );
      final data = tester
          .getSemantics(find.byKey(const Key('shell-sign-out')))
          .getSemanticsData();
      expect(data.label, 'Sign out');
      expect(data.flagsCollection.isButton, isTrue);
      // Focusable nodes expose isFocused as true/false; Tristate.none means not focusable.
      expect(data.flagsCollection.isFocused, isNot(Tristate.none));
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
    },
  );

  testWidgets(
    'Given Journal is selected on the desktop shell, when Sign out is activated from the keyboard, then the confirmation dialog opens',
    (tester) async {
      final auth = _FakeAuthService();
      await pumpShell(tester, size: const Size(601, 800), authService: auth);
      await tester.tap(chromeLabel(_desktopChrome, 'Journal'));
      await tester.pumpAndSettle();

      final focusFinder = find.descendant(
        of: find.byKey(const Key('shell-sign-out')),
        matching: find.byType(Focus),
      );
      expect(focusFinder, findsOneWidget);
      final focusNode = Focus.of(
        tester.element(
          find.descendant(of: focusFinder, matching: find.text('Sign out')),
        ),
      );
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expectDesktopShellExists();
      expectSignOutDialog(tester);
      expect(auth.signOutCalls, 0);
      expect(shellSelectedIndex(tester), 1);
      expectContent(tester, 'Journal');
    },
  );

  testWidgets(
    'Given Journal is selected on the desktop shell, when Sign out is tapped, then the confirmation dialog opens',
    (tester) async {
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(601, 800),
        chromeKey: _desktopChrome,
        destination: 'Journal',
      );

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
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: _phoneChrome,
        destination: 'Journal',
      );

      await tester.tap(find.byKey(const Key('confirmation-cancel')));
      await tester.pumpAndSettle();

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
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(601, 800),
        chromeKey: _desktopChrome,
        destination: 'Journal',
      );

      await tester.tap(find.byKey(const Key('confirmation-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(auth.signOutCalls, 0);
      expectContent(tester, 'Journal');
      expect(shellSelectedIndex(tester), 1);
      expectDesktopShellExists();
    },
  );

  testWidgets(
    'Given Archive is selected on the phone shell, when sign-out fails, then the error snackbar is shown and then dismissed',
    (tester) async {
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(400, 800),
        chromeKey: _phoneChrome,
        destination: 'Archive',
        throwOnSignOut: true,
      );

      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

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
      final auth = await _openSignOutDialog(
        tester,
        size: const Size(601, 800),
        chromeKey: _desktopChrome,
        destination: 'Archive',
        throwOnSignOut: true,
      );

      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

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
