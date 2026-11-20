import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:material_ui/material_ui.dart';

class Shell extends StatelessWidget {
  const Shell({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return DesktopScaffold(authService: authService);
        } else {
          return PhoneScaffold(authService: authService);
        }
      },
    );
  }
}

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            key: const Key('shell-side-panel'),
            width: 72,
            height: double.infinity,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Align(
                alignment: Alignment.topCenter,
                child: _SignOutButton(authService: authService),
              ),
            ),
          ),
          const Expanded(child: Center(child: Text('Desktop'))),
        ],
      ),
    );
  }
}

class PhoneScaffold extends StatelessWidget {
  const PhoneScaffold({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [_SignOutButton(authService: authService)]),
      body: const Center(child: Text('Phone')),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('shell-sign-out'),
      tooltip: 'Sign out',
      onPressed: () async {
        try {
          await authService.signOut();
        } on AuthException {
          // Stay on the shell. signedIn does not emit false.
        }
      },
      icon: const Icon(Icons.logout),
    );
  }
}
