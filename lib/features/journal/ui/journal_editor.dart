import 'dart:math' as math;

import 'package:flutter/widget_previews.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/ui/mood_picker.dart';
import 'package:material_ui/material_ui.dart';

const _dateNote = 'Date and time are set when you save';
const _journalHint = 'Write whatever is on your mind…';
const _saveFailed = 'The entry could not be saved.';

class JournalEditor extends StatefulWidget {
  const JournalEditor({
    required this.desktop,
    required this.onSubmit,
    this.subject = '',
    this.mood,
    this.text = '',
    super.key,
  });

  final bool desktop;
  final String subject;
  final int? mood;
  final String text;
  final Future<void> Function({
    required String subject,
    required int mood,
    required String text,
  })
  onSubmit;

  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  late final TextEditingController _subjectController;
  late final TextEditingController _textController;
  int? _mood;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.subject);
    _textController = TextEditingController(text: widget.text);
    _mood = widget.mood;
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

  void _dismiss() {
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();
    final text = _textController.text.trim();
    final mood = _mood;
    if (_saving || subject.isEmpty || mood == null || text.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    try {
      await widget.onSubmit(subject: subject, mood: mood, text: text);
      if (!mounted) {
        return;
      }
      navigator.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.errorContainer,
          content: Text(_saveFailed, style: TextStyle(color: scheme.error)),
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
      onMoodChanged: _selectMood,
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
    required this.onMoodChanged,
  });

  final TextEditingController subjectController;
  final TextEditingController textController;
  final int? mood;
  final bool desktop;
  final ValueChanged<int> onMoodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('journal-fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: desktop ? 16 : 14,
      children: [
        _Field(
          label: 'Subject',
          child: _OutlineField(
            fieldKey: const Key('journal-subject'),
            controller: subjectController,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        _Field(
          label: 'Mood',
          child: MoodPicker(value: mood, onChanged: onMoodChanged),
        ),
        _Field(
          label: 'Journal',
          child: _OutlineField(
            fieldKey: const Key('journal-text'),
            controller: textController,
            style: const TextStyle(fontSize: 16, height: 1.7),
            hintText: _journalHint,
            minHeight: desktop ? 260 : 220,
            minLines: desktop ? 9 : 8,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        _RequiredLabel(label: label),
        child,
      ],
    );
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(
            text: '*',
            style: TextStyle(color: scheme.error),
          ),
        ],
      ),
    );
  }
}

class _OutlineField extends StatefulWidget {
  const _OutlineField({
    required this.fieldKey,
    required this.controller,
    required this.style,
    this.hintText,
    this.minHeight,
    this.minLines,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final TextStyle style;
  final String? hintText;
  final double? minHeight;
  final int? minLines;

  @override
  State<_OutlineField> createState() => _OutlineFieldState();
}

class _OutlineFieldState extends State<_OutlineField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocus() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;
    final padding = focused
        ? const EdgeInsets.symmetric(horizontal: 13, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 11);
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(
        color: focused ? scheme.primary : scheme.outline,
        width: focused ? 2 : 1,
      ),
    );
    final minHeight = widget.minHeight;
    final minLines = widget.minLines;
    final multiline = minLines != null;

    return TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: _focusNode,
      style: widget.style,
      keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
      textInputAction: multiline
          ? TextInputAction.newline
          : TextInputAction.next,
      minLines: minLines,
      maxLines: multiline ? null : 1,
      textAlignVertical: multiline ? TextAlignVertical.top : null,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: scheme.surface,
        contentPadding: padding,
        constraints: minHeight == null
            ? null
            : BoxConstraints(minHeight: minHeight),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        disabledBorder: border,
      ),
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const Key('journal-editor'),
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            ConstrainedBox(
              key: const Key('journal-top-bar'),
              constraints: const BoxConstraints(minHeight: 64),
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
                          Text(
                            'New entry',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: scheme.onSurface,
                            ),
                          ),
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
    final scheme = Theme.of(context).colorScheme;
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
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: scheme.onSurface,
                            ),
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

class _DateNote extends StatelessWidget {
  const _DateNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      _dateNote,
      key: const Key('journal-date-note'),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

Future<void> _previewSubmit({
  required String subject,
  required int mood,
  required String text,
}) async {}

@Preview(name: 'Journal editor — Phone', size: Size(400, 800))
@Preview(name: 'Journal editor — Desktop', size: Size(1000, 700))
Widget previewJournalEditor() {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    home: const _JournalEditorPreview(),
  );
}

class _JournalEditorPreview extends StatelessWidget {
  const _JournalEditorPreview();

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width > 600;
    return ListView(
      children: [
        _PreviewTheme(theme: AppTheme.light, label: 'Light', desktop: desktop),
        _PreviewTheme(theme: AppTheme.dark, label: 'Dark', desktop: desktop),
      ],
    );
  }
}

class _PreviewTheme extends StatelessWidget {
  const _PreviewTheme({
    required this.theme,
    required this.label,
    required this.desktop,
  });

  final ThemeData theme;
  final String label;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SizedBox(
          height: desktop ? 680 : 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(label)),
              Expanded(
                child: desktop
                    ? const Center(
                        child: JournalEditor(
                          onSubmit: _previewSubmit,
                          desktop: true,
                        ),
                      )
                    : const JournalEditor(
                        onSubmit: _previewSubmit,
                        desktop: false,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
