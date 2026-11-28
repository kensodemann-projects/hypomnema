import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

class JournalEntryDetail extends StatelessWidget {
  const JournalEntryDetail({
    required this.entry,
    required this.when,
    this.card = false,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
    super.key,
  });

  final JournalEntry entry;
  final String when;
  final bool card;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = theme.extension<AppMetrics>()!;
    final paragraphs = [
      for (final paragraph in _paragraphs(entry.text))
        Text(paragraph, style: theme.textTheme.bodyLarge),
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
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(entry.subject, style: theme.textTheme.headlineSmall),
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
                      borderRadius: BorderRadius.circular(metrics.cardRadius),
                      border: Border.all(
                        color: scheme.outlineVariant,
                        width: metrics.borderWidth,
                      ),
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
