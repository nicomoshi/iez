import 'package:flutter/material.dart';

void main() {
  runApp(const GiftTrackerApp());
}

class GiftTrackerApp extends StatelessWidget {
  const GiftTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gift Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class GiftIdea {
  final String name;
  final int minPrice;
  final int maxPrice;
  final String recipient;
  final String status;

  const GiftIdea({
    required this.name,
    required this.minPrice,
    required this.maxPrice,
    required this.recipient,
    this.status = 'Pending',
  });
}

class Person {
  final String name;
  final String birthday;

  const Person({required this.name, required this.birthday});
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<GiftIdea> _ideas = [
    const GiftIdea(name: 'Wireless Earbuds', minPrice: 30, maxPrice: 50, recipient: 'Mom'),
    const GiftIdea(name: 'Book Set', minPrice: 20, maxPrice: 40, recipient: 'Dad'),
    const GiftIdea(name: 'Scented Candle', minPrice: 15, maxPrice: 25, recipient: 'Sister'),
    const GiftIdea(name: 'Gift Card', minPrice: 25, maxPrice: 100, recipient: 'Best Friend'),
    const GiftIdea(name: 'Board Game', minPrice: 20, maxPrice: 35, recipient: 'Mom'),
  ];

  final List<Person> _people = const [
    Person(name: 'Mom', birthday: 'May 10'),
    Person(name: 'Dad', birthday: 'Aug 22'),
    Person(name: 'Sister', birthday: 'Nov 3'),
    Person(name: 'Best Friend', birthday: 'Apr 15'),
  ];

  void _addIdea(GiftIdea idea) {
    setState(() {
      _ideas.add(idea);
    });
  }

  void _deleteIdea(GiftIdea idea) {
    setState(() {
      _ideas.remove(idea);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      IdeasTab(
        ideas: _ideas,
        people: _people,
        onAdd: _addIdea,
        onDelete: _deleteIdea,
      ),
      PeopleTab(people: _people),
      const BudgetTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(ideas: _ideas),
                ),
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.lightbulb_outline), label: 'Ideas'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'People'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Budget'),
        ],
      ),
    );
  }
}

// ─── Ideas Tab ───

class IdeasTab extends StatelessWidget {
  final List<GiftIdea> ideas;
  final List<Person> people;
  final void Function(GiftIdea) onAdd;
  final void Function(GiftIdea) onDelete;

  const IdeasTab({
    super.key,
    required this.ideas,
    required this.people,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: ideas.length,
        itemBuilder: (context, index) {
          final idea = ideas[index];
          return ListTile(
            title: Text(idea.name),
            subtitle: Text('\$${idea.minPrice}-\$${idea.maxPrice}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IdeaDetailPage(idea: idea, onDelete: onDelete),
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
              builder: (_) => AddIdeaPage(people: people, onSave: onAdd),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Idea'),
      ),
    );
  }
}

// ─── Idea Detail Page ───

class IdeaDetailPage extends StatelessWidget {
  final GiftIdea idea;
  final void Function(GiftIdea) onDelete;

  const IdeaDetailPage({super.key, required this.idea, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gift Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idea.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('\$${idea.minPrice} - \$${idea.maxPrice}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('For', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(idea.recipient, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(idea.status, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onDelete(idea);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Idea'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── People Tab ───

class PeopleTab extends StatelessWidget {
  final List<Person> people;

  const PeopleTab({super.key, required this.people});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('People', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(person.name),
                  subtitle: Text('Birthday: ${person.birthday}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Budget Tab ───

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          _BudgetCard(label: 'Total Budget', amount: '\$500', color: Colors.deepPurple),
          const SizedBox(height: 12),
          _BudgetCard(label: 'Spent', amount: '\$180', color: Colors.red),
          const SizedBox(height: 12),
          _BudgetCard(label: 'Remaining', amount: '\$320', color: Colors.green),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _BudgetCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(
              amount,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Idea Page ───

class AddIdeaPage extends StatefulWidget {
  final List<Person> people;
  final void Function(GiftIdea) onSave;

  const AddIdeaPage({super.key, required this.people, required this.onSave});

  @override
  State<AddIdeaPage> createState() => _AddIdeaPageState();
}

class _AddIdeaPageState extends State<AddIdeaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _selectedRecipient;

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Idea')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Gift Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minPriceController,
                decoration: const InputDecoration(
                  labelText: 'Min Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxPriceController,
                decoration: const InputDecoration(
                  labelText: 'Max Price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRecipient,
                decoration: const InputDecoration(
                  labelText: 'Recipient',
                  border: OutlineInputBorder(),
                ),
                items: widget.people
                    .map((p) => DropdownMenuItem(value: p.name, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRecipient = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave(GiftIdea(
                        name: _nameController.text,
                        minPrice: int.tryParse(_minPriceController.text) ?? 0,
                        maxPrice: int.tryParse(_maxPriceController.text) ?? 0,
                        recipient: _selectedRecipient!,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Idea'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Page ───

class SearchPage extends StatefulWidget {
  final List<GiftIdea> ideas;

  const SearchPage({super.key, required this.ideas});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Under \$25', 'Under \$50', 'Over \$50'];

  List<GiftIdea> get _filteredIdeas {
    var results = widget.ideas;

    // Apply text search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      results = results.where((i) => i.name.toLowerCase().contains(query)).toList();
    }

    // Apply price filter
    switch (_selectedFilter) {
      case 'Under \$25':
        results = results.where((i) => i.maxPrice < 25).toList();
        break;
      case 'Under \$50':
        results = results.where((i) => i.maxPrice < 50).toList();
        break;
      case 'Over \$50':
        results = results.where((i) => i.minPrice > 50).toList();
        break;
    }

    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Gifts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search gifts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _filters.map((filter) {
                return FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (_) {
                    setState(() => _selectedFilter = filter);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredIdeas.length,
                itemBuilder: (context, index) {
                  final idea = _filteredIdeas[index];
                  return ListTile(
                    title: Text(idea.name),
                    subtitle: Text('\$${idea.minPrice}-\$${idea.maxPrice}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
