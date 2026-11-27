import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final String title;
  final String message;
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = theme.extension<AppMetrics>()!;
    final actionIcon = this.actionIcon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: scheme.primary.withValues(
            alpha: metrics.emptyStateIconOpacity,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium!.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (actionIcon == null)
          FilledButton(onPressed: onAction, child: Text(actionLabel))
        else
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
          ),
      ],
    );
  }
}
