import 'package:flutter/widget_previews.dart';
import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
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
        final desktop = desktopLayoutForWidth(constraints.maxWidth);
        final options = [
          for (var mood = 1; mood <= 5; mood++)
            _MoodOption(
              mood: mood,
              selected: value == mood,
              width: desktop ? 64 : null,
              onTap: () => onChanged(mood),
            ),
        ];
        final row = desktop
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
          child: desktop
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
    final scheme = Theme.of(context).colorScheme;
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
                      style: TextStyle(
                        fontSize: 12,
                        height: 1,
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

@Preview(name: 'Mood picker — Phone', size: Size(400, 800))
@Preview(name: 'Mood picker — Desktop', size: Size(1000, 700))
Widget previewMoodPicker() {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    home: const Scaffold(body: _MoodPickerPreview()),
  );
}

class _MoodPickerPreview extends StatefulWidget {
  const _MoodPickerPreview();

  @override
  State<_MoodPickerPreview> createState() => _MoodPickerPreviewState();
}

class _MoodPickerPreviewState extends State<_MoodPickerPreview> {
  int? _mood = 3;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _PickerTheme(
          label: 'Light',
          theme: AppTheme.light,
          mood: _mood,
          onChanged: _select,
        ),
        const SizedBox(height: 24),
        _PickerTheme(
          label: 'Dark',
          theme: AppTheme.dark,
          mood: _mood,
          onChanged: _select,
        ),
      ],
    );
  }

  void _select(int mood) {
    setState(() => _mood = mood);
  }
}

class _PickerTheme extends StatelessWidget {
  const _PickerTheme({
    required this.label,
    required this.theme,
    required this.mood,
    required this.onChanged,
  });

  final String label;
  final ThemeData theme;
  final int? mood;
  final ValueChanged<int> onChanged;

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
              MoodPicker(value: mood, onChanged: onChanged),
              MoodSwatch(mood: mood != null ? mood as int : 3),
            ],
          ),
        ),
      ),
    );
  }
}
