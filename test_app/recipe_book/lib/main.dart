import 'package:flutter/material.dart';

void main() {
  runApp(const RecipeBookApp());
}

// ── Data model ──────────────────────────────────────────────────────────────

class Recipe {
  final int id;
  final String name;
  final String category;
  final String cookTime;
  final List<String> ingredients;
  final String instructions;

  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.cookTime,
    required this.ingredients,
    required this.instructions,
  });
}

final List<Recipe> kRecipes = [
  Recipe(
    id: 1,
    name: 'Spaghetti Carbonara',
    category: 'Italian',
    cookTime: '30 min',
    ingredients: [
      '400g spaghetti',
      '200g pancetta',
      '4 large eggs',
      '100g Pecorino Romano',
      '100g Parmesan',
      'Black pepper',
      'Salt',
    ],
    instructions:
        'Boil pasta in salted water until al dente. Fry pancetta until crispy. '
        'Mix eggs and cheese in a bowl. Drain pasta, combine with pancetta, '
        'remove from heat, add egg mixture and toss quickly. Season with pepper.',
  ),
  Recipe(
    id: 2,
    name: 'Chicken Tacos',
    category: 'Mexican',
    cookTime: '25 min',
    ingredients: [
      '500g chicken breast',
      '8 small corn tortillas',
      '1 avocado',
      '1 lime',
      'Salsa',
      'Cilantro',
      'Cumin',
      'Chili powder',
      'Garlic powder',
    ],
    instructions:
        'Season chicken with cumin, chili powder, and garlic powder. Grill or '
        'pan-fry for 6-7 minutes per side. Slice thinly. Warm tortillas. '
        'Assemble tacos with chicken, avocado, salsa, and cilantro. Squeeze lime on top.',
  ),
  Recipe(
    id: 3,
    name: 'Vegetable Stir Fry',
    category: 'Asian',
    cookTime: '20 min',
    ingredients: [
      '2 cups broccoli florets',
      '1 red bell pepper',
      '1 carrot',
      '200g snap peas',
      '3 tbsp soy sauce',
      '1 tbsp sesame oil',
      '2 cloves garlic',
      '1 tsp ginger',
      'Cooked rice',
    ],
    instructions:
        'Heat sesame oil in a wok over high heat. Add garlic and ginger, stir '
        'for 30 seconds. Add carrots and broccoli, stir-fry 3 minutes. Add '
        'bell pepper and snap peas, cook 2 more minutes. Add soy sauce and toss. Serve over rice.',
  ),
  Recipe(
    id: 4,
    name: 'Classic Beef Burger',
    category: 'American',
    cookTime: '15 min',
    ingredients: [
      '500g ground beef (80/20)',
      '4 burger buns',
      '4 slices cheddar cheese',
      'Lettuce',
      'Tomato',
      'Onion',
      'Pickles',
      'Ketchup',
      'Mustard',
      'Salt and pepper',
    ],
    instructions:
        'Form beef into 4 patties, season with salt and pepper. Grill over '
        'high heat 3-4 minutes per side. Add cheese in last minute. Toast buns. '
        'Assemble with toppings and condiments of choice.',
  ),
  Recipe(
    id: 5,
    name: 'Margherita Pizza',
    category: 'Italian',
    cookTime: '45 min',
    ingredients: [
      '250g pizza dough',
      '150ml tomato sauce',
      '200g fresh mozzarella',
      'Fresh basil leaves',
      '2 tbsp olive oil',
      'Salt',
    ],
    instructions:
        'Preheat oven to 250C. Roll out dough on a floured surface. Spread '
        'tomato sauce, leaving a border. Tear mozzarella and distribute. Drizzle '
        'with olive oil and season with salt. Bake 10-12 minutes until crust is golden. Top with fresh basil.',
  ),
  Recipe(
    id: 6,
    name: 'Greek Salad',
    category: 'Mediterranean',
    cookTime: '10 min',
    ingredients: [
      '3 large tomatoes',
      '1 cucumber',
      '1 red onion',
      '200g feta cheese',
      '100g Kalamata olives',
      '3 tbsp olive oil',
      '1 tbsp red wine vinegar',
      'Dried oregano',
      'Salt',
    ],
    instructions:
        'Chop tomatoes, cucumber, and red onion into chunks. Place in a large '
        'bowl. Add olives and crumble feta on top. Drizzle with olive oil and '
        'vinegar. Sprinkle oregano and salt. Toss gently and serve immediately.',
  ),
  Recipe(
    id: 7,
    name: 'Chicken Curry',
    category: 'Indian',
    cookTime: '40 min',
    ingredients: [
      '600g chicken thighs',
      '400ml coconut milk',
      '1 onion',
      '3 cloves garlic',
      '1 tbsp ginger',
      '2 tbsp curry powder',
      '1 tsp turmeric',
      '400g canned tomatoes',
      'Cooked basmati rice',
      'Fresh cilantro',
    ],
    instructions:
        'Saute onion in oil until soft. Add garlic, ginger, curry powder, and '
        'turmeric, cook 1 minute. Add chicken pieces and brown on all sides. '
        'Add tomatoes and coconut milk, simmer 25 minutes until chicken is cooked. '
        'Garnish with cilantro and serve with rice.',
  ),
];

