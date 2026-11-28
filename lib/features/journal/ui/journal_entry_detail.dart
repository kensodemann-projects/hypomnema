import 'dart:math' as math;

import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/journal/domain/journal_entry.dart';
import 'package:hypomnema/features/journal/ui/mood_swatch.dart';
import 'package:material_ui/material_ui.dart';

const _privateHeadline = 'Private entry';
const _coverTitle = 'This entry is private';
const _phoneCoverBody =
    "Showing it is for this viewing only and won't change the private setting.";
const _desktopCoverBody =
    "The subject and text are hidden. Showing them is for this viewing only and won't change the private setting.";
const _revealSentence = ' · Showing private content for this viewing';

class JournalEntryDetail extends StatelessWidget {
  const JournalEntryDetail({
    required this.entry,
    required this.when,
    this.card = false,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
    this.note,
    this.onEdit,
    this.contentRevealed = false,
    this.onShowContent,
    this.onHide,
    this.onTogglePrivacy,
    super.key,
  });

  final JournalEntry entry;
  final String when;
  final bool card;
  final EdgeInsetsGeometry padding;
  final String? note;
  final VoidCallback? onEdit;
  final bool contentRevealed;
  final VoidCallback? onShowContent;
  final VoidCallback? onHide;
  final VoidCallback? onTogglePrivacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = theme.extension<AppMetrics>()!;
    final paragraphs = [
      for (final paragraph in _paragraphs(entry.text))
        Text(paragraph, style: theme.textTheme.bodyLarge),
    ];
    final covered = entry.private && !contentRevealed;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Row(
            spacing: 14,
            children: [
              MoodSwatch(mood: entry.mood, size: MoodSwatchSize.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when,
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    _headline(theme, scheme),
                  ],
                ),
              ),
              if (onEdit != null)
                OutlinedButton.icon(
                  key: const Key('journal-edit'),
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.outline),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              if (card) _privacyButton(scheme),
            ],
          ),
          if (card && note != null) _EditableUntilNote(text: note!),
          if (!card && entry.private) ...[
            if (note != null) _EditableUntilNote(text: note!),
            Align(
              alignment: Alignment.centerLeft,
              child: _privacyButton(scheme),
            ),
          ],
          if (!card && !entry.private) _phonePublicPrivacyRow(scheme),
          if (covered)
            _widthBox(
              child: _PrivateCover(desktop: card, onShowContent: onShowContent),
            )
          else if (entry.private) ...[
            _widthBox(
              child: _RevealBanner(entry: entry, desktop: card, onHide: onHide),
            ),
            if (card)
              _widthBox(child: _detailCard(scheme, metrics, paragraphs))
            else
              ...paragraphs,
          ] else if (card)
            _widthBox(child: _detailCard(scheme, metrics, paragraphs))
          else
            ...paragraphs,
        ],
      ),
    );
  }

  Widget _headline(ThemeData theme, ColorScheme scheme) {
    if (!entry.private) {
      return Text(entry.subject, style: theme.textTheme.headlineSmall);
    }
    final color = scheme.onSurfaceVariant;
    return Row(
      spacing: card ? 8 : 6,
      children: [
        Icon(Icons.lock, size: 24, color: color),
        Flexible(
          child: Text(
            _privateHeadline,
            style: theme.textTheme.headlineSmall!.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _phonePublicPrivacyRow(ColorScheme scheme) {
    final button = _privacyButton(scheme);
    if (note == null) {
      return Align(alignment: Alignment.centerLeft, child: button);
    }
    return Row(
      children: [
        Expanded(child: _EditableUntilNote(text: note!)),
        button,
      ],
    );
  }

  Widget _privacyButton(ColorScheme scheme) {
    final makePublic = entry.private;
    final icon = Icon(makePublic ? Icons.lock_open : Icons.lock);
    final label = Text(makePublic ? 'Make Public' : 'Make Private');
    if (card) {
      return TextButton.icon(
        key: const Key('journal-privacy'),
        onPressed: onTogglePrivacy,
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
        icon: icon,
        label: label,
      );
    }
    return OutlinedButton.icon(
      key: const Key('journal-privacy'),
      onPressed: onTogglePrivacy,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
      ),
      icon: icon,
      label: label,
    );
  }

  Widget _widthBox({required Widget child}) {
    if (!card) {
      return SizedBox(width: double.infinity, child: child);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _PrivateCover extends StatelessWidget {
  const _PrivateCover({required this.desktop, required this.onShowContent});

  final bool desktop;
  final VoidCallback? onShowContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = theme.extension<AppMetrics>()!;
    final body = desktop ? _desktopCoverBody : _phoneCoverBody;
    return DecoratedBox(
      key: const Key('journal-private-cover'),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
      ),
      child: CustomPaint(
        painter: DashedRoundedBorderPainter(
          color: scheme.outline,
          strokeWidth: metrics.borderWidth,
          radius: metrics.cardRadius,
        ),
        child: Padding(
          padding: desktop
              ? const EdgeInsets.symmetric(horizontal: 32, vertical: 48)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          child: Column(
            spacing: 12,
            children: [
              Icon(
                Icons.visibility_off,
                size: 44,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              Text(
                _coverTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              FilledButton.tonalIcon(
                key: const Key('journal-show-content'),
                onPressed: onShowContent,
                icon: const Icon(Icons.visibility),
                label: const Text('Show Content'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevealBanner extends StatelessWidget {
  const _RevealBanner({
    required this.entry,
    required this.desktop,
    required this.onHide,
  });

  final JournalEntry entry;
  final bool desktop;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = theme.extension<AppMetrics>()!;
    final foreground = scheme.onSurfaceVariant;
    final subject = Text(
      entry.subject,
      style: theme.textTheme.titleSmall!.copyWith(color: foreground),
    );
    return DecoratedBox(
      key: const Key('journal-private-banner'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(metrics.rowRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Icon(Icons.visibility, size: 20, color: foreground),
            Expanded(
              child: desktop
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        subject,
                        Text(
                          _revealSentence,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: foreground,
                          ),
                        ),
                      ],
                    )
                  : subject,
            ),
            TextButton(
              key: const Key('journal-hide'),
              onPressed: onHide,
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              child: const Text('Hide'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _detailCard(
  ColorScheme scheme,
  AppMetrics metrics,
  List<Widget> paragraphs,
) {
  return DecoratedBox(
    key: const Key('journal-detail-card'),
    decoration: BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(metrics.cardRadius),
      border: Border.all(
        color: scheme.outlineVariant,
        width: metrics.borderWidth,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: paragraphs,
      ),
    ),
  );
}

class _EditableUntilNote extends StatelessWidget {
  const _EditableUntilNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      key: const Key('journal-editable-until'),
      spacing: 6,
      children: [
        Icon(Icons.schedule, size: 16, color: color),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall!.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class DashedRoundedBorderPainter extends CustomPainter {
  const DashedRoundedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

List<String> _paragraphs(String text) {
  return [
    for (final paragraph in text.split(RegExp(r'\n\s*\n')))
      if (paragraph.trim().isNotEmpty) paragraph.trim(),
  ];
}
