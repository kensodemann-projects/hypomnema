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