// ── App state ────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  bool _darkMode = false;
  String _measurementUnit = 'Metric';
  double _servings = 4;
  final Set<int> _favoriteIds = {};

  bool get darkMode => _darkMode;
  String get measurementUnit => _measurementUnit;
  double get servings => _servings;
  Set<int> get favoriteIds => _favoriteIds;

  void toggleDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }

  void setMeasurementUnit(String unit) {
    _measurementUnit = unit;
    notifyListeners();
  }

  void setServings(double value) {
    _servings = value;
    notifyListeners();
  }

  bool isFavorite(int id) => _favoriteIds.contains(id);

  void toggleFavorite(int id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  List<Recipe> get favoriteRecipes =>
      kRecipes.where((r) => _favoriteIds.contains(r.id)).toList();
}

// ── Root app ─────────────────────────────────────────────────────────────────

class RecipeBookApp extends StatefulWidget {
  const RecipeBookApp({super.key});

  @override
  State<RecipeBookApp> createState() => _RecipeBookAppState();
}

class _RecipeBookAppState extends State<RecipeBookApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Recipe Book',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepOrange,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
          themeMode:
              _appState.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainShell(appState: _appState),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// ── Main shell with bottom navigation ────────────────────────────────────────

class MainShell extends StatefulWidget {
  final AppState appState;
  const MainShell({super.key, required this.appState});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      RecipesTab(appState: widget.appState),
      FavoritesTab(appState: widget.appState),
      SettingsTab(appState: widget.appState),
    ];

    return Scaffold(
      body: tabs[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ── Recipes tab ───────────────────────────────────────────────────────────────

class RecipesTab extends StatefulWidget {
  final AppState appState;
  const RecipesTab({super.key, required this.appState});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> get _filtered {
    if (_query.isEmpty) return kRecipes;
    final q = _query.toLowerCase();
    return kRecipes
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Book'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No recipes found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final recipe = _filtered[index];
                      return ListenableBuilder(
                        listenable: widget.appState,
                        builder: (context, _) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(recipe.name[0]),
                            ),
                            title: Text(recipe.name),
                            subtitle: Text(
                                '${recipe.category} · ${recipe.cookTime}'),
                            trailing: Icon(
                              widget.appState.isFavorite(recipe.id)
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: widget.appState.isFavorite(recipe.id)
                                  ? Colors.red
                                  : null,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                    recipe: recipe,
                                    appState: widget.appState,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Favorites tab ─────────────────────────────────────────────────────────────

class FavoritesTab extends StatelessWidget {
  final AppState appState;
  const FavoritesTab({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final favorites = appState.favoriteRecipes;
          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart on a recipe to save it here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final recipe = favorites[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(recipe.name[0]),
                ),
                title: Text(recipe.name),
                subtitle:
                    Text('${recipe.category} · ${recipe.cookTime}'),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => appState.toggleFavorite(recipe.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(
                        recipe: recipe,
                        appState: appState,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ── Settings tab ──────────────────────────────────────────────────────────────

class SettingsTab extends StatelessWidget {
  final AppState appState;
  const SettingsTab({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: appState.darkMode,
                onChanged: appState.toggleDarkMode,
              ),
              ListTile(
                title: const Text('Measurement Unit'),
                subtitle: Text(appState.measurementUnit),
                trailing: DropdownButton<String>(
                  value: appState.measurementUnit,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'Metric', child: Text('Metric')),
                    DropdownMenuItem(
                        value: 'Imperial', child: Text('Imperial')),
                  ],
                  onChanged: (value) {
                    if (value != null) appState.setMeasurementUnit(value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Default Servings'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${appState.servings.round()} servings'),
                    Slider(
                      value: appState.servings,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: appState.servings.round().toString(),
                      onChanged: appState.setServings,
                    ),
                  ],
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const ListTile(
                title: Text('App Version'),
                trailing: Text('1.0.0'),
              ),
              const ListTile(
                title: Text('Recipe Book'),
                subtitle: Text('A simple app to manage your favorite recipes.'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Recipe Detail screen ──────────────────────────────────────────────────────

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final AppState appState;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isFav = appState.isFavorite(recipe.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(recipe.name),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_outline,
                  color: isFav ? Colors.red : null,
                ),
                tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => appState.toggleFavorite(recipe.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header chips
                Row(
                  children: [
                    Chip(label: Text(recipe.category)),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: Text(recipe.cookTime),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Ingredients section
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...recipe.ingredients.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(ingredient)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Instructions section
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  recipe.instructions,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
