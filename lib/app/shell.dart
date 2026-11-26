import 'package:hypomnema/core/constants/layout.dart';
import 'package:hypomnema/features/auth/data/auth_service.dart';
import 'package:hypomnema/features/journal/data/journal_entry_repository.dart';
import 'package:hypomnema/features/journal/ui/journal_screen.dart';
import 'package:hypomnema/shared/ui/confirmation_dialog.dart';
import 'package:material_ui/material_ui.dart';

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.build,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder build;
}

class Shell extends StatefulWidget {
  const Shell({
    required this.authService,
    required this.journalEntries,
    super.key,
  });

  final AuthService authService;
  final JournalEntryRepository journalEntries;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _selectedIndex = 0;

  Future<void> _signOut() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Sign out?',
      message: "You'll need your email and password to sign back in.",
      confirmLabel: 'Sign out',
      style: ConfirmationStyle.normal,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      await widget.authService.signOut();
    } on AuthException {
      if (!mounted) {
        return;
      }
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.errorContainer,
          content: Text(
            'Failed to sign out.',
            style: TextStyle(color: scheme.error),
          ),
        ),
      );
    }
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  List<_NavDestination> _destinations() {
    return [
      _NavDestination(
        label: 'Dashboard',
        icon: Icons.space_dashboard,
        build: (context) => const _ShellContent(label: 'Dashboard'),
      ),
      _NavDestination(
        label: 'Journal',
        icon: Icons.menu_book,
        build: (context) => JournalScreen(repository: widget.journalEntries),
      ),
      _NavDestination(
        label: 'Archive',
        icon: Icons.inventory_2,
        build: (context) => const _ShellContent(label: 'Archive'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();
    final content = destinations[_selectedIndex].build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (desktopLayoutForWidth(constraints.maxWidth)) {
          return DesktopScaffold(
            selectedIndex: _selectedIndex,
            content: content,
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
            onDestinationSelected: _selectDestination,
            onSignOut: _signOut,
          );
        }
        return PhoneScaffold(
          selectedIndex: _selectedIndex,
          content: content,
          destinations: [
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
          ],
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
    required this.content,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onSignOut,
    super.key,
  });

  final int selectedIndex;
  final Widget content;
  final List<NavigationRailDestination> destinations;
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
            destinations: destinations,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class PhoneScaffold extends StatelessWidget {
  const PhoneScaffold({
    required this.selectedIndex,
    required this.content,
    required this.destinations,
    required this.onDestinationSelected,
    required this.onSignOut,
    super.key,
  });

  final int selectedIndex;
  final Widget content;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content,
      bottomNavigationBar: NavigationBar(
        key: const Key('shell-navigation-bar'),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) async {
          if (index == destinations.length) {
            await onSignOut();
            return;
          }
          onDestinationSelected(index);
        },
        destinations: [
          ...destinations,
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
        TextButton(
          key: const Key('shell-sign-out'),
          style: TextButton.styleFrom(
            foregroundColor: IconTheme.of(context).color,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            onSignOut();
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout),
              SizedBox(height: 4),
              Text('Sign out'),
            ],
          ),
        ),
      ],
    );
  }
}
