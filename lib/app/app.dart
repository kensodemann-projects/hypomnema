import 'package:hypomnema/app/router.dart';
import 'package:hypomnema/core/theme/app_theme.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:material_ui/material_ui.dart';

class MainApp extends StatelessWidget {
  const MainApp({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: AuthGate(authService: authService),
    );
  }
}
