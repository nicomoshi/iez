import 'package:flutter/material.dart';

void main() {
  runApp(const TimeCapsuleApp());
}

class TimeCapsuleApp extends StatelessWidget {
  const TimeCapsuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeCapsule',
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

// --- Data Models ---

class Capsule {
  final String title;
  final String opensDate;
  final bool isOpened;
  final String? openedDate;
  final int itemCount;
  final String? message;

  const Capsule({
    required this.title,
    required this.opensDate,
    this.isOpened = false,
    this.openedDate,
    this.itemCount = 3,
    this.message,
  });
}

// --- Seed Data ---

final List<Capsule> sealedCapsules = [
  const Capsule(title: 'College Memories', opensDate: 'Dec 2025', itemCount: 5),
  const Capsule(title: 'New Year Goals', opensDate: 'Jan 2026', itemCount: 3),
  const Capsule(title: 'Birthday Letter', opensDate: 'Jul 2025', itemCount: 2),
];

final List<Capsule> openedCapsules = [
  const Capsule(
    title: 'High School Photos',
    opensDate: 'Jan 2024',
    isOpened: true,
    openedDate: 'Jan 2024',
    itemCount: 8,
  ),
  const Capsule(
    title: 'Time Capsule 2020',
    opensDate: 'Mar 2023',
    isOpened: true,
    openedDate: 'Mar 2023',
    itemCount: 4,
  ),
];

// --- Home Page with NavigationBar ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    CapsulesTab(),
    OpenedTab(),
    TimelineTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeCapsule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateCapsulePage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Capsule'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock),
            label: 'Capsules',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_open_outlined),
            selectedIcon: Icon(Icons.lock_open),
            label: 'Opened',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
        ],
      ),
    );
  }
}

// --- Capsules Tab ---

class CapsulesTab extends StatelessWidget {
  const CapsulesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sealedCapsules.length,
      itemBuilder: (context, index) {
        final capsule = sealedCapsules[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.lock, color: Colors.indigo),
            title: Text(capsule.title),
            subtitle: Text('Opens: ${capsule.opensDate}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CapsuleDetailPage(capsule: capsule),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- Opened Tab ---

class OpenedTab extends StatelessWidget {
  const OpenedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Opened',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        ...openedCapsules.map((capsule) => Card(
              child: ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.green),
                title: Text(capsule.title),
                subtitle: Text('Opened: ${capsule.openedDate}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CapsuleDetailPage(capsule: capsule),
                    ),
                  );
                },
              ),
            )),
      ],
    );
  }
}

// --- Timeline Tab ---

class TimelineTab extends StatelessWidget {
  const TimelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Timeline',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '2025',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _timelineEntry(context, 'College Memories', 'Sealed — Opens Dec 2025'),
        _timelineEntry(context, 'New Year Goals', 'Sealed — Opens Jan 2026'),
        _timelineEntry(context, 'Birthday Letter', 'Sealed — Opens Jul 2025'),
        const SizedBox(height: 16),
        Text(
          '2024',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _timelineEntry(context, 'High School Photos', 'Opened — Jan 2024'),
        _timelineEntry(context, 'Time Capsule 2020', 'Opened — Mar 2023'),
      ],
    );
  }

  Widget _timelineEntry(BuildContext context, String title, String subtitle) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.circle, size: 12, color: Colors.indigo),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

// --- Capsule Detail Page ---

class CapsuleDetailPage extends StatelessWidget {
  final Capsule capsule;

  const CapsuleDetailPage({super.key, required this.capsule});

  @override
  Widget build(BuildContext context) {
    final status = capsule.isOpened ? 'Opened' : 'Sealed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capsule Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            capsule.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Divider(height: 32),
          Text(
            'Opens On',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            capsule.opensDate,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Divider(height: 32),
          Text(
            'Items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${capsule.itemCount} items',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Capsule'),
                  content: const Text(
                      'Are you sure you want to delete this capsule?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
            ),
            child: const Text('Delete Capsule'),
          ),
        ],
      ),
    );
  }
}

// --- Create Capsule Page ---

class CreateCapsulePage extends StatefulWidget {
  const CreateCapsulePage({super.key});

  @override
  State<CreateCapsulePage> createState() => _CreateCapsulePageState();
}

class _CreateCapsulePageState extends State<CreateCapsulePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Capsule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Capsule Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a capsule name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Open Date',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Dec 2025',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an open date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Capsule saved!')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Capsule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Capsules'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Capsules',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
