import 'package:flutter/material.dart';

void main() => runApp(const RecipePlannerApp());

// --- Data Model ---

enum MealType { breakfast, lunch, dinner, snack, dessert }

extension MealTypeExt on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.dinner: return 'Dinner';
      case MealType.snack: return 'Snack';
      case MealType.dessert: return 'Dessert';
    }
  }
}

class Recipe {
  final String id;
  final String name;
  final MealType type;
  final int servings;
  final int prepTime;
  final int cookTime;
  final List<String> ingredients;
  final List<String> steps;
  final String notes;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.type,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.steps,
    this.notes = '',
    this.isFavorite = false,
  });

  int get totalTime => prepTime + cookTime;
}

// --- App State ---

class RecipeStore extends ChangeNotifier {
  final List<Recipe> _recipes = _seedRecipes();

  List<Recipe> get recipes => List.unmodifiable(_recipes);
  List<Recipe> get favorites => _recipes.where((r) => r.isFavorite).toList();

  void add(Recipe r) {
    _recipes.insert(0, r);
    notifyListeners();
  }

  void remove(String id) {
    _recipes.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final r = _recipes.firstWhere((r) => r.id == id);
    r.isFavorite = !r.isFavorite;
    notifyListeners();
  }

  static List<Recipe> _seedRecipes() {
    return [
      Recipe(
        id: '1',
        name: 'Avocado Toast',
        type: MealType.breakfast,
        servings: 2,
        prepTime: 5,
        cookTime: 5,
        ingredients: ['Bread', 'Avocado', 'Lemon', 'Salt', 'Red Pepper Flakes'],
        steps: ['Toast bread', 'Mash avocado with lemon and salt', 'Spread on toast', 'Sprinkle red pepper flakes'],
        notes: 'Add a poached egg for extra protein.',
        isFavorite: true,
      ),
      Recipe(
        id: '2',
        name: 'Caesar Salad',
        type: MealType.lunch,
        servings: 4,
        prepTime: 15,
        cookTime: 0,
        ingredients: ['Romaine Lettuce', 'Parmesan', 'Croutons', 'Caesar Dressing', 'Lemon'],
        steps: ['Wash and chop lettuce', 'Add croutons and parmesan', 'Toss with dressing', 'Squeeze lemon on top'],
        notes: 'Great with grilled chicken.',
      ),
      Recipe(
        id: '3',
        name: 'Pasta Carbonara',
        type: MealType.dinner,
        servings: 3,
        prepTime: 10,
        cookTime: 20,
        ingredients: ['Spaghetti', 'Pancetta', 'Eggs', 'Parmesan', 'Black Pepper'],
        steps: ['Cook pasta al dente', 'Fry pancetta until crisp', 'Mix eggs and parmesan', 'Combine everything off heat', 'Season with pepper'],
        isFavorite: true,
      ),
      Recipe(
        id: '4',
        name: 'Trail Mix',
        type: MealType.snack,
        servings: 6,
        prepTime: 5,
        cookTime: 0,
        ingredients: ['Almonds', 'Cashews', 'Dried Cranberries', 'Dark Chocolate Chips', 'Pumpkin Seeds'],
        steps: ['Combine all ingredients in a bowl', 'Mix well', 'Store in airtight container'],
      ),
      Recipe(
        id: '5',
        name: 'Chocolate Mousse',
        type: MealType.dessert,
        servings: 4,
        prepTime: 20,
        cookTime: 5,
        ingredients: ['Dark Chocolate', 'Heavy Cream', 'Sugar', 'Eggs', 'Vanilla Extract'],
        steps: ['Melt chocolate', 'Whip cream to soft peaks', 'Beat egg whites with sugar', 'Fold chocolate into egg whites', 'Fold in whipped cream', 'Chill for 2 hours'],
        notes: 'Best served cold with fresh berries.',
        isFavorite: true,
      ),
    ];
  }
}

final RecipeStore _globalStore = RecipeStore();

// --- App Root ---

class RecipePlannerApp extends StatelessWidget {
  const RecipePlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: MainScreen(store: _globalStore),
    );
  }
}

// --- Main Screen with Bottom Nav ---

class MainScreen extends StatefulWidget {
  final RecipeStore store;
  const MainScreen({super.key, required this.store});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = [
      RecipeListPage(store: widget.store),
      FavoritesPage(store: widget.store),
      MealPlanPage(store: widget.store),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Recipes'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Meal Plan'),
        ],
      ),
    );
  }
}

