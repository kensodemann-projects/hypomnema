import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
  });

  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  @override
  bool operator ==(Object other) {
    return other is AppColors &&
        other.warning == warning &&
        other.warningContainer == warningContainer &&
        other.info == info &&
        other.infoContainer == infoContainer;
  }

  @override
  int get hashCode =>
      Object.hash(warning, warningContainer, info, infoContainer);

  @override
  AppColors copyWith({
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return AppColors(
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

@immutable
class AppMetrics extends ThemeExtension<AppMetrics> {
  const AppMetrics({
    required this.paneWidth,
    required this.headerHeight,
    required this.barHeight,
    required this.rowRadius,
    required this.cardRadius,
    required this.borderWidth,
    required this.selectedBorderWidth,
    required this.emptyStateIconOpacity,
  });

  final double paneWidth;
  final double headerHeight;
  final double barHeight;
  final double rowRadius;
  final double cardRadius;
  final double borderWidth;
  final double selectedBorderWidth;
  final double emptyStateIconOpacity;

  @override
  bool operator ==(Object other) {
    return other is AppMetrics &&
        other.paneWidth == paneWidth &&
        other.headerHeight == headerHeight &&
        other.barHeight == barHeight &&
        other.rowRadius == rowRadius &&
        other.cardRadius == cardRadius &&
        other.borderWidth == borderWidth &&
        other.selectedBorderWidth == selectedBorderWidth &&
        other.emptyStateIconOpacity == emptyStateIconOpacity;
  }

  @override
  int get hashCode => Object.hash(
    paneWidth,
    headerHeight,
    barHeight,
    rowRadius,
    cardRadius,
    borderWidth,
    selectedBorderWidth,
    emptyStateIconOpacity,
  );

  @override
  AppMetrics copyWith({
    double? paneWidth,
    double? headerHeight,
    double? barHeight,
    double? rowRadius,
    double? cardRadius,
    double? borderWidth,
    double? selectedBorderWidth,
    double? emptyStateIconOpacity,
  }) {
    return AppMetrics(
      paneWidth: paneWidth ?? this.paneWidth,
      headerHeight: headerHeight ?? this.headerHeight,
      barHeight: barHeight ?? this.barHeight,
      rowRadius: rowRadius ?? this.rowRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      emptyStateIconOpacity:
          emptyStateIconOpacity ?? this.emptyStateIconOpacity,
    );
  }

  @override
  AppMetrics lerp(ThemeExtension<AppMetrics>? other, double t) {
    if (other is! AppMetrics) {
      return this;
    }
    return AppMetrics(
      paneWidth: lerpDouble(paneWidth, other.paneWidth, t)!,
      headerHeight: lerpDouble(headerHeight, other.headerHeight, t)!,
      barHeight: lerpDouble(barHeight, other.barHeight, t)!,
      rowRadius: lerpDouble(rowRadius, other.rowRadius, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      selectedBorderWidth: lerpDouble(
        selectedBorderWidth,
        other.selectedBorderWidth,
        t,
      )!,
      emptyStateIconOpacity: lerpDouble(
        emptyStateIconOpacity,
        other.emptyStateIconOpacity,
        t,
      )!,
    );
  }
}

const _appMetrics = AppMetrics(
  paneWidth: 380.0,
  headerHeight: 72.0,
  barHeight: 64.0,
  rowRadius: 12.0,
  cardRadius: 16.0,
  borderWidth: 1.0,
  selectedBorderWidth: 2.0,
  emptyStateIconOpacity: 0.8,
);

class AppTheme {
  static ThemeData get light {
    const primary = Color(0xFF4A55C8);
    const onPrimary = Color(0xFFFFFFFF);
    final theme = ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: Color(0xFFDFE0FF),
        onPrimaryContainer: Color(0xFF0E1260),
        secondary: primary,
        onSecondary: onPrimary,
        secondaryContainer: Color(0xFFE2E1F5),
        onSecondaryContainer: Color(0xFF1A1B2C),
        surface: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF8F8FD),
        surfaceContainer: Color(0xFFF1F1F8),
        surfaceContainerHigh: Color(0xFFE9E9F2),
        onSurface: Color(0xFF1B1B21),
        onSurfaceVariant: Color(0xFF46464F),
        outline: Color(0xFF777680),
        outlineVariant: Color(0xFFC7C5D0),
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        scrim: Color(0x61000000),
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F4FA),
      extensions: const [
        AppColors(
          warning: Color(0xFF8A5000),
          warningContainer: Color(0xFFFFDDB3),
          info: Color(0xFF0C5DA8),
          infoContainer: Color(0xFFD4E3FF),
        ),
        _appMetrics,
      ],
    );
    return _withComponentThemes(theme);
  }

  static ThemeData get dark {
    const primary = Color(0xFFBCC2FF);
    const onPrimary = Color(0xFF1A237A);
    final theme = ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: Color(0xFF323D9F),
        onPrimaryContainer: Color(0xFFDFE0FF),
        secondary: primary,
        onSecondary: onPrimary,
        secondaryContainer: Color(0xFF44455A),
        onSecondaryContainer: Color(0xFFE2E1F5),
        surface: Color(0xFF1C1C22),
        surfaceContainerLow: Color(0xFF202027),
        surfaceContainer: Color(0xFF25252C),
        surfaceContainerHigh: Color(0xFF2E2E36),
        onSurface: Color(0xFFE4E1E9),
        onSurfaceVariant: Color(0xFFC7C5D0),
        outline: Color(0xFF918F9A),
        outlineVariant: Color(0xFF46464F),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        scrim: Color(0x99000000),
      ),
      scaffoldBackgroundColor: const Color(0xFF131318),
      extensions: const [
        AppColors(
          warning: Color(0xFFFFB86B),
          warningContainer: Color(0xFF6A3C00),
          info: Color(0xFFA5C8FF),
          infoContainer: Color(0xFF00468A),
        ),
        _appMetrics,
      ],
    );
    return _withComponentThemes(theme);
  }
}

ThemeData _withComponentThemes(ThemeData theme) {
  final scheme = theme.colorScheme;
  // ThemeData.textTheme stores colors only. Material adds size, weight,
  // height, and letter spacing when the theme is localized.
  final bodyMedium = ThemeData.localize(
    theme,
    theme.typography.englishLike,
  ).textTheme.bodyMedium!;
  return theme.copyWith(
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.errorContainer,
      contentTextStyle: bodyMedium.copyWith(color: scheme.onErrorContainer),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
    ),
  );
}
