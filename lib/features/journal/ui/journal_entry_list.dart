import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/domain/journal_list.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

class JournalEntryList extends StatelessWidget {
  const JournalEntryList({
    required this.entries,
    required this.now,
    required this.onOpen,
    required this.headingSize,
    required this.headingLetterSpacing,
    required this.headingPadding,
    this.selectedId,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    super.key,
  });

  final List<JournalEntry> entries;
  final DateTime now;
  final ValueChanged<JournalEntry> onOpen;
  final double headingSize;
  final double headingLetterSpacing;
  final EdgeInsets headingPadding;
  final String? selectedId;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: headingLetterSpacing,
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
    final scheme = Theme.of(context).colorScheme;
    final labelColor = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return DecoratedBox(
      key: Key('journal-entry-decoration-${entry.id}'),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: selected ? scheme.onPrimaryContainer : null,
                        ),
                      ),
                      Text(
                        journalRowWhen(entry, now),
                        style: TextStyle(fontSize: 12, color: labelColor),
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
