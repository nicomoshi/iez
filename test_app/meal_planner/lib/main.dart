import 'package:flutter/material.dart';

void main() => runApp(const MealPlannerApp());

class MealPlannerApp extends StatelessWidget {
  const MealPlannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meal Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const MealPlannerHome(),
    );
  }
}

class Meal {
  final String name;
  final String category; // Breakfast, Lunch, Dinner, Snack
  final String day; // Mon, Tue, Wed, Thu, Fri, Sat, Sun
  bool isFavorite;
  Meal({required this.name, required this.category, required this.day, this.isFavorite = false});
}

class MealPlannerHome extends StatefulWidget {
  const MealPlannerHome({super.key});
  @override
  State<MealPlannerHome> createState() => _MealPlannerHomeState();
}

class _MealPlannerHomeState extends State<MealPlannerHome> {
  String _selectedDay = 'Mon';
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<Meal> _meals = [
    Meal(name: 'Oatmeal with Berries', category: 'Breakfast', day: 'Mon'),
    Meal(name: 'Grilled Chicken Salad', category: 'Lunch', day: 'Mon'),
    Meal(name: 'Pasta Carbonara', category: 'Dinner', day: 'Mon'),
    Meal(name: 'Greek Yogurt', category: 'Snack', day: 'Mon'),
    Meal(name: 'Scrambled Eggs', category: 'Breakfast', day: 'Tue'),
    Meal(name: 'Turkey Sandwich', category: 'Lunch', day: 'Tue'),
    Meal(name: 'Stir Fry Vegetables', category: 'Dinner', day: 'Tue'),
  ];

  List<Meal> get _filteredMeals => _meals.where((m) => m.day == _selectedDay).toList();

  void _addMeal(String name, String category) {
    setState(() => _meals.add(Meal(name: name, category: category, day: _selectedDay)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FavoritesPage(meals: _meals.where((m) => m.isFavorite).toList()))),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Shopping List',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ShoppingListPage(meals: _meals))),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _days.map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(d),
                  selected: _selectedDay == d,
                  onSelected: (_) => setState(() => _selectedDay = d),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _filteredMeals.isEmpty
                ? const Center(child: Text('No meals planned'))
                : ListView.builder(
                    itemCount: _filteredMeals.length,
                    itemBuilder: (_, i) {
                      final meal = _filteredMeals[i];
                      return ListTile(
                        leading: Icon(_categoryIcon(meal.category)),
                        title: Text(meal.name),
                        subtitle: Text(meal.category),
                        trailing: IconButton(
                          icon: Icon(meal.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: meal.isFavorite ? Colors.red : null),
                          tooltip: meal.isFavorite ? 'Unfavorite' : 'Favorite',
                          onPressed: () => setState(() => meal.isFavorite = !meal.isFavorite),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Meal',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddMealPage()));
          if (result != null) _addMeal(result['name']!, result['category']!);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Breakfast': return Icons.wb_sunny;
      case 'Lunch': return Icons.restaurant;
      case 'Dinner': return Icons.dinner_dining;
      case 'Snack': return Icons.cookie;
      default: return Icons.food_bank;
    }
  }
}

class AddMealPage extends StatefulWidget {
  const AddMealPage({super.key});
  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final _nameCtrl = TextEditingController();
  String _category = 'Breakfast';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Meal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Meal name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {'name': _nameCtrl.text, 'category': _category});
                  }
                },
                child: const Text('Save Meal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final List<Meal> meals;
  const FavoritesPage({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Meals')),
      body: meals.isEmpty
          ? const Center(child: Text('No favorite meals yet'))
          : ListView.builder(
              itemCount: meals.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(meals[i].name),
                subtitle: Text('${meals[i].category} — ${meals[i].day}'),
              ),
            ),
    );
  }
}

class ShoppingListPage extends StatelessWidget {
  final List<Meal> meals;
  const ShoppingListPage({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    final items = meals.map((m) => m.name).toSet().toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: items.isEmpty
          ? const Center(child: Text('No items'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => CheckboxListTile(
                title: Text(items[i]),
                value: false,
                onChanged: (_) {},
              ),
            ),
    );
  }
}
