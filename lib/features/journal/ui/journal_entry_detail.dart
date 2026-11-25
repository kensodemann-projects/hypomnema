import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

class JournalEntryDetail extends StatelessWidget {
  const JournalEntryDetail({
    required this.entry,
    required this.when,
    super.key,
  });

  final JournalEntry entry;
  final String when;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Row(
            spacing: 14,
            children: [
              MoodSwatch(mood: entry.mood, size: MoodSwatchSize.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      entry.subject,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final paragraph in _paragraphs(entry.text))
            Text(
              paragraph,
              style: TextStyle(
                fontSize: 16,
                height: 1.75,
                color: scheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _paragraphs(String text) {
  return [
    for (final paragraph in text.split(RegExp(r'\n\s*\n')))
      if (paragraph.trim().isNotEmpty) paragraph.trim(),
  ];
}
