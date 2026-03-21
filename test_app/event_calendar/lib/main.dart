import 'package:flutter/material.dart';

void main() => runApp(const EventCalendarApp());

class EventCalendarApp extends StatelessWidget {
  const EventCalendarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const EventCalendarHome(),
    );
  }
}

class Event {
  final String title;
  final String category;
  final String time;
  final String description;
  bool isCompleted;
  Event({required this.title, required this.category, required this.time,
         this.description = '', this.isCompleted = false});
}

class EventCalendarHome extends StatefulWidget {
  const EventCalendarHome({super.key});
  @override
  State<EventCalendarHome> createState() => _EventCalendarHomeState();
}

class _EventCalendarHomeState extends State<EventCalendarHome> {
  int _selectedTab = 0;
  String _filterCategory = 'Show All';
  final List<Event> _events = [
    Event(title: 'Team Meeting', category: 'Work', time: '09:00 AM', description: 'Weekly standup'),
    Event(title: 'Gym Session', category: 'Health', time: '07:00 AM', description: 'Leg day'),
    Event(title: 'Dentist', category: 'Personal', time: '02:00 PM', description: 'Annual checkup'),
    Event(title: 'Project Review', category: 'Work', time: '11:00 AM', description: 'Sprint review'),
    Event(title: 'Dinner with Friends', category: 'Social', time: '07:30 PM', description: 'Italian restaurant'),
    Event(title: 'Morning Run', category: 'Health', time: '06:00 AM', description: '5km route'),
  ];

  final List<String> _categories = ['Show All', 'Work', 'Health', 'Personal', 'Social'];

  List<Event> get _filteredEvents {
    final events = _filterCategory == 'Show All' ? _events : _events.where((e) => e.category == _filterCategory).toList();
    if (_selectedTab == 1) return events.where((e) => e.isCompleted).toList();
    if (_selectedTab == 2) return events.where((e) => !e.isCompleted).toList();
    return events;
  }

  void _addEvent(String title, String category, String time, String desc) {
    setState(() => _events.add(Event(title: title, category: category, time: time, description: desc)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Stats',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => StatsPage(events: _events))),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('All')),
                ButtonSegment(value: 1, label: Text('Done')),
                ButtonSegment(value: 2, label: Text('Pending')),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (s) => setState(() => _selectedTab = s.first),
            ),
          ),
          // Category filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(c),
                  selected: _filterCategory == c,
                  onSelected: (_) => setState(() => _filterCategory = c),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Event list
          Expanded(
            child: _filteredEvents.isEmpty
                ? const Center(child: Text('No events found'))
                : ListView.builder(
                    itemCount: _filteredEvents.length,
                    itemBuilder: (_, i) {
                      final event = _filteredEvents[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(
                            value: event.isCompleted,
                            onChanged: (_) => setState(() => event.isCompleted = !event.isCompleted),
                          ),
                          title: Text(event.title,
                              style: TextStyle(
                                decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                              )),
                          subtitle: Text('${event.time} — ${event.category}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            tooltip: 'Details',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(event.title),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Time: ${event.time}'),
                                    Text('Category: ${event.category}'),
                                    const SizedBox(height: 8),
                                    Text(event.description),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Event',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddEventPage()));
          if (result != null) _addEvent(result['title']!, result['category']!, result['time']!, result['desc']!);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});
  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '12:00 PM');
  final _descCtrl = TextEditingController();
  String _category = 'Work';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Event title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeCtrl,
              decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Work', 'Health', 'Personal', 'Social'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'title': _titleCtrl.text,
                    'category': _category,
                    'time': _timeCtrl.text,
                    'desc': _descCtrl.text,
                  });
                }
              },
              child: const Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  final List<Event> events;
  const StatsPage({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final total = events.length;
    final completed = events.where((e) => e.isCompleted).length;
    final categories = <String, int>{};
    for (final e in events) {
      categories[e.category] = (categories[e.category] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Event Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Total Events: $total', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Completed: $completed'),
                    Text('Pending: ${total - completed}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('By Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...categories.entries.map((e) => ListTile(
              title: Text(e.key),
              trailing: Text('${e.value} events'),
            )),
          ],
        ),
      ),
    );
  }
}
