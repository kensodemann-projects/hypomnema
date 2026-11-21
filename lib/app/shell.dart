import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:material_ui/material_ui.dart';

class _NavDestination {
  const _NavDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const _destinations = <_NavDestination>[
  _NavDestination(label: 'Dashboard', icon: Icons.space_dashboard),
  _NavDestination(label: 'Journal', icon: Icons.menu_book),
  _NavDestination(label: 'Archive', icon: Icons.inventory_2),
];

class Shell extends StatefulWidget {
  const Shell({required this.authService, super.key});

  final AuthService authService;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _selectedIndex = 0;

  Future<void> _signOut() async {
    try {
      await widget.authService.signOut();
    } on AuthException {
      // Stay on the current destination. signedIn does not emit false.
    }
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final label = _destinations[_selectedIndex].label;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return DesktopScaffold(
            selectedIndex: _selectedIndex,
            label: label,
            onDestinationSelected: _selectDestination,
            onSignOut: _signOut,
          );
        }
        return PhoneScaffold(
          selectedIndex: _selectedIndex,
          label: label,
          onDestinationSelected: _selectDestination,
          onSignOut: _signOut,
        );
      },
    );
  }
}

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({
    required this.selectedIndex,
    required this.label,
    required this.onDestinationSelected,
    required this.onSignOut,
    super.key,
  });

  final int selectedIndex;
  final String label;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            key: const Key('shell-navigation-rail'),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            trailingAtBottom: true,
            trailing: _SignOutRailButton(onSignOut: onSignOut),
            destinations: [
              for (final destination in _destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          Expanded(child: _ShellContent(label: label)),
        ],
      ),
    );
  }
}

class PhoneScaffold extends StatelessWidget {
  const PhoneScaffold({
    required this.selectedIndex,
    required this.label,
    required this.onDestinationSelected,
    required this.onSignOut,
    super.key,
  });

  final int selectedIndex;
  final String label;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ShellContent(label: label),
      bottomNavigationBar: NavigationBar(
        key: const Key('shell-navigation-bar'),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) async {
          if (index == _destinations.length) {
            await onSignOut();
            return;
          }
          onDestinationSelected(index);
        },
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
          const NavigationDestination(
            icon: Icon(Icons.logout, key: Key('shell-sign-out')),
            label: 'Sign out',
          ),
        ],
      ),
    );
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, key: const Key('shell-content')));
  }
}

class _SignOutRailButton extends StatelessWidget {
  const _SignOutRailButton({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        InkWell(
          key: const Key('shell-sign-out'),
          onTap: () async {
            await onSignOut();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout),
                SizedBox(height: 4),
                Text('Sign out'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
