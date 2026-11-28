import 'dart:math' as math;

import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/ui/mood_picker.dart';
import 'package:hypomnema/shared/ui/form_fields.dart';
import 'package:material_ui/material_ui.dart';

const _dateNote = 'Date and time are set when you save';
const _journalHint = 'Write whatever is on your mind…';
const _saveFailed = 'The entry could not be saved.';
const _phonePrivateSupport = 'Hide subject and text until Show Content';
const _desktopPrivateSupport =
    'Hide the subject and text until you choose Show Content';

class JournalEditor extends StatefulWidget {
  const JournalEditor({
    required this.desktop,
    required this.onSubmit,
    this.subject = '',
    this.mood,
    this.text = '',
    this.private = false,
    super.key,
  });

  final bool desktop;
  final String subject;
  final int? mood;
  final String text;
  final bool private;
  final Future<void> Function({
    required String subject,
    required int mood,
    required String text,
    required bool private,
  })
  onSubmit;

  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  late final TextEditingController _subjectController;
  late final TextEditingController _textController;
  int? _mood;
  late bool _private;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.subject);
    _textController = TextEditingController(text: widget.text);
    _mood = widget.mood;
    _private = widget.private;
    _subjectController.addListener(_onEdited);
    _textController.addListener(_onEdited);
  }

  @override
  void dispose() {
    _subjectController.removeListener(_onEdited);
    _textController.removeListener(_onEdited);
    _subjectController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onEdited() {
    setState(() {});
  }

  bool get _canSave {
    return !_saving &&
        _subjectController.text.trim().isNotEmpty &&
        _mood != null &&
        _textController.text.trim().isNotEmpty;
  }

  void _selectMood(int mood) {
    setState(() => _mood = mood);
  }

  void _setPrivate(bool value) {
    setState(() => _private = value);
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();
    final text = _textController.text.trim();
    final mood = _mood;
    final isPrivate = _private;
    if (_saving || subject.isEmpty || mood == null || text.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSubmit(
        subject: subject,
        mood: mood,
        text: text,
        private: isPrivate,
      );
      if (!mounted) {
        return;
      }
      navigator.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(_saveFailed),
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fields = _EditorFields(
      subjectController: _subjectController,
      textController: _textController,
      mood: _mood,
      desktop: widget.desktop,
      private: _private,
      onMoodChanged: _selectMood,
      onPrivateChanged: _setPrivate,
    );
    if (widget.desktop) {
      return _DesktopEditor(
        onDismiss: _saving ? null : _dismiss,
        onSave: _canSave ? _save : null,
        fields: fields,
        surface: scheme.surface,
      );
    }
    return _PhoneEditor(
      onDismiss: _saving ? null : _dismiss,
      onSave: _canSave ? _save : null,
      fields: fields,
      surface: scheme.surface,
      primary: scheme.primary,
    );
  }
}

class _EditorFields extends StatelessWidget {
  const _EditorFields({
    required this.subjectController,
    required this.textController,
    required this.mood,
    required this.desktop,
    required this.private,
    required this.onMoodChanged,
    required this.onPrivateChanged,
  });

  final TextEditingController subjectController;
  final TextEditingController textController;
  final int? mood;
  final bool desktop;
  final bool private;
  final ValueChanged<int> onMoodChanged;
  final ValueChanged<bool> onPrivateChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: const Key('journal-fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: desktop ? 16 : 14,
      children: [
        OutlineTextField(
          label: 'Subject',
          isRequired: true,
          fieldKey: const Key('journal-subject'),
          controller: subjectController,
          style: textTheme.titleMedium,
        ),
        LabeledField(
          label: 'Mood',
          isRequired: true,
          child: MoodPicker(value: mood, onChanged: onMoodChanged),
        ),
        OutlineTextField(
          label: 'Journal',
          isRequired: true,
          fieldKey: const Key('journal-text'),
          controller: textController,
          style: textTheme.bodyLarge,
          hintText: _journalHint,
          minHeight: desktop ? 260 : 220,
          minLines: desktop ? 9 : 8,
        ),
        _PrivateSwitch(
          value: private,
          desktop: desktop,
          onChanged: onPrivateChanged,
        ),
      ],
    );
  }
}

class _PhoneEditor extends StatelessWidget {
  const _PhoneEditor({
    required this.onDismiss,
    required this.onSave,
    required this.fields,
    required this.surface,
    required this.primary,
  });

  final VoidCallback? onDismiss;
  final VoidCallback? onSave;
  final Widget fields;
  final Color surface;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>()!;
    return Scaffold(
      key: const Key('journal-editor'),
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            ConstrainedBox(
              key: const Key('journal-top-bar'),
              constraints: BoxConstraints(minHeight: metrics.barHeight),
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: Row(
                  children: [
                    _CloseButton(onPressed: onDismiss, size: 48),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('New entry', style: theme.textTheme.titleLarge),
                          const _DateNote(),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const Key('journal-save'),
                      onPressed: onSave,
                      style: TextButton.styleFrom(foregroundColor: primary),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('journal-form'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: fields,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopEditor extends StatelessWidget {
  const _DesktopEditor({
    required this.onDismiss,
    required this.onSave,
    required this.fields,
    required this.surface,
  });

  final VoidCallback? onDismiss;
  final VoidCallback? onSave;
  final Widget fields;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      key: const Key('journal-editor'),
      backgroundColor: surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(720.0, constraints.maxWidth);
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width, minWidth: width),
            child: ListView(
              key: const Key('journal-form'),
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New journal entry',
                            style: theme.textTheme.titleLarge,
                          ),
                          const _DateNote(),
                        ],
                      ),
                    ),
                    _CloseButton(onPressed: onDismiss, size: 36),
                  ],
                ),
                const SizedBox(height: 16),
                fields,
                const SizedBox(height: 16),
                Row(
                  key: const Key('journal-actions'),
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      key: const Key('journal-cancel'),
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                      ),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      key: const Key('journal-save'),
                      onPressed: onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrivateSwitch extends StatelessWidget {
  const _PrivateSwitch({
    required this.value,
    required this.desktop,
    required this.onChanged,
  });

  final bool value;
  final bool desktop;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const Key('journal-private'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Private', style: theme.textTheme.titleMedium),
              Text(
                desktop ? _desktopPrivateSupport : _phonePrivateSupport,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateNote extends StatelessWidget {
  const _DateNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      _dateNote,
      key: const Key('journal-date-note'),
      style: theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed, required this.size});

  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        key: const Key('journal-close'),
        tooltip: 'Close',
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        style: IconButton.styleFrom(
          foregroundColor: color,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          fixedSize: Size(size, size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        icon: Icon(Icons.close, color: color),
      ),
    );
  }
}
