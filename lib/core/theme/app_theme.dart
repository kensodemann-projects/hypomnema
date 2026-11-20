import 'package:material_ui/material_ui.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.warning, required this.warningContainer});

  final Color warning;
  final Color warningContainer;

  @override
  bool operator ==(Object other) {
    return other is AppColors &&
        other.warning == warning &&
        other.warningContainer == warningContainer;
  }

  @override
  int get hashCode => Object.hash(warning, warningContainer);

  @override
  AppColors copyWith({Color? warning, Color? warningContainer}) {
    return AppColors(
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
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
    );
  }
}

class AppTheme {
  static ThemeData get light {
    const primary = Color(0xFF4A55C8);
    const onPrimary = Color(0xFFFFFFFF);
    return ThemeData(
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
        ),
      ],
    );
  }

  static ThemeData get dark {
    const primary = Color(0xFFBCC2FF);
    const onPrimary = Color(0xFF1A237A);
    return ThemeData(
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
        ),
      ],
    );
  }
}
