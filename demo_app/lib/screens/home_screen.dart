import 'package:flutter/material.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ExcludeSemantics(
          child: Text(['Home', 'Profile', 'Settings'][_currentTab]),
        ),
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _HomeTab(email: widget.email),
          _ProfileTab(email: widget.email),
          _SettingsTab(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

// ─── Home Tab ───

class _HomeTab extends StatelessWidget {
  final String email;
  const _HomeTab({required this.email});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 21, // 1 header + 20 items
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Welcome, $email!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
        }
        final itemNum = index;
        return ListTile(
          title: Text('Item $itemNum'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(content: Text('Tapped Item $itemNum')),
              );
          },
        );
      },
    );
  }
}

// ─── Profile Tab ───

class _ProfileTab extends StatefulWidget {
  final String email;
  const _ProfileTab({required this.email});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('Profile saved!')),
                  );
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tab ───

class _SettingsTab extends StatefulWidget {
  final VoidCallback onLogout;
  const _SettingsTab({required this.onLogout});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Dark Mode'),
          value: _darkMode,
          onChanged: (v) => setState(() => _darkMode = v),
        ),
        SwitchListTile(
          title: const Text('Notifications'),
          value: _notifications,
          onChanged: (v) => setState(() => _notifications = v),
        ),
        const Divider(),
        ListTile(
          title: const Text('About'),
          trailing: const Icon(Icons.info_outline),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('About'),
                content: const Text('iez Demo App v1.0.0\nBuilt to test iez automation.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('Logout'),
          leading: const Icon(Icons.logout, color: Colors.red),
          onTap: widget.onLogout,
        ),
      ],
    );
  }
}
