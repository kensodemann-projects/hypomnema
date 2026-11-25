import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

class JournalEntryDetail extends StatelessWidget {
  const JournalEntryDetail({
    required this.entry,
    required this.when,
    required this.subjectSize,
    this.subjectLetterSpacing,
    this.card = false,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
    super.key,
  });

  final JournalEntry entry;
  final String when;
  final double subjectSize;
  final double? subjectLetterSpacing;
  final bool card;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paragraphs = [
      for (final paragraph in _paragraphs(entry.text))
        Text(
          paragraph,
          style: TextStyle(fontSize: 16, height: 1.75, color: scheme.onSurface),
        ),
    ];
    return Padding(
      padding: padding,
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
                      style: TextStyle(
                        fontSize: subjectSize,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                        letterSpacing: subjectLetterSpacing,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (card)
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    key: const Key('journal-detail-card'),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 14,
                        children: paragraphs,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            ...paragraphs,
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
