import 'package:flutter/material.dart';

void main() {
  runApp(const ParkingFinderApp());
}

class ParkingSpot {
  final String id;
  final String location;
  final String type; // Street, Garage, Lot
  final double hourlyRate;
  final bool isAvailable;
  final double distance; // in miles
  final String notes;

  ParkingSpot({required this.id, required this.location, required this.type, required this.hourlyRate, this.isAvailable = true, required this.distance, this.notes = ''});
  ParkingSpot copyWith({bool? isAvailable}) => ParkingSpot(id: id, location: location, type: type, hourlyRate: hourlyRate, isAvailable: isAvailable ?? this.isAvailable, distance: distance, notes: notes);
}

class ParkingHistory {
  final String id;
  final String location;
  final DateTime startTime;
  final int durationHours;
  final double cost;

  ParkingHistory({required this.id, required this.location, required this.startTime, required this.durationHours, required this.cost});
}

class AppState extends ChangeNotifier {
  final List<ParkingSpot> _spots = [
    ParkingSpot(id: '1', location: 'Main Street Garage', type: 'Garage', hourlyRate: 3.50, distance: 0.2, notes: '24/7 access'),
    ParkingSpot(id: '2', location: 'Oak Avenue Lot', type: 'Lot', hourlyRate: 2.00, distance: 0.5, notes: 'Open air'),
    ParkingSpot(id: '3', location: 'Downtown Parking', type: 'Garage', hourlyRate: 5.00, distance: 0.1, notes: 'Covered parking'),
    ParkingSpot(id: '4', location: 'Elm Street', type: 'Street', hourlyRate: 1.50, distance: 0.8, isAvailable: false, notes: 'Metered'),
    ParkingSpot(id: '5', location: 'City Center Lot', type: 'Lot', hourlyRate: 4.00, distance: 0.3, notes: 'Near shops'),
    ParkingSpot(id: '6', location: 'Park Avenue', type: 'Street', hourlyRate: 1.00, distance: 1.2, notes: 'Free after 6pm'),
  ];

  final List<ParkingHistory> _history = [
    ParkingHistory(id: '1', location: 'Main Street Garage', startTime: DateTime.now().subtract(const Duration(days: 1)), durationHours: 3, cost: 10.50),
    ParkingHistory(id: '2', location: 'Downtown Parking', startTime: DateTime.now().subtract(const Duration(days: 3)), durationHours: 2, cost: 10.00),
  ];

  String _sortBy = 'distance';

  List<ParkingSpot> get spots => List.unmodifiable(_spots);
  List<ParkingHistory> get history => List.unmodifiable(_history);
  String get sortBy => _sortBy;

  List<ParkingSpot> get sortedSpots {
    final list = List<ParkingSpot>.from(_spots);
    if (_sortBy == 'price') {
      list.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
    } else {
      list.sort((a, b) => a.distance.compareTo(b.distance));
    }
    return list;
  }

  int get availableCount => _spots.where((s) => s.isAvailable).length;
  double get totalSpent => _history.fold(0, (sum, h) => sum + h.cost);

  void setSortBy(String sort) { _sortBy = sort; notifyListeners(); }

  void toggleAvailability(String id) {
    final idx = _spots.indexWhere((s) => s.id == id);
    if (idx >= 0) { _spots[idx] = _spots[idx].copyWith(isAvailable: !_spots[idx].isAvailable); notifyListeners(); }
  }

  void addSpot(ParkingSpot spot) { _spots.add(spot); notifyListeners(); }

  void addHistory(ParkingHistory h) { _history.insert(0, h); notifyListeners(); }
}

class ParkingFinderApp extends StatefulWidget {
  const ParkingFinderApp({super.key});
  @override State<ParkingFinderApp> createState() => _ParkingFinderAppState();
}

class _ParkingFinderAppState extends State<ParkingFinderApp> {
  final _state = AppState();
  @override void initState() { super.initState(); _state.addListener(() => setState(() {})); }
  @override Widget build(BuildContext context) {
    return MaterialApp(title: 'Parking Finder', debugShowCheckedModeBanner: false, theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.cyan), home: MainScreen(state: _state));
  }
}

