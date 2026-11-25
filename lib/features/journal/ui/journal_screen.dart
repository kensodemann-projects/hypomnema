import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/domain/journal_list.dart';
import 'package:hypomnema/features/journal/ui/journal_editor.dart';
import 'package:hypomnema/features/journal/ui/journal_entry_detail.dart';
import 'package:hypomnema/features/journal/ui/journal_entry_list.dart';
import 'package:hypomnema/shared/ui/empty_state.dart';
import 'package:material_ui/material_ui.dart';

const _emptyTitle = 'Start your journal';
const _emptyMessage =
    "Write about anything: how today went, something on your mind, or one good thing. If you're not sure where to start, I'm Stuck gives you a prompt.";
const _emptyAction = 'Write your first entry';
const _loadFailed = 'The entries could not be loaded.';

class JournalScreen extends StatefulWidget {
  const JournalScreen({
    required this.repository,
    this.clock = _currentTime,
    super.key,
  });

  final JournalEntryRepository repository;
  final DateTime Function() clock;

  static DateTime _currentTime() => DateTime.now();

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final Stream<List<JournalEntry>> _entries = widget.repository.watch();
  var _reportedWatchError = false;

  Future<void> _submit({
    required String subject,
    required int mood,
    required String text,
  }) async {
    await widget.repository.save(
      subject: subject,
      mood: mood,
      text: text,
      private: false,
    );
  }

  void _openEditor(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;
    final editor = JournalEditor(desktop: desktop, onSubmit: _submit);
    if (desktop) {
      showDialog<void>(
        context: context,
        barrierColor: Theme.of(context).colorScheme.scrim,
        builder: (context) => editor,
      );
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => editor));
  }

  void _openEntry(BuildContext context, JournalEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            key: const Key('journal-entry-screen'),
            backgroundColor: scheme.surface,
            body: SafeArea(
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              key: const Key('journal-back'),
                              tooltip: 'Back',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 48,
                                height: 48,
                              ),
                              style: IconButton.styleFrom(
                                foregroundColor: scheme.onSurfaceVariant,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                fixedSize: const Size(48, 48),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              journalEntryBarTitle(entry),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: JournalEntryDetail(
                        entry: entry,
                        when: journalDetailWhen(entry, includeYear: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _reportWatchError() {
    if (_reportedWatchError) {
      return;
    }
    _reportedWatchError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.errorContainer,
          content: Text(_loadFailed, style: TextStyle(color: scheme.error)),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width > 600) {
      return Center(
        child: FilledButton(
          key: const Key('journal-write'),
          onPressed: () => _openEditor(context),
          child: const Text('Write'),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          ColoredBox(
            color: scheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Journal',
                    key: const Key('journal-title'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<JournalEntry>>(
              stream: _entries,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  _reportWatchError();
                  return const SizedBox.shrink();
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      key: Key('journal-loading'),
                    ),
                  );
                }
                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 16,
                      ),
                      child: EmptyState(
                        key: const Key('journal-empty'),
                        icon: Icons.edit_note,
                        iconSize: 44,
                        title: _emptyTitle,
                        titleSize: 17,
                        message: _emptyMessage,
                        actionLabel: _emptyAction,
                        actionIcon: Icons.edit,
                        onAction: () => _openEditor(context),
                      ),
                    ),
                  );
                }
                return Stack(
                  children: [
                    JournalEntryList(
                      key: const Key('journal-list'),
                      entries: entries,
                      now: widget.clock(),
                      onOpen: (entry) => _openEntry(context, entry),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton.extended(
                        key: const Key('journal-write'),
                        onPressed: () => _openEditor(context),
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Write'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
