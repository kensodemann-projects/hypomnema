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

  void _openEditor(BuildContext context, {JournalEntry? entry}) {
    final desktop = desktopLayoutFor(context);
    Future<void> submit({
      required String subject,
      required int mood,
      required String text,
    }) async {
      final editing = entry;
      if (editing == null) {
        await _submit(subject: subject, mood: mood, text: text);
        return;
      }
      await widget.repository.update(
        entry: editing,
        subject: subject,
        mood: mood,
        text: text,
        private: editing.private,
      );
    }

    final editor = JournalEditor(
      desktop: desktop,
      onSubmit: submit,
      subject: entry?.subject ?? '',
      mood: entry?.mood,
      text: entry?.text ?? '',
    );
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
        builder: (context) => _PhoneEntryScreen(
          repository: widget.repository,
          entry: entry,
          clock: widget.clock,
          onEdit: _openEditor,
        ),
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
    final metrics = Theme.of(context).extension<AppMetrics>()!;
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
              borderRadius: BorderRadius.circular(metrics.cardRadius),
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
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>()!;
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
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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

  Widget _selectedDetail(BuildContext context, List<JournalEntry> entries) {
    final entry = entries.firstWhere((entry) => entry.id == _selectedId);
    final note = journalEditableUntilNote(
      createdAt: entry.createdAt,
      now: widget.clock(),
    );
    return SingleChildScrollView(
      child: JournalEntryDetail(
        entry: entry,
        when: journalDetailWhen(entry, includeYear: true),
        card: true,
        padding: EdgeInsets.zero,
        note: note,
        onEdit: note == null ? null : () => _openEditor(context, entry: entry),
      ),
    );
  }

  Widget _desktopDetailPane(BuildContext context, List<JournalEntry> entries) {
    final metrics = Theme.of(context).extension<AppMetrics>()!;
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
                      constraints: BoxConstraints(maxWidth: metrics.paneWidth),
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
          : _selectedDetail(context, entries),
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

class _PhoneEntryScreen extends StatefulWidget {
  const _PhoneEntryScreen({
    required this.repository,
    required this.entry,
    required this.clock,
    required this.onEdit,
  });

  final JournalEntryRepository repository;
  final JournalEntry entry;
  final DateTime Function() clock;
  final void Function(BuildContext context, {JournalEntry? entry}) onEdit;

  @override
  State<_PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<_PhoneEntryScreen> {
  StreamSubscription<List<JournalEntry>>? _subscription;
  late JournalEntry _entry;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _subscription = widget.repository.watch().listen(
      _onEntries,
      onError: _onWatchError,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onEntries(List<JournalEntry> entries) {
    if (!mounted) {
      return;
    }
    for (final candidate in entries) {
      if (candidate.id == widget.entry.id) {
        setState(() => _entry = candidate);
        return;
      }
    }
    if (_closed || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    _closed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onWatchError(Object error, StackTrace stackTrace) {
    // Keep _entry on screen. The list listener already reports the failure.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = theme.extension<AppMetrics>()!;
    final entry = _entry;
    final note = journalEditableUntilNote(
      createdAt: entry.createdAt,
      now: widget.clock(),
    );
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
                    _BarIconButton(
                      buttonKey: const Key('journal-back'),
                      tooltip: 'Back',
                      icon: Icons.arrow_back,
                      color: scheme.onSurfaceVariant,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        journalEntryBarTitle(entry),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (note != null)
                      _BarIconButton(
                        buttonKey: const Key('journal-edit'),
                        tooltip: 'Edit',
                        icon: Icons.edit,
                        color: scheme.onSurfaceVariant,
                        onPressed: () => widget.onEdit(context, entry: entry),
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
                  note: note,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        key: buttonKey,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        style: IconButton.styleFrom(
          foregroundColor: color,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          fixedSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: color),
      ),
    );
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
