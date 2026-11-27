import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

class MoodPicker extends StatelessWidget {
  MoodPicker({required this.value, required this.onChanged, super.key}) {
    if (value != null && (value! < 1 || value! > 5)) {
      throw ArgumentError.value(value, 'value', 'Must be from 1 through 5.');
    }
  }

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = desktopLayoutForWidth(constraints.maxWidth);
        final options = [
          for (var mood = 1; mood <= 5; mood++)
            _MoodOption(
              mood: mood,
              selected: value == mood,
              width: wide ? 64 : null,
              onTap: () => onChanged(mood),
            ),
        ];
        final row = wide
            ? Row(
                spacing: 12,
                mainAxisSize: MainAxisSize.min,
                children: options,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: options,
              );
        return SizedBox(
          width: constraints.maxWidth,
          child: wide
              ? Align(alignment: Alignment.centerLeft, child: row)
              : row,
        );
      },
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.selected,
    required this.onTap,
    required this.width,
  });

  final int mood;
  final bool selected;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = switch (mood) {
      1 => 'Awful',
      5 => 'Great',
      _ => null,
    };

    return GestureDetector(
      key: Key('mood-option-$mood'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Transform.scale(
              scale: selected ? 1.1 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  boxShadow: selected ? _selectionRing(scheme) : null,
                ),
                child: MoodSwatch(mood: mood, size: MoodSwatchSize.large),
              ),
            ),
            SizedBox(
              height: 16,
              child: label == null
                  ? null
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

List<BoxShadow> _selectionRing(ColorScheme scheme) {
  // Painted back to front, so the surface shadow covers all but the outer
  // 2px of the onSurface shadow.
  return [
    BoxShadow(color: scheme.onSurface, spreadRadius: 5, blurRadius: 0),
    BoxShadow(color: scheme.surface, spreadRadius: 3, blurRadius: 0),
  ];
}
