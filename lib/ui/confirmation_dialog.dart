import 'package:flutter/widget_previews.dart';
import 'package:hypomnema/ui/app_theme.dart';
import 'package:material_ui/material_ui.dart';

enum ConfirmationStyle { normal, danger }

const _lightWarning = Color(0xFF8A5000);
const _lightWarningContainer = Color(0xFFFFDDB3);
const _darkWarning = Color(0xFFFFB86B);
const _darkWarningContainer = Color(0xFF6A3C00);

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required ConfirmationStyle style,
  String? warning,
}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (context) {
      return ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        style: style,
        warning: warning,
      );
    },
  ).then((confirmed) => confirmed ?? false);
}

class ConfirmationDialog extends StatefulWidget {
  const ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.style,
    this.warning,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final ConfirmationStyle style;
  final String? warning;

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  var _closed = false;

  void _close(bool confirmed) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(confirmed);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth > 600;
        final width = desktop ? 440.0 : constraints.maxWidth - 48;
        final titleSize = desktop ? 22.0 : 20.0;
        final gap = desktop ? 16.0 : 14.0;
        final colorScheme = Theme.of(context).colorScheme;
        final warningText = widget.warning;

        return AlertDialog(
          scrollable: true,
          key: const Key('confirmation-dialog'),
          insetPadding: const EdgeInsets.all(24),
          constraints: BoxConstraints.tightFor(width: width),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          title: Text(
            widget.title,
            key: const Key('confirmation-title'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w400),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: [
              Text(
                widget.message,
                key: const Key('confirmation-message'),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (warningText != null && warningText.isNotEmpty)
                _WarningBanner(text: warningText),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              key: const Key('confirmation-cancel'),
              onPressed: () => _close(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmation-confirm'),
              style: _confirmStyle(colorScheme),
              onPressed: () => _close(true),
              child: Text(widget.confirmLabel),
            ),
          ],
        );
      },
    );
  }

  ButtonStyle _confirmStyle(ColorScheme colorScheme) {
    return switch (widget.style) {
      ConfirmationStyle.normal => FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      ConfirmationStyle.danger => FilledButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      ),
    };
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (Theme.of(context).brightness) {
      Brightness.light => (_lightWarning, _lightWarningContainer),
      Brightness.dark => (_darkWarning, _darkWarningContainer),
    };

    return DecoratedBox(
      key: const Key('confirmation-warning'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          spacing: 12,
          children: [
            Icon(Icons.warning, size: 20, color: foreground),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Confirmation dialog — Phone', size: Size(400, 800))
@Preview(name: 'Confirmation dialog — Desktop', size: Size(1000, 700))
Widget previewConfirmationDialog() {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    home: const _ConfirmationDialogPreview(),
  );
}

class _ConfirmationDialogPreview extends StatefulWidget {
  const _ConfirmationDialogPreview();

  @override
  State<_ConfirmationDialogPreview> createState() =>
      _ConfirmationDialogPreviewState();
}

class _ConfirmationDialogPreviewState
    extends State<_ConfirmationDialogPreview> {
  String _result = 'No result yet.';

  Future<void> _open({
    required String title,
    required String message,
    required String confirmLabel,
    required ConfirmationStyle style,
    String? warning,
  }) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      style: style,
      warning: warning,
    );
    setState(() {
      _result = confirmed ? 'Confirmed.' : 'Canceled.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(_result),
            FilledButton(
              onPressed: () => _open(
                title: 'Continue?',
                message: 'You can keep going from here.',
                confirmLabel: 'Continue',
                style: ConfirmationStyle.normal,
              ),
              child: const Text('Normal'),
            ),
            FilledButton(
              onPressed: () => _open(
                title: 'Continue?',
                message: 'You can keep going from here.',
                confirmLabel: 'Continue',
                style: ConfirmationStyle.normal,
                warning: "This can't be undone.",
              ),
              child: const Text('Normal with warning'),
            ),
            FilledButton(
              onPressed: () => _open(
                title: 'Delete this goal?',
                message: 'This permanently removes the goal.',
                confirmLabel: 'Delete',
                style: ConfirmationStyle.danger,
              ),
              child: const Text('Danger'),
            ),
            FilledButton(
              onPressed: () => _open(
                title: 'Delete this goal?',
                message: 'This permanently removes the goal.',
                confirmLabel: 'Delete',
                style: ConfirmationStyle.danger,
                warning: "This can't be undone.",
              ),
              child: const Text('Danger with warning'),
            ),
          ],
        ),
      ),
    );
  }
}
