import 'package:flutter/material.dart';

void main() {
  runApp(const PetAdoptApp());
}

// --- Data Models ---

enum PetType { dog, cat, rabbit, bird }

extension PetTypeLabel on PetType {
  String get label {
    switch (this) {
      case PetType.dog: return 'Dog';
      case PetType.cat: return 'Cat';
      case PetType.rabbit: return 'Rabbit';
      case PetType.bird: return 'Bird';
    }
  }

  IconData get icon {
    switch (this) {
      case PetType.dog: return Icons.pets;
      case PetType.cat: return Icons.pets;
      case PetType.rabbit: return Icons.cruelty_free;
      case PetType.bird: return Icons.flutter_dash;
    }
  }
}

class Pet {
  final String id;
  final String name;
  final PetType type;
  final String breed;
  final int age;
  final String gender;
  final String description;
  final String shelter;
  final bool isVaccinated;
  final bool isNeutered;
  bool isFavorite;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.gender,
    required this.description,
    required this.shelter,
    this.isVaccinated = true,
    this.isNeutered = false,
    this.isFavorite = false,
  });

  String get ageText => age < 12 ? '$age months' : '${age ~/ 12} years';
}

// --- App State ---

class AppState extends ChangeNotifier {
  final List<Pet> _pets = [
    Pet(id: '1', name: 'Buddy', type: PetType.dog, breed: 'Golden Retriever', age: 36, gender: 'Male', description: 'Friendly and playful. Great with kids and other dogs. Loves fetch and long walks.', shelter: 'Happy Paws Shelter', isVaccinated: true, isNeutered: true),
    Pet(id: '2', name: 'Luna', type: PetType.cat, breed: 'Siamese', age: 24, gender: 'Female', description: 'Elegant and vocal. Enjoys curling up in warm spots and playing with feather toys.', shelter: 'City Cat Rescue', isVaccinated: true, isNeutered: true),
    Pet(id: '3', name: 'Max', type: PetType.dog, breed: 'German Shepherd', age: 18, gender: 'Male', description: 'Intelligent and loyal. Needs an active family with a yard. Well-trained.', shelter: 'Happy Paws Shelter', isVaccinated: true, isNeutered: false),
    Pet(id: '4', name: 'Coco', type: PetType.rabbit, breed: 'Holland Lop', age: 8, gender: 'Female', description: 'Gentle and curious. Loves to be held and enjoys exploring. Litter trained.', shelter: 'Small Friends Rescue', isVaccinated: true),
    Pet(id: '5', name: 'Kiwi', type: PetType.bird, breed: 'Cockatiel', age: 12, gender: 'Male', description: 'Cheerful whistler. Can mimic tunes and enjoys head scratches.', shelter: 'Wings of Hope', isVaccinated: true),
    Pet(id: '6', name: 'Bella', type: PetType.cat, breed: 'Maine Coon', age: 48, gender: 'Female', description: 'Majestic and gentle giant. Gets along with dogs. Loves grooming sessions.', shelter: 'City Cat Rescue', isVaccinated: true, isNeutered: true),
    Pet(id: '7', name: 'Rocky', type: PetType.dog, breed: 'Bulldog', age: 60, gender: 'Male', description: 'Calm and affectionate couch companion. Low exercise needs. Snores adorably.', shelter: 'Happy Paws Shelter', isVaccinated: true, isNeutered: true),
    Pet(id: '8', name: 'Mochi', type: PetType.rabbit, breed: 'Mini Rex', age: 6, gender: 'Male', description: 'Soft velvety fur. Very social and loves to binky around the room.', shelter: 'Small Friends Rescue', isVaccinated: true),
  ];

  int _tabIndex = 0;
  PetType? _filterType;
  String _searchQuery = '';

  List<Pet> get pets {
    var list = _filterType == null
        ? _pets
        : _pets.where((p) => p.type == _filterType).toList();
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.breed.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  List<Pet> get favorites => _pets.where((p) => p.isFavorite).toList();
  List<Pet> get allPets => List.unmodifiable(_pets);
  int get tabIndex => _tabIndex;
  PetType? get filterType => _filterType;

  int get totalPets => _pets.length;
  int get totalFavorites => favorites.length;
  Map<PetType, int> get countByType {
    final map = <PetType, int>{};
    for (final p in _pets) {
      map[p.type] = (map[p.type] ?? 0) + 1;
    }
    return map;
  }

  void setTab(int t) { _tabIndex = t; notifyListeners(); }
  void setFilter(PetType? t) { _filterType = t; notifyListeners(); }
  void setSearch(String q) { _searchQuery = q; notifyListeners(); }

  void toggleFavorite(String id) {
    final pet = _pets.firstWhere((p) => p.id == id);
    pet.isFavorite = !pet.isFavorite;
    notifyListeners();
  }

  void addPet(Pet pet) {
    _pets.insert(0, pet);
    notifyListeners();
  }
}

// --- App ---

class PetAdoptApp extends StatefulWidget {
  const PetAdoptApp({super.key});
  @override
  State<PetAdoptApp> createState() => _PetAdoptAppState();
}

class _PetAdoptAppState extends State<PetAdoptApp> {
  final _state = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => MaterialApp(
        title: 'PetAdopt',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: MainScreen(state: _state),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final screens = [
      BrowseScreen(state: state),
      FavoritesScreen(state: state),
      AddPetScreen(state: state),
    ];
    return Scaffold(
      body: screens[state.tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tabIndex,
        onDestinationSelected: state.setTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Add Pet'),
        ],
      ),
    );
  }
}

