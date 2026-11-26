import 'package:material_ui/material_ui.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.titleSize,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final String title;
  final double titleSize;
  final String message;
  final String actionLabel;
  final IconData? actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actionIcon = this.actionIcon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: scheme.primary.withValues(alpha: 0.8),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
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
