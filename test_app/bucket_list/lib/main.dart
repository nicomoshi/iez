import 'package:flutter/material.dart';

void main() {
  runApp(const BucketListApp());
}

// --- Data Models ---

enum BucketCategory { travel, adventure, learning, personal, creative }

extension BucketCategoryLabel on BucketCategory {
  String get label {
    switch (this) {
      case BucketCategory.travel: return 'Travel';
      case BucketCategory.adventure: return 'Adventure';
      case BucketCategory.learning: return 'Learning';
      case BucketCategory.personal: return 'Personal';
      case BucketCategory.creative: return 'Creative';
    }
  }
}

class BucketItem {
  final String id;
  final String title;
  final BucketCategory category;
  final String notes;
  final bool isCompleted;
  final int priority; // 1=high, 2=medium, 3=low

  BucketItem({
    required this.id,
    required this.title,
    required this.category,
    this.notes = '',
    this.isCompleted = false,
    this.priority = 2,
  });

  BucketItem copyWith({bool? isCompleted}) => BucketItem(
    id: id, title: title, category: category, notes: notes,
    isCompleted: isCompleted ?? this.isCompleted, priority: priority,
  );

  String get priorityLabel {
    switch (priority) {
      case 1: return 'High';
      case 2: return 'Medium';
      default: return 'Low';
    }
  }
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<BucketItem> _items = [
    BucketItem(id: '1', title: 'Visit the Northern Lights', category: BucketCategory.travel, priority: 1, notes: 'Best seen in Iceland or Norway'),
    BucketItem(id: '2', title: 'Learn to Play Guitar', category: BucketCategory.learning, priority: 2, notes: 'Start with acoustic'),
    BucketItem(id: '3', title: 'Skydiving', category: BucketCategory.adventure, priority: 1, notes: 'Tandem jump first'),
    BucketItem(id: '4', title: 'Write a Novel', category: BucketCategory.creative, priority: 3, notes: 'NaNoWriMo challenge'),
    BucketItem(id: '5', title: 'Run a Marathon', category: BucketCategory.personal, priority: 2, notes: 'Train for 6 months'),
    BucketItem(id: '6', title: 'Visit Machu Picchu', category: BucketCategory.travel, priority: 2, notes: 'Inca Trail trek'),
    BucketItem(id: '7', title: 'Learn Japanese', category: BucketCategory.learning, priority: 3, notes: 'For travel to Japan'),
    BucketItem(id: '8', title: 'Go Scuba Diving', category: BucketCategory.adventure, priority: 2, notes: 'Great Barrier Reef'),
  ];

  List<BucketItem> get items => List.unmodifiable(_items);
  int get completedCount => _items.where((i) => i.isCompleted).length;
  int get pendingCount => _items.where((i) => !i.isCompleted).length;
  int get totalCount => _items.length;

  List<BucketItem> itemsByCategory(BucketCategory cat) =>
      _items.where((i) => i.category == cat).toList();

  void toggleItem(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(isCompleted: !_items[idx].isCompleted);
      notifyListeners();
    }
  }

  void addItem(BucketItem item) {
    _items.add(item);
    notifyListeners();
  }

  void deleteItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}

// --- App ---

class BucketListApp extends StatefulWidget {
  const BucketListApp({super.key});

  @override
  State<BucketListApp> createState() => _BucketListAppState();
}

class _BucketListAppState extends State<BucketListApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bucket List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: MainScreen(state: _state),
    );
  }
}

class MainScreen extends StatefulWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AllItemsPage(state: widget.state),
      CategoriesPage(state: widget.state),
      StatsPage(state: widget.state),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'All'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

// --- All Items Page ---

class AllItemsPage extends StatelessWidget {
  final AppState state;
  const AllItemsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bucket List'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('${state.completedCount}/${state.totalCount}', style: Theme.of(context).textTheme.bodyMedium)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Checkbox(
                value: item.isCompleted,
                onChanged: (_) => state.toggleItem(item.id),
              ),
              title: Text(item.title, style: TextStyle(decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
              subtitle: Text('${item.category.label} · ${item.priorityLabel}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailPage(state: state, item: item))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    BucketCategory category = BucketCategory.personal;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Goal Title')),
              const SizedBox(height: 12),
              DropdownButtonFormField<BucketCategory>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: BucketCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                onChanged: (v) => category = v ?? category,
              ),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                state.addItem(BucketItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  category: category,
                  notes: notesController.text,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// --- Item Detail Page ---

class ItemDetailPage extends StatelessWidget {
  final AppState state;
  final BucketItem item;
  const ItemDetailPage({super.key, required this.state, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Goal'),
                  content: Text('Delete "${item.title}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    FilledButton(onPressed: () { state.deleteItem(item.id); Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Delete')),
                  ],
                ),
              );
            },
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Row(children: [
                    Chip(label: Text(item.category.label)),
                    const SizedBox(width: 8),
                    Chip(label: Text(item.priorityLabel)),
                    const SizedBox(width: 8),
                    Chip(label: Text(item.isCompleted ? 'Completed' : 'Pending')),
                  ]),
                ],
              ),
            ),
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(item.notes),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Categories Page ---

class CategoriesPage extends StatelessWidget {
  final AppState state;
  const CategoriesPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: BucketCategory.values.map((cat) {
          final items = state.itemsByCategory(cat);
          final completed = items.where((i) => i.isCompleted).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(cat.label),
              subtitle: Text('$completed/${items.length} completed'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryDetailPage(state: state, category: cat))),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- Category Detail Page ---

class CategoryDetailPage extends StatelessWidget {
  final AppState state;
  final BucketCategory category;
  const CategoryDetailPage({super.key, required this.state, required this.category});

  @override
  Widget build(BuildContext context) {
    final items = state.itemsByCategory(category);
    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: items.isEmpty
          ? const Center(child: Text('No goals in this category'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return CheckboxListTile(
                  value: item.isCompleted,
                  onChanged: (_) => state.toggleItem(item.id),
                  title: Text(item.title),
                  subtitle: Text(item.priorityLabel),
                );
              },
            ),
    );
  }
}

// --- Stats Page ---

class StatsPage extends StatelessWidget {
  final AppState state;
  const StatsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Overall Progress', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Text('${state.completedCount} of ${state.totalCount} goals completed'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: state.totalCount == 0 ? 0 : state.completedCount / state.totalCount),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [Text('${state.totalCount}', style: Theme.of(context).textTheme.headlineMedium), const Text('Total')]),
                      Column(children: [Text('${state.completedCount}', style: Theme.of(context).textTheme.headlineMedium), const Text('Done')]),
                      Column(children: [Text('${state.pendingCount}', style: Theme.of(context).textTheme.headlineMedium), const Text('Pending')]),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('By Category', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...BucketCategory.values.map((cat) {
            final items = state.itemsByCategory(cat);
            final completed = items.where((i) => i.isCompleted).length;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(cat.label),
                trailing: Text('$completed/${items.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
