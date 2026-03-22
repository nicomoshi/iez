import 'package:flutter/material.dart';

void main() {
  runApp(const EventRsvpApp());
}

class Event {
  final String name;
  final String date;
  final String location;
  final String description;
  final int guestCount;

  const Event({
    required this.name,
    required this.date,
    this.location = '',
    this.description = '',
    this.guestCount = 0,
  });
}

class EventRsvpApp extends StatelessWidget {
  const EventRsvpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event RSVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Event> _events = const [
    Event(name: 'Birthday Party', date: 'Mar 28', location: 'Downtown Hall', description: 'A fun birthday celebration', guestCount: 8),
    Event(name: 'Team Lunch', date: 'Apr 2', location: 'Italian Bistro', description: 'Quarterly team lunch', guestCount: 5),
    Event(name: 'Movie Night', date: 'Apr 5', location: 'Home Theater', description: 'Watching the latest blockbuster', guestCount: 3),
    Event(name: 'Book Club', date: 'Apr 10', location: 'City Library', description: 'Discussing this month\'s pick', guestCount: 6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventPage()),
                );
              },
              label: const Text('Create Event'),
              icon: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'My RSVPs'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Hosting'),
        ],
      ),
    );
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Events';
      case 1:
        return 'My RSVPs';
      case 2:
        return 'Hosting';
      default:
        return 'Events';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildEventsTab();
      case 1:
        return _buildRsvpsTab();
      case 2:
        return _buildHostingTab();
      default:
        return _buildEventsTab();
    }
  }

  Widget _buildEventsTab() {
    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return ListTile(
          title: Text(event.name),
          subtitle: Text(event.date),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(event: event),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRsvpsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'My RSVPs',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Birthday Party'),
          subtitle: const Text('Mar 28'),
          trailing: Chip(
            label: const Text('Going'),
            backgroundColor: Colors.green.shade100,
          ),
        ),
        ListTile(
          title: const Text('Book Club'),
          subtitle: const Text('Apr 10'),
          trailing: Chip(
            label: const Text('Maybe'),
            backgroundColor: Colors.orange.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildHostingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Hosting',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Movie Night'),
          subtitle: const Text('Apr 5'),
          trailing: const Text('3 guests'),
        ),
        ListTile(
          title: const Text('Team Lunch'),
          subtitle: const Text('Apr 2'),
          trailing: const Text('5 guests'),
        ),
      ],
    );
  }
}

class EventDetailPage extends StatelessWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Event Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            event.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Text('Date', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(event.date, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(event.location.isEmpty ? 'TBD' : event.location,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Guests', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('${event.guestCount} guests',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          if (event.description.isNotEmpty) ...[
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(event.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
          ],
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete Event'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create Event'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Event Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Search Events'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
