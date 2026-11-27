import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/domain/journal_list.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

class JournalEntryList extends StatelessWidget {
  const JournalEntryList({
    required this.entries,
    required this.now,
    required this.onOpen,
    required this.headingPadding,
    this.selectedId,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    super.key,
  });

  final List<JournalEntry> entries;
  final DateTime now;
  final ValueChanged<JournalEntry> onOpen;
  final EdgeInsets headingPadding;
  final String? selectedId;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final groups = groupJournalEntries(entries: entries, now: now);
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (final group in groups) ...[
            Padding(
              padding: headingPadding,
              child: Text(
                group.heading.toUpperCase(),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final entry in group.entries)
              _JournalEntryRow(
                entry: entry,
                now: now,
                selected: entry.id == selectedId,
                onOpen: onOpen,
              ),
          ],
        ],
      ),
    );
  }
}

class _JournalEntryRow extends StatelessWidget {
  const _JournalEntryRow({
    required this.entry,
    required this.now,
    required this.selected,
    required this.onOpen,
  });

  final JournalEntry entry;
  final DateTime now;
  final bool selected;
  final ValueChanged<JournalEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = theme.extension<AppMetrics>()!;
    final labelColor = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return DecoratedBox(
      key: Key('journal-entry-decoration-${entry.id}'),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(metrics.rowRadius),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? metrics.selectedBorderWidth : metrics.borderWidth,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('journal-entry-${entry.id}'),
          onTap: () => onOpen(entry),
          child: Padding(
            padding: selected
                ? const EdgeInsets.symmetric(horizontal: 11, vertical: 9)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              spacing: 12,
              children: [
                MoodSwatch(mood: entry.mood),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: selected
                            ? theme.textTheme.titleMedium!.copyWith(
                                color: scheme.onPrimaryContainer,
                              )
                            : theme.textTheme.titleMedium,
                      ),
                      Text(
                        journalRowWhen(entry, now),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
