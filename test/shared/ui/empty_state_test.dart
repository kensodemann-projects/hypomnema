import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/shared/ui/empty_state.dart';
import 'package:material_ui/material_ui.dart';

const _title = 'Nothing here';
const _message = 'Add something to get started.';
const _actionLabel = 'Add one';

Future<void> _pumpEmptyState(
  WidgetTester tester, {
  required ThemeData theme,
  IconData? actionIcon = Icons.add,
  VoidCallback? onAction,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: EmptyState(
          icon: Icons.inbox,
          iconSize: 44,
          title: _title,
          titleSize: 18,
          message: _message,
          actionLabel: _actionLabel,
          actionIcon: actionIcon,
          onAction: onAction ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Given a sample empty state, when it builds, then the title, message, and action render and the action fires once',
    (tester) async {
      var taps = 0;
      await _pumpEmptyState(
        tester,
        theme: AppTheme.light,
        onAction: () => taps += 1,
      );

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_message), findsOneWidget);
      expect(find.text(_actionLabel), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisSize, MainAxisSize.min);
      expect(column.crossAxisAlignment, CrossAxisAlignment.center);
      expect(column.spacing, 10);
      expect(
        tester.widget<Text>(find.text(_title)).style?.fontWeight,
        FontWeight.w600,
      );
      expect(tester.widget<Text>(find.text(_message)).style?.fontSize, 14);
      expect(
        tester.widget<Text>(find.text(_message)).textAlign,
        TextAlign.center,
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(taps, 1);
    },
  );

  testWidgets(
    'Given no action icon, when the empty state builds, then the action is still a filled button',
    (tester) async {
      await _pumpEmptyState(tester, theme: AppTheme.light, actionIcon: null);

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text(_actionLabel), findsOneWidget);
    },
  );

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final themeName = theme.brightness.name;
    testWidgets(
      'Given the $themeName theme, when the empty state builds, then the title, message, and icon use the scheme colors',
      (tester) async {
        await _pumpEmptyState(tester, theme: theme);

        final scheme = theme.colorScheme;
        expect(
          tester.widget<Text>(find.text(_title)).style?.color,
          scheme.onSurface,
        );
        expect(
          tester.widget<Text>(find.text(_message)).style?.color,
          scheme.onSurfaceVariant,
        );
        expect(
          tester.widget<Icon>(find.byIcon(Icons.inbox)).color,
          scheme.primary.withValues(alpha: 0.8),
        );
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );
  }
}
