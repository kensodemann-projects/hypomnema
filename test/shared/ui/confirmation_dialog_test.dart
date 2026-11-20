import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/shared/ui/confirmation_dialog.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/viewport.dart';

const _title = 'Delete this goal?';
const _message = 'This permanently removes the goal.';
const _confirmLabel = 'Delete';
const _warning = "This can't be undone.";

Future<Future<bool>> openDialog(
  WidgetTester tester, {
  required Size size,
  ThemeData? theme,
  String? warning,
  ConfirmationStyle style = ConfirmationStyle.normal,
}) async {
  setLogicalViewportSize(tester, size);
  late Future<bool> result;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () {
                result = showConfirmationDialog(
                  context: context,
                  title: _title,
                  message: _message,
                  confirmLabel: _confirmLabel,
                  style: style,
                  warning: warning,
                );
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

Text titled(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('confirmation-title')));
}

Text message(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('confirmation-message')));
}

double dialogWidth(WidgetTester tester) {
  final material = find.descendant(
    of: find.byKey(const Key('confirmation-dialog')),
    matching: find.byType(Material),
  );
  return tester.getSize(material.first).width;
}

void main() {
  testWidgets(
    'Given a phone width, when the dialog opens, then the phone layout shows the title, message, Cancel, and confirm label',
    (tester) async {
      await openDialog(tester, size: const Size(400, 800));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_message), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text(_confirmLabel), findsOneWidget);
      expect(titled(tester).style?.fontSize, 20);
      expect(titled(tester).textAlign, TextAlign.center);
      expect(message(tester).style?.fontSize, 14);
      expect(
        message(tester).style?.color,
        AppTheme.light.colorScheme.onSurfaceVariant,
      );
      expect(dialogWidth(tester), 352);
    },
  );

  testWidgets(
    'Given a desktop width, when the dialog opens, then the desktop layout shows the title, message, Cancel, and confirm label',
    (tester) async {
      await openDialog(tester, size: const Size(601, 800));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_message), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text(_confirmLabel), findsOneWidget);
      expect(titled(tester).style?.fontSize, 22);
      expect(titled(tester).textAlign, TextAlign.center);
      expect(message(tester).style?.fontSize, 14);
      expect(
        message(tester).style?.color,
        AppTheme.light.colorScheme.onSurfaceVariant,
      );
      expect(dialogWidth(tester), 440);
    },
  );

  testWidgets(
    'Given no warning, when the dialog opens, then the warning banner is absent',
    (tester) async {
      await openDialog(tester, size: const Size(400, 800));

      expect(find.byKey(const Key('confirmation-warning')), findsNothing);
    },
  );

  testWidgets(
    'Given an empty warning, when the dialog opens, then the warning banner is absent',
    (tester) async {
      await openDialog(tester, size: const Size(400, 800), warning: '');

      expect(find.byKey(const Key('confirmation-warning')), findsNothing);
    },
  );

  testWidgets(
    'Given a warning in the light theme, when the dialog opens, then the banner shows that warning',
    (tester) async {
      await openDialog(
        tester,
        size: const Size(400, 800),
        theme: AppTheme.light,
        warning: _warning,
      );

      expect(find.text(_warning), findsOneWidget);
      expectBannerColors(
        tester,
        background: const Color(0xFFFFDDB3),
        foreground: const Color(0xFF8A5000),
      );
    },
  );

  testWidgets(
    'Given a warning in the dark theme, when the dialog opens, then the banner uses the dark warning colors',
    (tester) async {
      await openDialog(
        tester,
        size: const Size(400, 800),
        theme: AppTheme.dark,
        warning: _warning,
      );

      expect(find.text(_warning), findsOneWidget);
      expectBannerColors(
        tester,
        background: const Color(0xFF6A3C00),
        foreground: const Color(0xFFFFB86B),
      );
    },
  );

  testWidgets(
    'Given the dialog, when Cancel is tapped, then the dialog closes and the result is false',
    (tester) async {
      final result = await openDialog(tester, size: const Size(400, 800));

      await tester.tap(find.byKey(const Key('confirmation-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(await result, isFalse);
    },
  );

  testWidgets(
    'Given the dialog, when the scrim is tapped, then the dialog closes and the result is false',
    (tester) async {
      final result = await openDialog(tester, size: const Size(400, 800));

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(await result, isFalse);
    },
  );

  testWidgets(
    'Given the normal style, when confirm is tapped, then the dialog closes with true and the primary colors',
    (tester) async {
      final result = await openDialog(
        tester,
        size: const Size(400, 800),
        style: ConfirmationStyle.normal,
      );

      expectConfirmColors(
        tester,
        background: AppTheme.light.colorScheme.primary,
        foreground: AppTheme.light.colorScheme.onPrimary,
      );

      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(await result, isTrue);
    },
  );

  testWidgets(
    'Given a MaterialApp nested under another navigator, when the dialog opens, then the dialog is shown',
    (tester) async {
      setLogicalViewportSize(tester, const Size(400, 800));
      late Future<bool> result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) {
                  return MaterialApp(
                    theme: AppTheme.light,
                    home: Builder(
                      builder: (context) {
                        return Scaffold(
                          body: TextButton(
                            onPressed: () {
                              result = showConfirmationDialog(
                                context: context,
                                title: _title,
                                message: _message,
                                confirmLabel: _confirmLabel,
                                style: ConfirmationStyle.normal,
                              );
                            },
                            child: const Text('Open'),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(_title), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmation-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(await result, isFalse);
    },
  );

  testWidgets(
    'Given the danger style, when confirm is tapped, then the dialog closes with true and the error colors',
    (tester) async {
      final result = await openDialog(
        tester,
        size: const Size(400, 800),
        style: ConfirmationStyle.danger,
      );

      expectConfirmColors(
        tester,
        background: AppTheme.light.colorScheme.error,
        foreground: AppTheme.light.colorScheme.onError,
      );

      await tester.tap(find.byKey(const Key('confirmation-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmation-dialog')), findsNothing);
      expect(await result, isTrue);
    },
  );
}

void expectBannerColors(
  WidgetTester tester, {
  required Color background,
  required Color foreground,
}) {
  final banner = tester.widget<DecoratedBox>(
    find.byKey(const Key('confirmation-warning')),
  );
  final decoration = banner.decoration as BoxDecoration;
  final icon = tester.widget<Icon>(
    find.descendant(
      of: find.byKey(const Key('confirmation-warning')),
      matching: find.byIcon(Icons.warning),
    ),
  );
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byKey(const Key('confirmation-warning')),
      matching: find.byType(Text),
    ),
  );

  expect(decoration.color, background);
  expect(icon.color, foreground);
  expect(text.style?.color, foreground);
}

void expectConfirmColors(
  WidgetTester tester, {
  required Color background,
  required Color foreground,
}) {
  final button = tester.widget<FilledButton>(
    find.byKey(const Key('confirmation-confirm')),
  );
  expect(button.style?.backgroundColor?.resolve(<WidgetState>{}), background);
  expect(button.style?.foregroundColor?.resolve(<WidgetState>{}), foreground);
}
