import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/domain/journal_list.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

class JournalEntryList extends StatelessWidget {
  const JournalEntryList({
    required this.entries,
    required this.now,
    required this.onOpen,
    super.key,
  });

  final List<JournalEntry> entries;
  final DateTime now;
  final ValueChanged<JournalEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = groupJournalEntries(entries: entries, now: now);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                group.heading.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.72,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final entry in group.entries)
              _JournalEntryRow(entry: entry, now: now, onOpen: onOpen),
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
    required this.onOpen,
  });

  final JournalEntry entry;
  final DateTime now;
  final ValueChanged<JournalEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: Key('journal-entry-decoration-${entry.id}'),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('journal-entry-${entry.id}'),
          onTap: () => onOpen(entry),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        journalRowWhen(entry, now),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
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
