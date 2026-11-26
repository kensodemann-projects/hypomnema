import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/ui/mood_picker.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/viewport.dart';

const _fills = <int, Color>{
  1: Color(0xFFE5534B),
  2: Color(0xFFF28C38),
  3: Color(0xFFF5C842),
  4: Color(0xFFA8CC4A),
  5: Color(0xFF4CAF50),
};

const _numberColor = Color(0xFF111111);

Future<void> pumpPicker(
  WidgetTester tester, {
  required ThemeData theme,
  required double width,
  required int? value,
  ValueChanged<int>? onChanged,
}) {
  setLogicalViewportSize(tester, Size(width, 800));
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: MoodPicker(value: value, onChanged: onChanged ?? (_) {}),
      ),
    ),
  );
}

Finder option(int mood) => find.byKey(Key('mood-option-$mood'));

double scaleOf(WidgetTester tester, int mood) {
  final transform = tester.widget<Transform>(
    find.descendant(of: option(mood), matching: find.byType(Transform)),
  );
  return transform.transform.getMaxScaleOnAxis();
}

List<BoxShadow>? ringOf(WidgetTester tester, int mood) {
  final decorations = tester
      .widgetList<DecoratedBox>(
        find.descendant(of: option(mood), matching: find.byType(DecoratedBox)),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>();
  for (final decoration in decorations) {
    final shadow = decoration.boxShadow;
    if (shadow != null) {
      return shadow;
    }
  }
  return null;
}

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final themeName = theme.brightness.name;

    testWidgets(
      'Given the $themeName theme, when the picker is shown, then each mood is a large numbered swatch and only the ends are labeled',
      (tester) async {
        await pumpPicker(tester, theme: theme, width: 800, value: null);

        final swatches = tester
            .widgetList<MoodSwatch>(find.byType(MoodSwatch))
            .toList();
        expect(swatches.map((swatch) => swatch.mood), [1, 2, 3, 4, 5]);
        expect(
          swatches.map((swatch) => swatch.size),
          everyElement(MoodSwatchSize.large),
        );

        for (final mood in _fills.keys) {
          final swatch = find.descendant(
            of: option(mood),
            matching: find.byType(MoodSwatch),
          );
          final text = tester.widget<Text>(
            find.descendant(of: swatch, matching: find.byType(Text)),
          );
          final decoration =
              tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: swatch,
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          expect(text.data, '$mood');
          expect(text.style?.color, _numberColor);
          expect(decoration.color, _fills[mood]);
          expect(tester.getSize(swatch), const Size.square(48));
        }

        final labels = tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .where((data) => data != null && int.tryParse(data) == null)
            .toList();
        expect(labels, ['Awful', 'Great']);

        for (final label in ['Awful', 'Great']) {
          final text = tester.widget<Text>(find.text(label));
          expect(text.style?.fontSize, 12);
          expect(text.style?.color, theme.colorScheme.onSurfaceVariant);
          final line = find
              .ancestor(
                of: find.text(label),
                matching: find.byWidgetPredicate(
                  (widget) => widget is SizedBox && widget.height == 16,
                ),
              )
              .first;
          expect(tester.getSize(line).height, 16);
        }

        for (final mood in [1, 2, 3, 4, 5]) {
          final line = find.descendant(
            of: option(mood),
            matching: find.byWidgetPredicate(
              (widget) => widget is SizedBox && widget.height == 16,
            ),
          );
          final transform = find.descendant(
            of: option(mood),
            matching: find.byType(Transform),
          );
          expect(
            tester.getRect(line).top - tester.getRect(transform).bottom,
            6,
          );
        }

        for (final mood in [2, 3, 4]) {
          final texts = tester
              .widgetList<Text>(
                find.descendant(of: option(mood), matching: find.byType(Text)),
              )
              .map((text) => text.data)
              .toList();
          expect(texts, ['$mood']);
        }
      },
    );

    testWidgets(
      'Given mood 4 is selected in the $themeName theme, when the picker is shown, then that swatch is scaled and ringed',
      (tester) async {
        await pumpPicker(tester, theme: theme, width: 800, value: 4);

        expect(scaleOf(tester, 4), 1.1);
        final ring = ringOf(tester, 4);
        expect(ring, hasLength(2));
        expect(ring![0].color, theme.colorScheme.onSurface);
        expect(ring[0].spreadRadius, 5);
        expect(ring[0].blurRadius, 0);
        expect(ring[1].color, theme.colorScheme.surface);
        expect(ring[1].spreadRadius, 3);
        expect(ring[1].blurRadius, 0);

        final swatch = find.descendant(
          of: option(4),
          matching: find.byType(MoodSwatch),
        );
        final text = tester.widget<Text>(
          find.descendant(of: swatch, matching: find.byType(Text)),
        );
        final fill =
            tester
                    .widget<DecoratedBox>(
                      find.descendant(
                        of: swatch,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        expect(text.data, '4');
        expect(fill.color, _fills[4]);

        for (final mood in [1, 2, 3, 5]) {
          expect(scaleOf(tester, mood), 1);
          expect(ringOf(tester, mood), isNull);
        }
      },
    );

    testWidgets(
      'Given no mood is selected in the $themeName theme, when the picker is shown, then no swatch is scaled or ringed',
      (tester) async {
        await pumpPicker(tester, theme: theme, width: 800, value: null);

        for (final mood in [1, 2, 3, 4, 5]) {
          expect(scaleOf(tester, mood), 1);
          expect(ringOf(tester, mood), isNull);
        }
      },
    );
  }

  testWidgets(
    'Given a standalone swatch, when it is shown, then the digit has no Awful or Great label',
    (tester) async {
      setLogicalViewportSize(
        tester,
        const Size(kDesktopLayoutMinWidth - 200, 800),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: MoodSwatch(mood: 3))),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Awful'), findsNothing);
      expect(find.text('Great'), findsNothing);
    },
  );

  testWidgets(
    'Given the picker, when mood 2 is tapped, then onChanged is called with 2',
    (tester) async {
      int? selected;
      await pumpPicker(
        tester,
        theme: AppTheme.light,
        width: kDesktopLayoutMinWidth - 200,
        value: null,
        onChanged: (mood) => selected = mood,
      );

      await tester.tap(option(2));
      expect(selected, 2);
    },
  );

  for (final width in [kDesktopLayoutMinWidth - 200, kDesktopLayoutMinWidth]) {
    testWidgets(
      'Given a width of $width, when the picker is shown, then the options spread from edge to edge with equal gaps',
      (tester) async {
        await pumpPicker(tester, theme: AppTheme.light, width: width, value: 3);

        final picker = tester.getRect(find.byType(MoodPicker));
        final rects = [
          for (var mood = 1; mood <= 5; mood++) tester.getRect(option(mood)),
        ];
        expect(rects.first.left, moreOrLessEquals(picker.left));
        expect(rects.last.right, moreOrLessEquals(picker.right));
        final gaps = [
          for (var index = 0; index < 4; index++)
            rects[index + 1].left - rects[index].right,
        ];
        for (final gap in gaps) {
          expect(gap, moreOrLessEquals(gaps.first));
          expect(gap, greaterThan(0));
        }
      },
    );
  }

  for (final width in [
    kDesktopLayoutMinWidth + 1,
    kDesktopLayoutMinWidth + 400,
  ]) {
    testWidgets(
      'Given a width of $width, when the picker is shown, then the options are 64 wide and 12 apart',
      (tester) async {
        await pumpPicker(tester, theme: AppTheme.light, width: width, value: 3);

        final picker = tester.getRect(find.byType(MoodPicker));
        final rects = [
          for (var mood = 1; mood <= 5; mood++) tester.getRect(option(mood)),
        ];
        expect(rects.first.left, moreOrLessEquals(picker.left));
        expect(rects.last.right, lessThan(picker.right));
        for (final rect in rects) {
          expect(rect.width, moreOrLessEquals(64));
        }
        for (var index = 0; index < 4; index++) {
          expect(
            rects[index + 1].left - rects[index].right,
            moreOrLessEquals(12),
          );
        }
      },
    );
  }

  test(
    'Given value 0, when a picker is created, then ArgumentError is thrown',
    () {
      expect(
        () => MoodPicker(value: 0, onChanged: (_) {}),
        throwsArgumentError,
      );
    },
  );

  test(
    'Given value 6, when a picker is created, then ArgumentError is thrown',
    () {
      expect(
        () => MoodPicker(value: 6, onChanged: (_) {}),
        throwsArgumentError,
      );
    },
  );
}
