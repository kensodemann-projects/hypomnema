import 'package:flutter_test/flutter_test.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

class _ContractPalette {
  const _ContractPalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.surface,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.scrim,
    required this.scaffoldBackgroundColor,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color surface;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color scrim;
  final Color scaffoldBackgroundColor;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
}

const _lightPalette = _ContractPalette(
  primary: Color(0xFF4A55C8),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDFE0FF),
  onPrimaryContainer: Color(0xFF0E1260),
  secondary: Color(0xFF4A55C8),
  onSecondary: Color(0xFFFFFFFF),
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
  scaffoldBackgroundColor: Color(0xFFF4F4FA),
  warning: Color(0xFF8A5000),
  warningContainer: Color(0xFFFFDDB3),
  info: Color(0xFF0C5DA8),
  infoContainer: Color(0xFFD4E3FF),
);

const _darkPalette = _ContractPalette(
  primary: Color(0xFFBCC2FF),
  onPrimary: Color(0xFF1A237A),
  primaryContainer: Color(0xFF323D9F),
  onPrimaryContainer: Color(0xFFDFE0FF),
  secondary: Color(0xFFBCC2FF),
  onSecondary: Color(0xFF1A237A),
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
  scaffoldBackgroundColor: Color(0xFF131318),
  warning: Color(0xFFFFB86B),
  warningContainer: Color(0xFF6A3C00),
  info: Color(0xFFA5C8FF),
  infoContainer: Color(0xFF00468A),
);

void _expectContractColors(ThemeData theme, _ContractPalette palette) {
  final scheme = theme.colorScheme;
  expect(scheme.primary, palette.primary);
  expect(scheme.onPrimary, palette.onPrimary);
  expect(scheme.primaryContainer, palette.primaryContainer);
  expect(scheme.onPrimaryContainer, palette.onPrimaryContainer);
  expect(scheme.secondary, palette.secondary);
  expect(scheme.onSecondary, palette.onSecondary);
  expect(scheme.secondaryContainer, palette.secondaryContainer);
  expect(scheme.onSecondaryContainer, palette.onSecondaryContainer);
  expect(scheme.surface, palette.surface);
  expect(scheme.surfaceContainerLow, palette.surfaceContainerLow);
  expect(scheme.surfaceContainer, palette.surfaceContainer);
  expect(scheme.surfaceContainerHigh, palette.surfaceContainerHigh);
  expect(scheme.onSurface, palette.onSurface);
  expect(scheme.onSurfaceVariant, palette.onSurfaceVariant);
  expect(scheme.outline, palette.outline);
  expect(scheme.outlineVariant, palette.outlineVariant);
  expect(scheme.error, palette.error);
  expect(scheme.onError, palette.onError);
  expect(scheme.errorContainer, palette.errorContainer);
  expect(scheme.onErrorContainer, palette.onErrorContainer);
  expect(scheme.scrim, palette.scrim);
  expect(theme.scaffoldBackgroundColor, palette.scaffoldBackgroundColor);
  final colors = theme.extension<AppColors>()!;
  expect(colors.warning, palette.warning);
  expect(colors.warningContainer, palette.warningContainer);
  expect(colors.info, palette.info);
  expect(colors.infoContainer, palette.infoContainer);
}

Future<void> _pumpTheme(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(body: SizedBox(key: Key('theme-home'))),
    ),
  );
}

void main() {
  testWidgets(
    'Given AppTheme.light, when a MaterialApp builds, then the light contract is applied',
    (tester) async {
      // When
      await _pumpTheme(tester, AppTheme.light);

      // Then
      _expectContractColors(AppTheme.light, _lightPalette);
      _expectContractColors(
        Theme.of(tester.element(find.byKey(const Key('theme-home')))),
        _lightPalette,
      );
    },
  );

  testWidgets(
    'Given AppTheme.dark, when a MaterialApp builds, then the dark contract is applied',
    (tester) async {
      // When
      await _pumpTheme(tester, AppTheme.dark);

      // Then
      _expectContractColors(AppTheme.dark, _darkPalette);
      _expectContractColors(
        Theme.of(tester.element(find.byKey(const Key('theme-home')))),
        _darkPalette,
      );
    },
  );
}
