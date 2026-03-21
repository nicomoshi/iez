import 'package:flutter/material.dart';

void main() {
  runApp(const WineJournalApp());
}

class Wine {
  final String name;
  final String winery;
  final int vintage;
  final String region;
  final String type;
  final int rating;
  final String tastingNotes;
  final String foodPairing;
  final double price;
  bool isFavorite;

  Wine({
    required this.name,
    required this.winery,
    required this.vintage,
    required this.region,
    required this.type,
    required this.rating,
    this.tastingNotes = '',
    this.foodPairing = '',
    this.price = 0.0,
    this.isFavorite = false,
  });
}

class WineRegion {
  final String name;
  final String country;
  final String knownVarieties;

  const WineRegion({
    required this.name,
    required this.country,
    required this.knownVarieties,
  });
}

final List<WineRegion> wineRegions = [
  const WineRegion(name: 'Bordeaux', country: 'France', knownVarieties: 'Cabernet Sauvignon, Merlot'),
  const WineRegion(name: 'Napa Valley', country: 'USA', knownVarieties: 'Cabernet Sauvignon'),
  const WineRegion(name: 'Burgundy', country: 'France', knownVarieties: 'Pinot Noir, Chardonnay'),
  const WineRegion(name: 'Marlborough', country: 'New Zealand', knownVarieties: 'Sauvignon Blanc'),
];

