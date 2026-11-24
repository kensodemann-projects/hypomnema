import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

const _fills = <int, Color>{
  1: Color(0xFFE5534B),
  2: Color(0xFFF28C38),
  3: Color(0xFFF5C842),
  4: Color(0xFFA8CC4A),
  5: Color(0xFF4CAF50),
};

const _numberColor = Color(0xFF111111);
const _darkBorderColor = Color.fromRGBO(255, 255, 255, 0.18);

const _metrics = <MoodSwatchSize, (double, double, double)>{
  MoodSwatchSize.regular: (28, 7, 15),
  MoodSwatchSize.large: (48, 12, 22),
};

Future<void> pumpSwatch(
  WidgetTester tester, {
  required int mood,
  required MoodSwatchSize size,
  required ThemeData theme,
}) {
  final swatch = size == MoodSwatchSize.regular
      ? MoodSwatch(mood: mood)
      : MoodSwatch(mood: mood, size: size);
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: swatch)),
    ),
  );
}

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final themeName = theme.brightness.name;
    for (final size in MoodSwatchSize.values) {
      final (side, radius, fontSize) = _metrics[size]!;
      for (final mood in _fills.keys) {
        testWidgets(
          'Given mood $mood at ${size.name} in the $themeName theme, when the swatch is shown, then the digit sits on its fill',
          (tester) async {
            await pumpSwatch(tester, mood: mood, size: size, theme: theme);

            final swatch = find.byType(MoodSwatch);
            final text = tester.widget<Text>(
              find.descendant(of: swatch, matching: find.byType(Text)),
            );
            expect(text.data, '$mood');
            expect(text.style?.color, _numberColor);
            expect(text.style?.fontWeight, FontWeight.w700);
            expect(text.style?.fontSize, fontSize);
            expect(
              tester.getRect(find.byType(Text)).center,
              tester.getRect(swatch).center,
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
            expect(decoration.color, _fills[mood]);
            expect(decoration.borderRadius, BorderRadius.circular(radius));
            expect(tester.getSize(swatch), Size.square(side));

            if (theme.brightness == Brightness.dark) {
              final border = decoration.border! as Border;
              expect(border.top.color, _darkBorderColor);
              expect(border.top.width, 1);
              expect(border.top.strokeAlign, BorderSide.strokeAlignInside);
              expect(border.right.color, _darkBorderColor);
              expect(border.bottom.color, _darkBorderColor);
              expect(border.left.color, _darkBorderColor);
            } else {
              expect(decoration.border, isNull);
            }
          },
        );
      }
    }
  }

  test(
    'Given mood 0, when a swatch is created, then ArgumentError is thrown',
    () {
      expect(() => MoodSwatch(mood: 0), throwsArgumentError);
    },
  );

  test(
    'Given mood 6, when a swatch is created, then ArgumentError is thrown',
    () {
      expect(() => MoodSwatch(mood: 6), throwsArgumentError);
    },
  );
}
