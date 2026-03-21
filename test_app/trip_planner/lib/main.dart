import 'package:flutter/material.dart';

void main() {
  runApp(const TripPlannerApp());
}

class TripPlannerApp extends StatelessWidget {
  const TripPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Planner',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Models ---

class Trip {
  String destination;
  String dates;
  int days;
  int travelers;
  double budget;
  String status;
  String hotel;
  String flight;
  List<Activity> activities;

  Trip({
    required this.destination,
    required this.dates,
    required this.days,
    required this.travelers,
    required this.budget,
    required this.status,
    this.hotel = '',
    this.flight = '',
    List<Activity>? activities,
  }) : activities = activities ?? [];
}

class Activity {
  String name;
  String time;
  String location;
  double cost;

  Activity({
    required this.name,
    required this.time,
    required this.location,
    required this.cost,
  });
}

class PackingItem {
  String name;
  bool checked;

  PackingItem({required this.name, this.checked = false});
}

// --- Global State ---

final List<Trip> _trips = [
  Trip(
    destination: 'Tokyo, Japan',
    dates: 'Apr 10 - Apr 17',
    days: 7,
    travelers: 2,
    budget: 5000,
    status: 'Planning',
    hotel: 'Shinjuku Grand Hotel',
    flight: 'AA 173 - JFK to NRT',
    activities: [
      Activity(name: 'Visit Shibuya Crossing', time: '10:00 AM', location: 'Shibuya', cost: 0),
      Activity(name: 'Tsukiji Fish Market', time: '7:00 AM', location: 'Tsukiji', cost: 50),
      Activity(name: 'Mount Fuji Day Trip', time: '6:00 AM', location: 'Fuji', cost: 120),
    ],
  ),
  Trip(
    destination: 'Paris, France',
    dates: 'May 5 - May 12',
    days: 7,
    travelers: 2,
    budget: 6000,
    status: 'Booked',
    hotel: 'Hotel Le Marais',
    flight: 'AF 007 - JFK to CDG',
    activities: [
      Activity(name: 'Eiffel Tower', time: '9:00 AM', location: 'Champ de Mars', cost: 25),
      Activity(name: 'Louvre Museum', time: '1:00 PM', location: 'Rue de Rivoli', cost: 17),
      Activity(name: 'Seine River Cruise', time: '7:00 PM', location: 'Pont Neuf', cost: 40),
    ],
  ),
  Trip(
    destination: 'New York, USA',
    dates: 'Jun 1 - Jun 5',
    days: 4,
    travelers: 1,
    budget: 3000,
    status: 'Planning',
    hotel: 'Manhattan Suites',
    flight: 'UA 456 - LAX to JFK',
    activities: [
      Activity(name: 'Central Park', time: '8:00 AM', location: 'Central Park', cost: 0),
      Activity(name: 'Broadway Show', time: '7:30 PM', location: 'Times Square', cost: 150),
    ],
  ),
];

final List<PackingItem> _packingItems = [
  PackingItem(name: 'Passport'),
  PackingItem(name: 'Charger'),
  PackingItem(name: 'Sunscreen'),
  PackingItem(name: 'First Aid Kit'),
  PackingItem(name: 'Umbrella'),
];

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
        title: const Text('Trip Planner'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'packing') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PackingListScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'packing', child: Text('Packing List')),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _trips.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return _TripCard(
            trip: trip,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
              );
              setState(() {});
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTripScreen()),
          );
          setState(() {});
        },
        child: const Text('Add Trip'),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  Color _statusColor() {
    switch (trip.status) {
      case 'Booked':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      trip.destination,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(trip.status),
                    backgroundColor: _statusColor().withValues(alpha: 0.2),
                    labelStyle: TextStyle(color: _statusColor()),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(trip.dates),
              const SizedBox(height: 4),
              Text('${trip.days} days  •  ${trip.travelers} traveler${trip.travelers > 1 ? 's' : ''}  •  \$${trip.budget.toStringAsFixed(0)}'),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Trip Detail Screen ---

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final activityTotal = trip.activities.fold<double>(0, (sum, a) => sum + a.cost);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.destination),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(trip.destination, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Dates: ${trip.dates}'),
          Text('Duration: ${trip.days} days'),
          Text('Travelers: ${trip.travelers}'),
          Text('Hotel: ${trip.hotel}'),
          Text('Flight: ${trip.flight}'),
          const SizedBox(height: 16),

          const Text('Budget Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total Budget: \$${trip.budget.toStringAsFixed(0)}'),
          Text('Activities: \$${activityTotal.toStringAsFixed(0)}'),
          Text('Remaining: \$${(trip.budget - activityTotal).toStringAsFixed(0)}'),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddActivityScreen(trip: trip)),
                  );
                  setState(() {});
                },
                child: const Text('Add Activity'),
              ),
            ],
          ),
          ...trip.activities.map((a) => ListTile(
                title: Text(a.name),
                subtitle: Text('${a.time}  •  ${a.location}'),
                trailing: Text('\$${a.cost.toStringAsFixed(0)}'),
              )),
        ],
      ),
    );
  }
}

// --- Add Trip Screen ---

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _destinationController = TextEditingController();
  final _hotelController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _destinationController.dispose();
    _hotelController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => '${_monthName(d.month)} ${d.day}';

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _dateRange == null
        ? 'No dates selected'
        : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hotelController,
              decoration: const InputDecoration(labelText: 'Hotel', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(labelText: 'Budget', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text(dateText)),
                TextButton(
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (range != null) setState(() => _dateRange = range);
                  },
                  child: const Text('Select Dates'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_destinationController.text.isEmpty) return;
                final budget = double.tryParse(_budgetController.text) ?? 0;
                final days = _dateRange == null ? 1 : _dateRange!.end.difference(_dateRange!.start).inDays;
                _trips.add(Trip(
                  destination: _destinationController.text,
                  dates: _dateRange == null ? 'TBD' : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                  days: days,
                  travelers: 1,
                  budget: budget,
                  status: 'Planning',
                  hotel: _hotelController.text,
                ));
                Navigator.pop(context);
              },
              child: const Text('Save Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Activity Screen ---

class AddActivityScreen extends StatefulWidget {
  final Trip trip;

  const AddActivityScreen({super.key, required this.trip});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _costController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _costController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Activity Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _costController,
              decoration: const InputDecoration(labelText: 'Cost', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty) return;
                widget.trip.activities.add(Activity(
                  name: _nameController.text,
                  location: _locationController.text,
                  cost: double.tryParse(_costController.text) ?? 0,
                  time: _timeController.text,
                ));
                Navigator.pop(context);
              },
              child: const Text('Save Activity'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Packing List Screen ---

class PackingListScreen extends StatefulWidget {
  const PackingListScreen({super.key});

  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen> {
  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Packing List')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _packingItems.length,
              itemBuilder: (context, index) {
                final item = _packingItems[index];
                return CheckboxListTile(
                  title: Text(item.name),
                  value: item.checked,
                  onChanged: (val) => setState(() => item.checked = val ?? false),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemController,
                    decoration: const InputDecoration(labelText: 'New Item', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_newItemController.text.isEmpty) return;
                    setState(() {
                      _packingItems.add(PackingItem(name: _newItemController.text));
                      _newItemController.clear();
                    });
                  },
                  child: const Text('Add Item'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
