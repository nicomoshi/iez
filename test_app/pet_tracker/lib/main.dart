import 'package:flutter/material.dart';

void main() => runApp(const PetTrackerApp());

// --- Data Models ---

class Pet {
  String name;
  String species;
  String breed;
  int age;
  double weight;
  String microchipId;
  String nextVetVisit;
  List<Vaccine> vaccines;
  List<Feeding> feedings;

  Pet({
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.weight,
    required this.microchipId,
    required this.nextVetVisit,
    required this.vaccines,
    required this.feedings,
  });
}

class Vaccine {
  final String name;
  final String date;
  final String nextDue;
  Vaccine({required this.name, required this.date, required this.nextDue});
}

class Feeding {
  final String time;
  final String foodType;
  final String amount;
  Feeding({required this.time, required this.foodType, required this.amount});
}

class Vet {
  final String name;
  final String phone;
  final String specialty;
  Vet({required this.name, required this.phone, required this.specialty});
}

// --- Global State ---

final List<Pet> pets = [
  Pet(
    name: 'Max',
    species: 'Dog',
    breed: 'Golden Retriever',
    age: 3,
    weight: 70,
    microchipId: 'MC-001-DOG',
    nextVetVisit: 'Apr 15',
    vaccines: [
      Vaccine(name: 'Rabies', date: 'Jan 2026', nextDue: 'Jan 2027'),
      Vaccine(name: 'DHPP', date: 'Mar 2026', nextDue: 'Mar 2027'),
    ],
    feedings: [
      Feeding(time: '7:00 AM', foodType: 'Kibble', amount: '2 cups'),
      Feeding(time: '5:00 PM', foodType: 'Kibble', amount: '2 cups'),
    ],
  ),
  Pet(
    name: 'Luna',
    species: 'Cat',
    breed: 'Siamese',
    age: 2,
    weight: 9,
    microchipId: 'MC-002-CAT',
    nextVetVisit: 'May 1',
    vaccines: [
      Vaccine(name: 'FVRCP', date: 'Feb 2026', nextDue: 'Feb 2027'),
      Vaccine(name: 'Rabies', date: 'Feb 2026', nextDue: 'Feb 2027'),
    ],
    feedings: [
      Feeding(time: '8:00 AM', foodType: 'Wet Food', amount: '1 can'),
      Feeding(time: '6:00 PM', foodType: 'Dry Food', amount: '1/2 cup'),
    ],
  ),
  Pet(
    name: 'Buddy',
    species: 'Dog',
    breed: 'Labrador',
    age: 5,
    weight: 80,
    microchipId: 'MC-003-DOG',
    nextVetVisit: 'Jun 10',
    vaccines: [
      Vaccine(name: 'Rabies', date: 'Dec 2025', nextDue: 'Dec 2026'),
      Vaccine(name: 'Bordetella', date: 'Nov 2025', nextDue: 'Nov 2026'),
    ],
    feedings: [
      Feeding(time: '7:30 AM', foodType: 'Kibble', amount: '3 cups'),
      Feeding(time: '5:30 PM', foodType: 'Kibble', amount: '2 cups'),
    ],
  ),
];

final List<Vet> vets = [
  Vet(name: 'Dr. Sarah Wilson', phone: '555-0101', specialty: 'General Practice'),
  Vet(name: 'Dr. James Park', phone: '555-0102', specialty: 'Surgery'),
  Vet(name: 'Dr. Emily Brown', phone: '555-0103', specialty: 'Dentistry'),
];

// --- App ---

class PetTrackerApp extends StatelessWidget {
  const PetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Tracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'vet_directory') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VetDirectoryScreen()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'vet_directory',
                child: Text('Vet Directory'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditPetScreen()),
          );
          setState(() {});
        },
        child: const Text('Add Pet'),
      ),
      body: ListView.builder(
        itemCount: pets.length,
        itemBuilder: (context, index) {
          final pet = pets[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(pet.name),
              subtitle: Text(
                  '${pet.species} - ${pet.breed}\nAge: ${pet.age} years | Next vet: ${pet.nextVetVisit}'),
              isThreeLine: true,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PetDetailScreen(pet: pet)),
                );
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}

// --- Pet Detail Screen ---

class PetDetailScreen extends StatelessWidget {
  final Pet pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Species: ${pet.species}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Breed: ${pet.breed}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Age: ${pet.age} years', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Weight: ${pet.weight.toStringAsFixed(0)} lbs',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Microchip ID: ${pet.microchipId}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VaccinationsScreen(pet: pet)),
                  ),
                  child: const Text('Vaccinations'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FeedingScheduleScreen(pet: pet)),
                  ),
                  child: const Text('Feeding Schedule'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddEditPetScreen(pet: pet)),
              ),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Vaccinations Screen ---

class VaccinationsScreen extends StatelessWidget {
  final Pet pet;
  const VaccinationsScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccinations')),
      body: ListView.builder(
        itemCount: pet.vaccines.length,
        itemBuilder: (context, index) {
          final v = pet.vaccines[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(v.name),
              subtitle: Text('Date: ${v.date}\nNext due: ${v.nextDue}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

// --- Feeding Schedule Screen ---

class FeedingScheduleScreen extends StatelessWidget {
  final Pet pet;
  const FeedingScheduleScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feeding Schedule')),
      body: ListView.builder(
        itemCount: pet.feedings.length,
        itemBuilder: (context, index) {
          final f = pet.feedings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(f.time),
              subtitle: Text('${f.foodType} - ${f.amount}'),
            ),
          );
        },
      ),
    );
  }
}

// --- Add/Edit Pet Screen ---

class AddEditPetScreen extends StatefulWidget {
  final Pet? pet;
  const AddEditPetScreen({super.key, this.pet});

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _microchipCtrl;
  String _species = 'Dog';

  final _speciesOptions = ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit'];

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _breedCtrl = TextEditingController(text: p?.breed ?? '');
    _ageCtrl = TextEditingController(text: p != null ? '${p.age}' : '');
    _weightCtrl =
        TextEditingController(text: p != null ? p.weight.toStringAsFixed(0) : '');
    _microchipCtrl = TextEditingController(text: p?.microchipId ?? '');
    if (p != null) _species = p.species;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _microchipCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (widget.pet != null) {
      final p = widget.pet!;
      p.name = name;
      p.species = _species;
      p.breed = _breedCtrl.text.trim();
      p.age = int.tryParse(_ageCtrl.text) ?? 0;
      p.weight = double.tryParse(_weightCtrl.text) ?? 0;
      p.microchipId = _microchipCtrl.text.trim();
    } else {
      pets.add(Pet(
        name: name,
        species: _species,
        breed: _breedCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 0,
        weight: double.tryParse(_weightCtrl.text) ?? 0,
        microchipId: _microchipCtrl.text.trim(),
        nextVetVisit: 'TBD',
        vaccines: [],
        feedings: [],
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.pet != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Pet' : 'Add Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _species,
              decoration: const InputDecoration(labelText: 'Species'),
              items: _speciesOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _species = v!),
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
              decoration: const InputDecoration(labelText: 'Weight'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _microchipCtrl,
              decoration: const InputDecoration(labelText: 'Microchip ID'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Pet'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Vet Directory Screen ---

class VetDirectoryScreen extends StatelessWidget {
  const VetDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vet Directory')),
      body: ListView.builder(
        itemCount: vets.length,
        itemBuilder: (context, index) {
          final v = vets[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(v.name),
              subtitle: Text('${v.phone} - ${v.specialty}'),
            ),
          );
        },
      ),
    );
  }
}