// --- Recipe List Page ---

class RecipeListPage extends StatefulWidget {
  final RecipeStore store;
  const RecipeListPage({super.key, required this.store});

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  String _filter = 'All';
  final _filters = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];

  List<Recipe> get _filtered {
    if (_filter == 'All') return widget.store.recipes;
    return widget.store.recipes.where((r) => r.type.label == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Planner'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(store: widget.store)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: recipes.isEmpty
                ? const Center(child: Text('No recipes found.'))
                : ListView.builder(
                    itemCount: recipes.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final r = recipes[index];
                      return Card(
                        child: ListTile(
                          title: Text(r.name),
                          subtitle: Text('${r.type.label} • ${r.totalTime} min'),
                          trailing: IconButton(
                            icon: Icon(r.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: r.isFavorite ? Colors.red : null),
                            onPressed: () => widget.store.toggleFavorite(r.id),
                          ),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: r, store: widget.store))),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AddRecipePage(store: widget.store))),
        label: const Text('Add Recipe'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- Favorites Page ---

class FavoritesPage extends StatelessWidget {
  final RecipeStore store;
  const FavoritesPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final favs = store.favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favs.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.builder(
              itemCount: favs.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final r = favs[index];
                return Card(
                  child: ListTile(
                    title: Text(r.name),
                    subtitle: Text('${r.type.label} • ${r.totalTime} min'),
                    trailing: const Icon(Icons.favorite, color: Colors.red),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: r, store: store))),
                  ),
                );
              },
            ),
    );
  }
}

// --- Meal Plan Page ---

class MealPlanPage extends StatelessWidget {
  final RecipeStore store;
  const MealPlanPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final meals = ['Breakfast', 'Lunch', 'Dinner'];
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plan')),
      body: ListView.builder(
        itemCount: days.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          return Card(
            child: ExpansionTile(
              title: Text(days[index]),
              children: meals.map((meal) => ListTile(
                title: Text(meal),
                trailing: const Icon(Icons.add_circle_outline),
              )).toList(),
            ),
          );
        },
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatefulWidget {
  final RecipeStore store;
  const SearchPage({super.key, required this.store});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  List<Recipe> _results = [];

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = [];
      } else {
        _results = widget.store.recipes
            .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Recipes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Type to search recipes.'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      return ListTile(
                        title: Text(r.name),
                        subtitle: Text(r.type.label),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: r, store: widget.store))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Recipe Detail Page ---

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;
  final RecipeStore store;
  const RecipeDetailPage({super.key, required this.recipe, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recipe.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Row(children: [
              Chip(label: Text(recipe.type.label)),
              const SizedBox(width: 8),
              Chip(label: Text('${recipe.servings} servings')),
            ]),
            const SizedBox(height: 12),
            Text('Prep: ${recipe.prepTime} min • Cook: ${recipe.cookTime} min • Total: ${recipe.totalTime} min'),
            const SizedBox(height: 16),
            Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...recipe.ingredients.map((i) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text('• $i'),
            )),
            const SizedBox(height: 16),
            Text('Steps', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...recipe.steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text('${e.key + 1}. ${e.value}'),
            )),
            if (recipe.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(recipe.notes),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  store.remove(recipe.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Delete Recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Recipe Page ---

class AddRecipePage extends StatefulWidget {
  final RecipeStore store;
  const AddRecipePage({super.key, required this.store});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _servingsCtl = TextEditingController();
  final _prepCtl = TextEditingController();
  final _cookCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  MealType _type = MealType.dinner;

  @override
  void dispose() {
    _nameCtl.dispose();
    _servingsCtl.dispose();
    _prepCtl.dispose();
    _cookCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.add(Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtl.text.trim(),
      type: _type,
      servings: int.tryParse(_servingsCtl.text.trim()) ?? 1,
      prepTime: int.tryParse(_prepCtl.text.trim()) ?? 0,
      cookTime: int.tryParse(_cookCtl.text.trim()) ?? 0,
      ingredients: [],
      steps: [],
      notes: _notesCtl.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Recipe Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MealType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Meal Type'),
                items: MealType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) { if (v != null) setState(() => _type = v); },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _servingsCtl,
                decoration: const InputDecoration(labelText: 'Servings'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prepCtl,
                decoration: const InputDecoration(labelText: 'Prep Time (min)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cookCtl,
                decoration: const InputDecoration(labelText: 'Cook Time (min)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text('Save Recipe')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
