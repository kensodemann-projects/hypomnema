import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/shared/ui/empty_state.dart';
import 'package:material_ui/material_ui.dart';

const _title = 'Nothing here';
const _message = 'Add something to get started.';
const _actionLabel = 'Add one';

void _expectRole(TextStyle? style, TextStyle? role) {
  expect(style?.fontSize, role?.fontSize);
  expect(style?.fontWeight, role?.fontWeight);
  expect(style?.height, role?.height);
  expect(style?.letterSpacing, role?.letterSpacing);
}

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
      final title = find.text(_title);
      final message = find.text(_message);
      final textTheme = Theme.of(tester.element(title)).textTheme;
      _expectRole(tester.widget<Text>(title).style, textTheme.titleMedium);
      _expectRole(tester.widget<Text>(message).style, textTheme.bodyMedium);
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
        final title = find.text(_title);
        final message = find.text(_message);
        final icon = find.byIcon(Icons.inbox);
        final built = Theme.of(tester.element(title));
        expect(tester.widget<Text>(title).style?.color, scheme.onSurface);
        expect(
          tester.widget<Text>(message).style?.color,
          scheme.onSurfaceVariant,
        );
        expect(
          tester.widget<Icon>(icon).color,
          scheme.primary.withValues(
            alpha: built.extension<AppMetrics>()!.emptyStateIconOpacity,
          ),
        );
        _expectRole(
          tester.widget<Text>(title).style,
          built.textTheme.titleMedium,
        );
        _expectRole(
          tester.widget<Text>(message).style,
          built.textTheme.bodyMedium,
        );
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );
  }
}