class MainScreen extends StatefulWidget {
  final AppState state;
  const MainScreen({super.key, required this.state});
  @override State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  @override Widget build(BuildContext context) {
    final pages = [SpotsPage(state: widget.state), HistoryPage(state: widget.state), SettingsPage(state: widget.state)];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_parking), label: 'Spots'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class SpotsPage extends StatelessWidget {
  final AppState state;
  const SpotsPage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Parking'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: () => _showSortDialog(context), tooltip: 'Sort'),
          Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${state.availableCount} available'))),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.sortedSpots.length,
        itemBuilder: (context, index) {
          final spot = state.sortedSpots[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(spot.location),
              subtitle: Text('${spot.type} · \$${spot.hourlyRate.toStringAsFixed(2)}/hr · ${spot.distance} mi'),
              trailing: Chip(label: Text(spot.isAvailable ? 'Open' : 'Full'), backgroundColor: spot.isAvailable ? Colors.green.shade100 : Colors.red.shade100),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpotDetailPage(state: state, spot: spot))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddSpotDialog(context), icon: const Icon(Icons.add), label: const Text('Add Spot')),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Sort By'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        RadioListTile<String>(value: 'distance', groupValue: state.sortBy, title: const Text('Distance'), onChanged: (v) { state.setSortBy(v!); Navigator.pop(ctx); }),
        RadioListTile<String>(value: 'price', groupValue: state.sortBy, title: const Text('Price'), onChanged: (v) { state.setSortBy(v!); Navigator.pop(ctx); }),
      ]),
    ));
  }

  void _showAddSpotDialog(BuildContext context) {
    final locController = TextEditingController();
    final rateController = TextEditingController();
    String type = 'Lot';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Spot'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: locController, decoration: const InputDecoration(labelText: 'Location')),
        const SizedBox(height: 12),
        TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Hourly Rate'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Type'), items: ['Street', 'Garage', 'Lot'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => type = v ?? type),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { if (locController.text.isNotEmpty) { state.addSpot(ParkingSpot(id: DateTime.now().millisecondsSinceEpoch.toString(), location: locController.text, type: type, hourlyRate: double.tryParse(rateController.text) ?? 0, distance: 0.5)); Navigator.pop(ctx); } }, child: const Text('Save')),
      ],
    ));
  }
}

class SpotDetailPage extends StatelessWidget {
  final AppState state;
  final ParkingSpot spot;
  const SpotDetailPage({super.key, required this.state, required this.spot});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(spot.location)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Spot Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _Row(label: 'Location', value: spot.location),
          _Row(label: 'Type', value: spot.type),
          _Row(label: 'Rate', value: '\$${spot.hourlyRate.toStringAsFixed(2)}/hr'),
          _Row(label: 'Distance', value: '${spot.distance} mi'),
          _Row(label: 'Status', value: spot.isAvailable ? 'Available' : 'Full'),
          if (spot.notes.isNotEmpty) _Row(label: 'Notes', value: spot.notes),
        ]))),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () { state.addHistory(ParkingHistory(id: DateTime.now().millisecondsSinceEpoch.toString(), location: spot.location, startTime: DateTime.now(), durationHours: 1, cost: spot.hourlyRate)); Navigator.pop(context); },
          icon: const Icon(Icons.local_parking),
          label: const Text('Park Here'),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label; final String value;
  const _Row({required this.label, required this.value});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))]));
}

class HistoryPage extends StatelessWidget {
  final AppState state;
  const HistoryPage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking History')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text('Total Spent', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('\$${state.totalSpent.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('${state.history.length} sessions'),
        ]))),
        const SizedBox(height: 16),
        ...state.history.map((h) {
          final days = DateTime.now().difference(h.startTime).inDays;
          final when = days == 0 ? 'Today' : days == 1 ? 'Yesterday' : '$days days ago';
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(h.location), subtitle: Text('${h.durationHours}h · \$${h.cost.toStringAsFixed(2)}'), trailing: Text(when)));
        }),
      ]),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(title: const Text('Notifications'), subtitle: const Text('Parking expiry alerts'), leading: const Icon(Icons.notifications), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('Payment Methods'), subtitle: const Text('Manage cards'), leading: const Icon(Icons.credit_card), trailing: const Icon(Icons.chevron_right)),
        ListTile(title: const Text('About'), subtitle: const Text('Parking Finder v1.0'), leading: const Icon(Icons.info), onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('About'), content: const Text('Parking Finder helps you find and track parking spots near you.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))]))),
      ]),
    );
  }
}
