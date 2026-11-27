import 'dart:async';

import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
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
  StreamSubscription<List<JournalEntry>>? _subscription;
  List<JournalEntry>? _cachedEntries;
  var _watchFailed = false;
  var _reportedWatchError = false;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _listenEntries();
  }

  @override
  void didUpdateWidget(JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _subscription?.cancel();
      _cachedEntries = null;
      _watchFailed = false;
      _reportedWatchError = false;
      _listenEntries();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenEntries() {
    _subscription = widget.repository.watch().listen(
      _onEntries,
      onError: _onWatchError,
    );
  }

  void _onEntries(List<JournalEntry> entries) {
    if (!mounted) {
      return;
    }
    final nextId = _reconcileJournalSelection(entries, _selectedId);
    setState(() {
      _cachedEntries = entries;
      _watchFailed = false;
      _selectedId = nextId;
    });
  }

  void _onWatchError(Object error, StackTrace stackTrace) {
    if (!mounted) {
      return;
    }
    setState(() {
      _watchFailed = true;
      _cachedEntries = null;
    });
    _reportWatchError();
  }

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
    final desktop = desktopLayoutFor(context);
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
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final metrics = theme.extension<AppMetrics>()!;
          return Scaffold(
            key: const Key('journal-entry-screen'),
            backgroundColor: scheme.surface,
            body: SafeArea(
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: metrics.barHeight),
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
                              style: theme.textTheme.titleLarge,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(_loadFailed),
        ),
      );
    });
  }

  Widget _phoneLayout(BuildContext context, ColorScheme scheme) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>()!;
    return Column(
      children: [
        ColoredBox(
          color: scheme.surface,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.barHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Journal',
                  key: const Key('journal-title'),
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: _entriesBody(context, scheme, desktop: false)),
      ],
    );
  }

  Widget _desktopLayout(BuildContext context, ColorScheme scheme) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>()!;
    return Column(
      children: [
        DecoratedBox(
          key: const Key('journal-header'),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant,
                width: metrics.borderWidth,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.headerHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Journal',
                      key: const Key('journal-title'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('journal-write'),
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Write'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _entriesBody(context, scheme, desktop: true)),
      ],
    );
  }

  Widget _entriesBody(
    BuildContext context,
    ColorScheme scheme, {
    required bool desktop,
  }) {
    if (_watchFailed) {
      return const SizedBox.shrink();
    }
    final entries = _cachedEntries;
    if (entries == null) {
      return const Center(
        child: CircularProgressIndicator(key: Key('journal-loading')),
      );
    }
    if (desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _desktopListPane(context, scheme, entries),
          Expanded(child: _desktopDetailPane(context, entries)),
        ],
      );
    }
    return _phoneListPane(context, entries);
  }

  Widget _phoneListPane(BuildContext context, List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: EmptyState(
            key: const Key('journal-empty'),
            icon: Icons.edit_note,
            iconSize: 44,
            title: _emptyTitle,
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
          headingPadding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          onOpen: (entry) => _openEntry(context, entry),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            key: const Key('journal-write'),
            onPressed: () => _openEditor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Theme.of(context).extension<AppMetrics>()!.cardRadius,
              ),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Write'),
          ),
        ),
      ],
    );
  }

  Widget _desktopListPane(
    BuildContext context,
    ColorScheme scheme,
    List<JournalEntry> entries,
  ) {
    final metrics = Theme.of(context).extension<AppMetrics>()!;
    return SizedBox(
      key: const Key('journal-list-pane'),
      width: metrics.paneWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            right: BorderSide(
              color: scheme.outlineVariant,
              width: metrics.borderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    child: Text(
                      'No entries yet.',
                      key: const Key('journal-list-empty'),
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              : JournalEntryList(
                  key: const Key('journal-list'),
                  entries: entries,
                  now: widget.clock(),
                  selectedId: _selectedId,
                  headingPadding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                  padding: EdgeInsets.zero,
                  onOpen: (entry) => setState(() => _selectedId = entry.id),
                ),
        ),
      ),
    );
  }

  Widget _selectedDetail(List<JournalEntry> entries) {
    final entry = entries.firstWhere((entry) => entry.id == _selectedId);
    return SingleChildScrollView(
      child: JournalEntryDetail(
        entry: entry,
        when: journalDetailWhen(entry, includeYear: true),
        card: true,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _desktopDetailPane(BuildContext context, List<JournalEntry> entries) {
    return Padding(
      key: const Key('journal-detail-pane'),
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      child: entries.isEmpty
          ? CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Theme.of(context)
                            .extension<AppMetrics>()!
                            .paneWidth,
                      ),
                      child: EmptyState(
                        key: const Key('journal-empty'),
                        icon: Icons.edit_note,
                        iconSize: 48,
                        title: _emptyTitle,
                        message: _emptyMessage,
                        actionLabel: _emptyAction,
                        actionIcon: Icons.edit,
                        onAction: () => _openEditor(context),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _selectedDetail(entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (desktopLayoutFor(context)) {
      return Scaffold(body: _desktopLayout(context, scheme));
    }
    return Scaffold(body: _phoneLayout(context, scheme));
  }
}

String? _reconcileJournalSelection(
  List<JournalEntry> entries,
  String? current,
) {
  if (entries.isEmpty) {
    return null;
  }
  if (current != null && entries.any((entry) => entry.id == current)) {
    return current;
  }
  return entries.first.id;
}
