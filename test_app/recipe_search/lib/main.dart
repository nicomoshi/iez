import 'package:flutter/material.dart';

void main() => runApp(const RecipeSearchApp());

class RecipeSearchApp extends StatelessWidget {
  const RecipeSearchApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const RecipeHome(),
    );
  }
}

class Recipe {
  final String name;
  final String cuisine;
  final int cookTime;
  final String difficulty;
  final List<String> ingredients;
  final String instructions;
  bool isFavorite;
  Recipe({
    required this.name,
    required this.cuisine,
    required this.cookTime,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    this.isFavorite = false,
  });
}

final _recipes = [
  Recipe(name: 'Spaghetti Carbonara', cuisine: 'Italian', cookTime: 25, difficulty: 'Easy',
      ingredients: ['Spaghetti', 'Eggs', 'Pancetta', 'Parmesan'],
      instructions: 'Cook pasta. Fry pancetta. Mix eggs and cheese. Combine.'),
  Recipe(name: 'Chicken Tikka Masala', cuisine: 'Indian', cookTime: 45, difficulty: 'Medium',
      ingredients: ['Chicken', 'Yogurt', 'Tomatoes', 'Spices'],
      instructions: 'Marinate chicken. Grill. Simmer in sauce.'),
  Recipe(name: 'Sushi Roll', cuisine: 'Japanese', cookTime: 60, difficulty: 'Hard',
      ingredients: ['Rice', 'Nori', 'Fish', 'Avocado'],
      instructions: 'Prepare rice. Layer ingredients. Roll tightly.'),
  Recipe(name: 'Caesar Salad', cuisine: 'American', cookTime: 15, difficulty: 'Easy',
      ingredients: ['Romaine', 'Croutons', 'Parmesan', 'Caesar Dressing'],
      instructions: 'Chop lettuce. Toss with dressing and toppings.'),
  Recipe(name: 'Pad Thai', cuisine: 'Thai', cookTime: 30, difficulty: 'Medium',
      ingredients: ['Rice Noodles', 'Shrimp', 'Peanuts', 'Bean Sprouts'],
      instructions: 'Soak noodles. Stir-fry with sauce and toppings.'),
  Recipe(name: 'Tacos al Pastor', cuisine: 'Mexican', cookTime: 40, difficulty: 'Medium',
      ingredients: ['Pork', 'Pineapple', 'Tortillas', 'Cilantro'],
      instructions: 'Marinate pork. Grill with pineapple. Serve in tortillas.'),
];

class RecipeHome extends StatefulWidget {
  const RecipeHome({super.key});
  @override
  State<RecipeHome> createState() => _RecipeHomeState();
}

class _RecipeHomeState extends State<RecipeHome> {
  String _searchQuery = '';
  String _cuisineFilter = 'All';

  List<Recipe> get _filtered {
    return _recipes.where((r) {
      final matchSearch = r.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCuisine = _cuisineFilter == 'All' || r.cuisine == _cuisineFilter;
      return matchSearch && matchCuisine;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cuisines = ['All', ...{..._recipes.map((r) => r.cuisine)}..remove('All')];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FavoritesPage(
                  recipes: _recipes.where((r) => r.isFavorite).toList(),
                ))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search recipes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: cuisines.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(c),
                  selected: _cuisineFilter == c,
                  onSelected: (_) => setState(() => _cuisineFilter = c),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No recipes found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final recipe = _filtered[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(recipe.name),
                          subtitle: Text('${recipe.cuisine} · ${recipe.cookTime} min · ${recipe.difficulty}'),
                          trailing: IconButton(
                            icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: recipe.isFavorite ? Colors.red : null),
                            tooltip: recipe.isFavorite ? 'Unfavorite' : 'Favorite',
                            onPressed: () => setState(() => recipe.isFavorite = !recipe.isFavorite),
                          ),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe))),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(recipe.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(label: Text(recipe.cuisine)),
              const SizedBox(width: 8),
              Chip(label: Text('${recipe.cookTime} min')),
              const SizedBox(width: 8),
              Chip(label: Text(recipe.difficulty)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...recipe.ingredients.map((ing) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text('• $ing'),
          )),
          const SizedBox(height: 16),
          const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(recipe.instructions),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final List<Recipe> recipes;
  const FavoritesPage({super.key, required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Recipes')),
      body: recipes.isEmpty
          ? const Center(child: Text('No favorite recipes yet'))
          : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (_, i) {
                final r = recipes[i];
                return ListTile(
                  title: Text(r.name),
                  subtitle: Text('${r.cuisine} · ${r.cookTime} min'),
                );
              },
            ),
    );
  }
}
