import 'package:flutter/material.dart';

void main() {
  runApp(const PasswordVaultApp());
}

class PasswordVaultApp extends StatelessWidget {
  const PasswordVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class PasswordEntry {
  final String site;
  final String username;
  final String category;
  final String notes;

  const PasswordEntry({
    required this.site,
    required this.username,
    required this.category,
    this.notes = '',
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<PasswordEntry> _passwords = [
    const PasswordEntry(site: 'Gmail', username: 'john@gmail.com', category: 'Social', notes: 'Primary email account'),
    const PasswordEntry(site: 'GitHub', username: 'johndoe', category: 'Work', notes: 'Developer account'),
    const PasswordEntry(site: 'Netflix', username: 'john_stream', category: 'Entertainment', notes: 'Family plan'),
    const PasswordEntry(site: 'Slack', username: 'john.d', category: 'Social', notes: 'Team workspace'),
  ];

  void _addPassword(PasswordEntry entry) {
    setState(() {
      _passwords.add(entry);
    });
  }

  void _deletePassword(int index) {
    setState(() {
      _passwords.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PasswordsTab(
        passwords: _passwords,
        onAdd: _addPassword,
        onDelete: _deletePassword,
      ),
      CategoriesTab(passwords: _passwords),
      const GeneratorTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(passwords: _passwords, onDelete: _deletePassword),
                ),
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lock), label: 'Passwords'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.auto_fix_high), label: 'Generator'),
        ],
      ),
    );
  }
}

// --- Passwords Tab ---

class PasswordsTab extends StatelessWidget {
  final List<PasswordEntry> passwords;
  final void Function(PasswordEntry) onAdd;
  final void Function(int) onDelete;

  const PasswordsTab({
    super.key,
    required this.passwords,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: passwords.length,
        itemBuilder: (context, index) {
          final entry = passwords[index];
          return ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(entry.site),
            subtitle: Text(entry.username),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PasswordDetailPage(
                    entry: entry,
                    onDelete: () {
                      onDelete(index);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPasswordPage(onSave: onAdd),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Password'),
      ),
    );
  }
}

// --- Password Detail Page ---

class PasswordDetailPage extends StatelessWidget {
  final PasswordEntry entry;
  final VoidCallback onDelete;

  const PasswordDetailPage({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Username', entry.username),
          const SizedBox(height: 16),
          _buildSection('Website', entry.site),
          const SizedBox(height: 16),
          _buildSection('Notes', entry.notes.isEmpty ? 'No notes' : entry.notes),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Password'),
                  content: Text('Are you sure you want to delete ${entry.site}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete Password'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18),
        ),
        const Divider(),
      ],
    );
  }
}

// --- Add Password Page ---

class AddPasswordPage extends StatefulWidget {
  final void Function(PasswordEntry) onSave;

  const AddPasswordPage({super.key, required this.onSave});

  @override
  State<AddPasswordPage> createState() => _AddPasswordPageState();
}

class _AddPasswordPageState extends State<AddPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _siteController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedCategory = 'Work';

  final List<String> _categories = ['Social', 'Work', 'Entertainment'];

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Password'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _siteController,
              decoration: const InputDecoration(
                labelText: 'Site Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedCategory = v;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave(PasswordEntry(
                    site: _siteController.text,
                    username: _usernameController.text,
                    category: _selectedCategory,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Password'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Categories Tab ---

class CategoriesTab extends StatelessWidget {
  final List<PasswordEntry> passwords;

  const CategoriesTab({super.key, required this.passwords});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> categoryCounts = {};
    for (final p in passwords) {
      categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
    }

    // Ensure all categories appear even if count is 0
    final allCategories = <String, int>{'Social': 0, 'Work': 0, 'Entertainment': 0};
    allCategories.addAll(categoryCounts);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        ...allCategories.entries.map((e) => ListTile(
          leading: const Icon(Icons.folder),
          title: Text(e.key),
          trailing: Text(
            '${e.value} ${e.value == 1 ? "item" : "items"}',
            style: const TextStyle(color: Colors.grey),
          ),
        )),
      ],
    );
  }
}

// --- Generator Tab ---

class GeneratorTab extends StatefulWidget {
  const GeneratorTab({super.key});

  @override
  State<GeneratorTab> createState() => _GeneratorTabState();
}

class _GeneratorTabState extends State<GeneratorTab> {
  double _length = 16;
  bool _uppercase = true;
  bool _numbers = true;
  bool _symbols = false;
  String _generatedPassword = 'Tap Generate';

  void _generate() {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const nums = '0123456789';
    const syms = r'!@#$%^&*()_+-=[]{}|;:,.<>?';

    String chars = lower;
    if (_uppercase) chars += upper;
    if (_numbers) chars += nums;
    if (_symbols) chars += syms;

    final len = _length.round();
    final buffer = StringBuffer();
    for (int i = 0; i < len; i++) {
      buffer.write(chars[(DateTime.now().microsecondsSinceEpoch + i * 37) % chars.length]);
    }
    setState(() {
      _generatedPassword = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Generator',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Generated Password',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _generatedPassword,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Length'),
        Slider(
          value: _length,
          min: 8,
          max: 32,
          divisions: 24,
          label: _length.round().toString(),
          onChanged: (v) {
            setState(() {
              _length = v;
            });
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Uppercase'),
          value: _uppercase,
          onChanged: (v) {
            setState(() {
              _uppercase = v;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Numbers'),
          value: _numbers,
          onChanged: (v) {
            setState(() {
              _numbers = v;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Symbols'),
          value: _symbols,
          onChanged: (v) {
            setState(() {
              _symbols = v;
            });
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _generate,
          child: const Text('Generate'),
        ),
      ],
    );
  }
}

// --- Search Page ---

class SearchPage extends StatefulWidget {
  final List<PasswordEntry> passwords;
  final void Function(int) onDelete;

  const SearchPage({super.key, required this.passwords, required this.onDelete});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<PasswordEntry> _results = [];

  @override
  void initState() {
    super.initState();
    _results = List.from(widget.passwords);
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = List.from(widget.passwords);
      } else {
        _results = widget.passwords
            .where((p) =>
                p.site.toLowerCase().contains(query.toLowerCase()) ||
                p.username.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Passwords'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final entry = _results[index];
                return ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(entry.site),
                  subtitle: Text(entry.username),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