class WineJournalApp extends StatelessWidget {
  const WineJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wine Journal',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Red', 'White', 'Rosé', 'Sparkling'];

  final List<Wine> _wines = [
    Wine(
      name: 'Chateau Margaux',
      winery: 'Chateau Margaux',
      vintage: 2015,
      region: 'Bordeaux',
      type: 'Red',
      rating: 5,
      tastingNotes: 'Complex layers of blackcurrant, violet, and cedar with silky tannins.',
      foodPairing: 'Grilled lamb chops',
      price: 850.00,
    ),
    Wine(
      name: 'Cloudy Bay',
      winery: 'Cloudy Bay',
      vintage: 2022,
      region: 'Marlborough',
      type: 'White',
      rating: 4,
      tastingNotes: 'Crisp citrus and tropical fruit with a refreshing mineral finish.',
      foodPairing: 'Seafood platter',
      price: 28.00,
    ),
    Wine(
      name: 'Dom Perignon',
      winery: 'Moet Hennessy',
      vintage: 2012,
      region: 'Champagne',
      type: 'Sparkling',
      rating: 5,
      tastingNotes: 'Elegant brioche and toasted almond with fine persistent bubbles.',
      foodPairing: 'Oysters and caviar',
      price: 250.00,
    ),
    Wine(
      name: 'Whispering Angel',
      winery: 'Caves d\'Esclans',
      vintage: 2023,
      region: 'Provence',
      type: 'Rosé',
      rating: 3,
      tastingNotes: 'Delicate strawberry and peach with a dry, crisp finish.',
      foodPairing: 'Mediterranean salad',
      price: 22.00,
    ),
    Wine(
      name: 'Opus One',
      winery: 'Opus One Winery',
      vintage: 2018,
      region: 'Napa Valley',
      type: 'Red',
      rating: 5,
      tastingNotes: 'Rich cassis and dark cherry with velvety tannins and a long finish.',
      foodPairing: 'Prime ribeye steak',
      price: 450.00,
    ),
    Wine(
      name: 'Chablis Premier',
      winery: 'William Fevre',
      vintage: 2020,
      region: 'Burgundy',
      type: 'White',
      rating: 4,
      tastingNotes: 'Bright green apple and flinty minerality with balanced acidity.',
      foodPairing: 'Roasted chicken',
      price: 45.00,
    ),
  ];

  List<Wine> get _filteredWines {
    if (_selectedFilter == 'All') return _wines;
    return _wines.where((w) => w.type == _selectedFilter).toList();
  }

  String _starsText(int rating) {
    return List.filled(rating, '\u2605').join() + List.filled(5 - rating, '\u2606').join();
  }

  void _addWine(Wine wine) {
    setState(() {
      _wines.add(wine);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredWines;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wine Journal'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Regions') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegionsScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(value: 'Regions', child: Text('Regions')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _filters.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
                    onSelected: (_) {
                      setState(() => _selectedFilter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final wine = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(wine.name),
                    subtitle: Text('${wine.winery} \u2022 ${wine.vintage}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(label: Text(wine.type)),
                        const SizedBox(width: 8),
                        Text(_starsText(wine.rating)),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailScreen(wine: wine)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Wine>(
            context,
            MaterialPageRoute(builder: (_) => const AddWineScreen()),
          );
          if (result != null) _addWine(result);
        },
        child: const Text('Add Wine'),
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final Wine wine;

  const DetailScreen({super.key, required this.wine});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final wine = widget.wine;
    final stars = List.filled(wine.rating, '\u2605').join() +
        List.filled(5 - wine.rating, '\u2606').join();

    return Scaffold(
      appBar: AppBar(
        title: Text(wine.name),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                wine.isFavorite = !wine.isFavorite;
              });
            },
            icon: Icon(wine.isFavorite ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(wine.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Winery: ${wine.winery}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Vintage: ${wine.vintage}'),
          const SizedBox(height: 4),
          Text('Region: ${wine.region}'),
          const SizedBox(height: 4),
          Text('Type: ${wine.type}'),
          const SizedBox(height: 8),
          Text('Rating: $stars', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('Tasting Notes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(wine.tastingNotes),
          const SizedBox(height: 16),
          Text('Food Pairing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(wine.foodPairing),
          const SizedBox(height: 16),
          Text('Price: \$${wine.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class AddWineScreen extends StatefulWidget {
  const AddWineScreen({super.key});

  @override
  State<AddWineScreen> createState() => _AddWineScreenState();
}

class _AddWineScreenState extends State<AddWineScreen> {
  final _nameController = TextEditingController();
  final _wineryController = TextEditingController();
  final _vintageController = TextEditingController();
  final _regionController = TextEditingController();
  final _notesController = TextEditingController();
  final _pairingController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedType = 'Red';
  double _rating = 3;

  final List<String> _types = ['Red', 'White', 'Rosé', 'Sparkling'];

  @override
  void dispose() {
    _nameController.dispose();
    _wineryController.dispose();
    _vintageController.dispose();
    _regionController.dispose();
    _notesController.dispose();
    _pairingController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Wine')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Wine Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wineryController,
            decoration: const InputDecoration(labelText: 'Winery'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vintageController,
            decoration: const InputDecoration(labelText: 'Vintage'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regionController,
            decoration: const InputDecoration(labelText: 'Region'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Tasting Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pairingController,
            decoration: const InputDecoration(labelText: 'Food Pairing'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedType = v);
            },
          ),
          const SizedBox(height: 16),
          Text('Rating: ${_rating.round()}'),
          Slider(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: _rating.round().toString(),
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final wine = Wine(
                name: _nameController.text,
                winery: _wineryController.text,
                vintage: int.tryParse(_vintageController.text) ?? 2024,
                region: _regionController.text,
                type: _selectedType,
                rating: _rating.round(),
                tastingNotes: _notesController.text,
                foodPairing: _pairingController.text,
                price: double.tryParse(_priceController.text) ?? 0.0,
              );
              Navigator.pop(context, wine);
            },
            child: const Text('Save Wine'),
          ),
        ],
      ),
    );
  }
}

class RegionsScreen extends StatelessWidget {
  const RegionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: wineRegions.length,
        itemBuilder: (context, index) {
          final region = wineRegions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(region.name),
              subtitle: Text('${region.country} \u2022 ${region.knownVarieties}'),
            ),
          );
        },
      ),
    );
  }
}
