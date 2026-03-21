import 'package:flutter/material.dart';

void main() => runApp(const TravelLogApp());

class TravelLogApp extends StatelessWidget {
  const TravelLogApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const TravelHome(),
    );
  }
}

class Trip {
  final String destination;
  final String country;
  final String dates;
  final int rating;
  final int photos;
  final String highlight;
  bool isFavorite;
  Trip({
    required this.destination,
    required this.country,
    required this.dates,
    required this.rating,
    required this.photos,
    required this.highlight,
    this.isFavorite = false,
  });
}

class TravelHome extends StatefulWidget {
  const TravelHome({super.key});
  @override
  State<TravelHome> createState() => _TravelHomeState();
}

class _TravelHomeState extends State<TravelHome> {
  String _filter = 'All';
  final List<Trip> _trips = [
    Trip(destination: 'Kyoto', country: 'Japan', dates: 'Oct 2025', rating: 5, photos: 234, highlight: 'Bamboo forest at sunrise'),
    Trip(destination: 'Barcelona', country: 'Spain', dates: 'Jul 2025', rating: 4, photos: 189, highlight: 'Sagrada Familia architecture'),
    Trip(destination: 'Reykjavik', country: 'Iceland', dates: 'Jan 2025', rating: 5, photos: 312, highlight: 'Northern lights over glacier'),
    Trip(destination: 'Machu Picchu', country: 'Peru', dates: 'Mar 2025', rating: 5, photos: 278, highlight: 'Sunrise at the citadel'),
    Trip(destination: 'Cape Town', country: 'South Africa', dates: 'Nov 2024', rating: 4, photos: 156, highlight: 'Table Mountain hike'),
    Trip(destination: 'Santorini', country: 'Greece', dates: 'Aug 2024', rating: 4, photos: 201, highlight: 'Sunset in Oia village'),
  ];

  List<Trip> get _filtered {
    if (_filter == 'All') return _trips;
    if (_filter == '5 Stars') return _trips.where((t) => t.rating == 5).toList();
    if (_filter == 'Favorites') return _trips.where((t) => t.isFavorite).toList();
    return _trips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Stats',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TravelStatsPage(trips: _trips))),
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
              children: ['All', '5 Stars', 'Favorites'].map((f) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No trips found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final trip = _filtered[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(trip.destination),
                          subtitle: Text('${trip.country} · ${trip.dates} · ${'★' * trip.rating}'),
                          trailing: IconButton(
                            icon: Icon(trip.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: trip.isFavorite ? Colors.red : null),
                            tooltip: trip.isFavorite ? 'Unfavorite' : 'Favorite',
                            onPressed: () => setState(() => trip.isFavorite = !trip.isFavorite),
                          ),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => TripDetailPage(trip: trip))),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Trip',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddTripPage()));
          if (result != null) {
            setState(() => _trips.insert(0, Trip(
              destination: result['destination']!,
              country: result['country']!,
              dates: 'Mar 2026',
              rating: 4,
              photos: 0,
              highlight: result['highlight'] ?? '',
            )));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TripDetailPage extends StatelessWidget {
  final Trip trip;
  const TripDetailPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trip.destination)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.destination, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(trip.country, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text(trip.dates)),
                const SizedBox(width: 8),
                Chip(label: Text('${'★' * trip.rating}')),
                const SizedBox(width: 8),
                Chip(label: Text('${trip.photos} photos')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Highlight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(trip.highlight, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});
  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _destCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _highlightCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _destCtrl,
              decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryCtrl,
              decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _highlightCtrl,
              decoration: const InputDecoration(labelText: 'Highlight', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_destCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'destination': _destCtrl.text,
                      'country': _countryCtrl.text,
                      'highlight': _highlightCtrl.text,
                    });
                  }
                },
                child: const Text('Save Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TravelStatsPage extends StatelessWidget {
  final List<Trip> trips;
  const TravelStatsPage({super.key, required this.trips});

  @override
  Widget build(BuildContext context) {
    final totalPhotos = trips.fold<int>(0, (s, t) => s + t.photos);
    final countries = trips.map((t) => t.country).toSet();
    final avgRating = trips.isEmpty ? 0.0 : trips.fold<int>(0, (s, t) => s + t.rating) / trips.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Total Trips: ${trips.length}'),
                  Text('Countries Visited: ${countries.length}'),
                  Text('Total Photos: $totalPhotos'),
                  Text('Avg Rating: ${avgRating.toStringAsFixed(1)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Countries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...countries.map((c) {
            final count = trips.where((t) => t.country == c).length;
            return ListTile(
              leading: const Icon(Icons.place),
              title: Text(c),
              trailing: Chip(label: Text('$count trips')),
            );
          }),
        ],
      ),
    );
  }
}