// --- Browse Screen ---

class BrowseScreen extends StatelessWidget {
  final AppState state;
  const BrowseScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pets = state.pets;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Pet'),
        actions: [
          PopupMenuButton<PetType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: state.setFilter,
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Pets')),
              ...PetType.values.map((t) =>
                  PopupMenuItem(value: t, child: Text(t.label))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or breed...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: state.setSearch,
            ),
          ),
          // Type filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: state.filterType == null,
                  onSelected: (_) => state.setFilter(null),
                ),
                const SizedBox(width: 8),
                ...PetType.values.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(t.label),
                    selected: state.filterType == t,
                    onSelected: (_) => state.setFilter(
                        state.filterType == t ? null : t),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${pets.length} pets available',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
          ),
          const SizedBox(height: 8),
          // Pet list
          Expanded(
            child: pets.isEmpty
                ? const Center(child: Text('No pets found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pets.length,
                    itemBuilder: (context, i) =>
                        PetCard(pet: pets[i], state: state),
                  ),
          ),
        ],
      ),
    );
  }
}

class PetCard extends StatelessWidget {
  final Pet pet;
  final AppState state;
  const PetCard({super.key, required this.pet, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet, state: state)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.primaryContainer,
                child: Icon(pet.type.icon, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${pet.breed} · ${pet.ageText}',
                        style: TextStyle(color: cs.outline, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: cs.outline),
                        const SizedBox(width: 4),
                        Text(pet.shelter,
                            style: TextStyle(color: cs.outline, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  pet.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: pet.isFavorite ? Colors.red : cs.outline,
                ),
                onPressed: () => state.toggleFavorite(pet.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Pet Detail ---

class PetDetailScreen extends StatelessWidget {
  final Pet pet;
  final AppState state;
  const PetDetailScreen({super.key, required this.pet, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            icon: Icon(pet.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: pet.isFavorite ? Colors.red : null),
            onPressed: () => state.toggleFavorite(pet.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: cs.primaryContainer,
              child: Icon(pet.type.icon, size: 40, color: cs.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(pet.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text('${pet.breed} · ${pet.gender} · ${pet.ageText}',
                style: TextStyle(color: cs.outline, fontSize: 15)),
          ),
          const SizedBox(height: 16),
          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Chip(
                avatar: const Icon(Icons.pets, size: 18),
                label: Text(pet.type.label),
              ),
              if (pet.isVaccinated)
                const Chip(
                  avatar: Icon(Icons.vaccines, size: 18),
                  label: Text('Vaccinated'),
                ),
              if (pet.isNeutered)
                const Chip(
                  avatar: Icon(Icons.check_circle, size: 18),
                  label: Text('Neutered'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // About
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(pet.description, style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
          // Shelter info
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_work),
              title: Text(pet.shelter),
              subtitle: const Text('Available for adoption'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Adoption Request'),
                  content: Text('Your request to adopt ${pet.name} has been submitted! The shelter will contact you soon.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.pets),
            label: const Text('Adopt Me'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Favorites Screen ---

class FavoritesScreen extends StatelessWidget {
  final AppState state;
  const FavoritesScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final favs = state.favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorites yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Heart a pet to save it here',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favs.length,
              itemBuilder: (context, i) =>
                  PetCard(pet: favs[i], state: state),
            ),
    );
  }
}

// --- Add Pet Screen ---

class AddPetScreen extends StatefulWidget {
  final AppState state;
  const AddPetScreen({super.key, required this.state});
  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _shelterCtrl = TextEditingController();
  PetType _type = PetType.dog;
  String _gender = 'Male';
  int _ageMonths = 12;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _descCtrl.dispose();
    _shelterCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty || _breedCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill name and breed')),
      );
      return;
    }
    widget.state.addPet(Pet(
      id: '${widget.state.totalPets + 1}',
      name: _nameCtrl.text.trim(),
      type: _type,
      breed: _breedCtrl.text.trim(),
      age: _ageMonths,
      gender: _gender,
      description: _descCtrl.text.trim().isEmpty
          ? 'A lovely ${_type.label.toLowerCase()} looking for a forever home.'
          : _descCtrl.text.trim(),
      shelter: _shelterCtrl.text.trim().isEmpty
          ? 'Community Shelter'
          : _shelterCtrl.text.trim(),
    ));
    _nameCtrl.clear();
    _breedCtrl.clear();
    _descCtrl.clear();
    _shelterCtrl.clear();
    widget.state.setTab(0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pet listed for adoption!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List a Pet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Pet Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PetType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: PetType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _breedCtrl,
            decoration: const InputDecoration(
              labelText: 'Breed',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            items: ['Male', 'Female']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Age: '),
              Expanded(
                child: Slider(
                  value: _ageMonths.toDouble(),
                  min: 1,
                  max: 180,
                  divisions: 179,
                  label: _ageMonths < 12
                      ? '$_ageMonths months'
                      : '${_ageMonths ~/ 12} years',
                  onChanged: (v) => setState(() => _ageMonths = v.round()),
                ),
              ),
              Text(_ageMonths < 12
                  ? '$_ageMonths mo'
                  : '${_ageMonths ~/ 12} yr'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Tell us about this pet...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _shelterCtrl,
            decoration: const InputDecoration(
              labelText: 'Shelter Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add),
            label: const Text('List Pet'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
