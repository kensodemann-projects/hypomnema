import 'package:flutter/widget_previews.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

enum MoodSwatchSize { regular, large }

class MoodSwatch extends StatelessWidget {
  MoodSwatch({
    required this.mood,
    this.size = MoodSwatchSize.regular,
    super.key,
  }) {
    if (mood < 1 || mood > 5) {
      throw ArgumentError.value(mood, 'mood', 'Must be from 1 through 5.');
    }
  }

  final int mood;
  final MoodSwatchSize size;

  static const _numberColor = Color(0xFF111111);
  static const _darkBorderColor = Color.fromRGBO(255, 255, 255, 0.18);

  static const _fills = <Color>[
    Color(0xFFE5534B),
    Color(0xFFF28C38),
    Color(0xFFF5C842),
    Color(0xFFA8CC4A),
    Color(0xFF4CAF50),
  ];

  @override
  Widget build(BuildContext context) {
    final (side, radius, fontSize) = switch (size) {
      MoodSwatchSize.regular => (28.0, 7.0, 15.0),
      MoodSwatchSize.large => (48.0, 12.0, 22.0),
    };
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: side,
      height: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _fills[mood - 1],
          borderRadius: BorderRadius.circular(radius),
          border: dark
              ? Border.all(
                  color: _darkBorderColor,
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
        ),
        child: Center(
          child: Text(
            '$mood',
            style: TextStyle(
              color: _numberColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Mood swatch — Phone', size: Size(400, 800))
@Preview(name: 'Mood swatch — Desktop', size: Size(1000, 700))
Widget previewMoodSwatch() {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    home: const Scaffold(body: _MoodSwatchPreview()),
  );
}

class _MoodSwatchPreview extends StatelessWidget {
  const _MoodSwatchPreview();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _SwatchTheme(label: 'Light', theme: AppTheme.light),
        const SizedBox(height: 24),
        _SwatchTheme(label: 'Dark', theme: AppTheme.dark),
      ],
    );
  }
}

class _SwatchTheme extends StatelessWidget {
  const _SwatchTheme({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(label),
              const _SwatchRow(size: MoodSwatchSize.regular),
              const _SwatchRow(size: MoodSwatchSize.large),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.size});

  final MoodSwatchSize size;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        for (var mood = 1; mood <= 5; mood++)
          MoodSwatch(mood: mood, size: size),
      ],
    );
  }
}
