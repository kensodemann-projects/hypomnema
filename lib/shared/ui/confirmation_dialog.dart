import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

enum ConfirmationStyle { normal, danger }

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
        final desktop = desktopLayoutFor(context);
        final width = desktop ? 440.0 : constraints.maxWidth - 48;
        final gap = desktop ? 16.0 : 14.0;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
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
            style: theme.textTheme.headlineSmall,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: [
              Text(
                widget.message,
                key: const Key('confirmation-message'),
                style: theme.textTheme.bodyMedium!.copyWith(
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
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final foreground = colors.warning;
    final background = colors.warningContainer;

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
                style: theme.textTheme.bodyMedium!.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
