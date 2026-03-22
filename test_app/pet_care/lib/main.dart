import 'package:flutter/material.dart';

void main() => runApp(const PetCareApp());

// --- Data Model ---

enum Species { dog, cat, bird, fish, rabbit }

extension SpeciesLabel on Species {
  String get label => name[0].toUpperCase() + name.substring(1);
}

class Pet {
  String name;
  Species species;
  String breed;
  int age;
  double weight;
  DateTime lastVetVisit;
  String notes;

  Pet({
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.weight,
    required this.lastVetVisit,
    this.notes = '',
  });
}

// --- Sample Data ---

List<Pet> _samplePets() => [
      Pet(
        name: 'Buddy',
        species: Species.dog,
        breed: 'Golden Retriever',
        age: 4,
        weight: 30.5,
        lastVetVisit: DateTime(2026, 1, 15),
        notes: 'Loves fetch and swimming.',
      ),
      Pet(
        name: 'Whiskers',
        species: Species.cat,
        breed: 'Siamese',
        age: 3,
        weight: 4.2,
        lastVetVisit: DateTime(2026, 2, 20),
        notes: 'Indoor cat, needs nail trim.',
      ),
      Pet(
        name: 'Kiwi',
        species: Species.bird,
        breed: 'Budgerigar',
        age: 2,
        weight: 0.03,
        lastVetVisit: DateTime(2025, 11, 10),
        notes: 'Talks a lot in the morning.',
      ),
      Pet(
        name: 'Nemo',
        species: Species.fish,
        breed: 'Clownfish',
        age: 1,
        weight: 0.01,
        lastVetVisit: DateTime(2025, 12, 5),
        notes: 'Tank cleaned weekly.',
      ),
      Pet(
        name: 'Thumper',
        species: Species.rabbit,
        breed: 'Holland Lop',
        age: 2,
        weight: 1.8,
        lastVetVisit: DateTime(2026, 3, 1),
        notes: 'Enjoys fresh hay and carrots.',
      ),
      Pet(
        name: 'Max',
        species: Species.dog,
        breed: 'German Shepherd',
        age: 5,
        weight: 34.0,
        lastVetVisit: DateTime(2025, 10, 22),
        notes: 'Training for agility.',
      ),
    ];

// --- App ---

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- HomeScreen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Pet> _pets = _samplePets();
  String _selectedFilter = 'All';

  List<Pet> get _filteredPets {
    if (_selectedFilter == 'All') return _pets;
    return _pets
        .where((p) => p.species.label == _selectedFilter)
        .toList();
  }

  static const _filters = ['All', 'Dog', 'Cat', 'Bird', 'Fish', 'Rabbit'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Vet Schedule') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VetScheduleScreen(pets: _pets),
                  ),
                );
              } else if (value == 'Care Tips') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CareTipsScreen()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Vet Schedule', child: Text('Vet Schedule')),
              PopupMenuItem(value: 'Care Tips', child: Text('Care Tips')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _filters
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f),
                        selected: _selectedFilter == f,
                        onSelected: (_) => setState(() => _selectedFilter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPets.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final pet = _filteredPets[index];
                return Card(
                  child: ListTile(
                    title: Text(pet.name),
                    subtitle: Text(pet.breed),
                    trailing: Text(pet.species.label),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(pet: pet),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newPet = await Navigator.push<Pet>(
            context,
            MaterialPageRoute(builder: (_) => const AddPetScreen()),
          );
          if (newPet != null) {
            setState(() => _pets.add(newPet));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Pet'),
      ),
    );
  }
}

// --- DetailScreen ---

class DetailScreen extends StatefulWidget {
  final Pet pet;
  const DetailScreen({super.key, required this.pet});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pet.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Chip(label: Text(pet.species.label)),
            const SizedBox(height: 12),
            Text('Breed: ${pet.breed}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Age: ${pet.age} years', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Weight: ${pet.weight} kg', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Last Vet Visit: ${_formatDate(pet.lastVetVisit)}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text('Notes: ${pet.notes}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      pet.lastVetVisit = DateTime.now();
                    });
                  },
                  child: const Text('Log Vet Visit'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _showEditNotesDialog(context, pet),
                  child: const Text('Edit Notes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNotesDialog(BuildContext context, Pet pet) {
    final controller = TextEditingController(text: pet.notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => pet.notes = controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// --- AddPetScreen ---

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Species _species = Species.dog;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Pet Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Species>(
              value: _species,
              decoration: const InputDecoration(labelText: 'Species'),
              items: Species.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _species = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _breedCtrl,
              decoration: const InputDecoration(labelText: 'Breed'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageCtrl,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightCtrl,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addPet,
              child: const Text('Add Pet'),
            ),
          ],
        ),
      ),
    );
  }

  void _addPet() {
    final name = _nameCtrl.text.trim();
    final breed = _breedCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final notes = _notesCtrl.text.trim();

    if (name.isEmpty || breed.isEmpty) return;

    Navigator.pop(
      context,
      Pet(
        name: name,
        species: _species,
        breed: breed,
        age: age,
        weight: weight,
        lastVetVisit: DateTime.now(),
        notes: notes,
      ),
    );
  }
}

// --- VetScheduleScreen ---

class VetScheduleScreen extends StatelessWidget {
  final List<Pet> pets;
  const VetScheduleScreen({super.key, required this.pets});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Schedule')),
      body: ListView.builder(
        itemCount: pets.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final pet = pets[index];
          final daysSince = now.difference(pet.lastVetVisit).inDays;
          return Card(
            child: ListTile(
              title: Text(pet.name),
              subtitle: Text(
                'Last visit: ${_formatDate(pet.lastVetVisit)}',
              ),
              trailing: Text('$daysSince days ago'),
            ),
          );
        },
      ),
    );
  }
}

// --- CareTipsScreen ---

class CareTipsScreen extends StatelessWidget {
  const CareTipsScreen({super.key});

  static const _tips = [
    ('Nutrition', 'Feed a balanced diet appropriate for your pet\'s species and age.'),
    ('Exercise', 'Regular exercise keeps your pet healthy and prevents obesity.'),
    ('Grooming', 'Brush your pet regularly and bathe as needed for their coat type.'),
    ('Dental', 'Dental care prevents gum disease — brush teeth or provide dental treats.'),
    ('Socialization', 'Expose pets to new people, animals, and environments early on.'),
    ('Training', 'Consistent positive reinforcement builds good behavior and trust.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Care Tips')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: _tips
            .map(
              (tip) => Card(
                child: ListTile(
                  title: Text(tip.$1),
                  subtitle: Text(tip.$2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// --- Helpers ---

String _formatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
