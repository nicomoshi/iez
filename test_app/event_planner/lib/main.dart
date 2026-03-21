import 'package:flutter/material.dart';

void main() => runApp(const EventPlannerApp());

class EventPlannerApp extends StatelessWidget {
  const EventPlannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Models ---

class Event {
  String name;
  DateTime date;
  TimeOfDay time;
  String location;
  String description;
  int attendees;
  String category;
  double budget;
  bool favorite;
  String? rsvp;

  Event({
    required this.name,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.attendees,
    required this.category,
    this.budget = 0,
    this.favorite = false,
    this.rsvp,
  });
}

// --- Data ---

List<Event> _events = [
  Event(
    name: "Sarah's Birthday",
    date: DateTime(2026, 3, 25),
    time: const TimeOfDay(hour: 19, minute: 0),
    location: 'Skyline Rooftop Bar',
    description:
        'Birthday celebration for Sarah with rooftop views and live music.',
    attendees: 24,
    category: 'Birthday',
    budget: 1200,
  ),
  Event(
    name: 'Q1 Review',
    date: DateTime(2026, 3, 28),
    time: const TimeOfDay(hour: 10, minute: 0),
    location: 'Conference Room A',
    description: 'Quarterly business review with department leads.',
    attendees: 12,
    category: 'Meeting',
    budget: 200,
  ),
  Event(
    name: 'Spring Gala',
    date: DateTime(2026, 4, 5),
    time: const TimeOfDay(hour: 18, minute: 30),
    location: 'Grand Ballroom',
    description:
        'Annual spring gala with dinner, dancing, and silent auction.',
    attendees: 150,
    category: 'Party',
    budget: 15000,
  ),
  Event(
    name: 'Tech Summit',
    date: DateTime(2026, 4, 12),
    time: const TimeOfDay(hour: 9, minute: 0),
    location: 'Convention Center',
    description:
        'Full-day technology summit featuring keynotes and workshops.',
    attendees: 500,
    category: 'Conference',
    budget: 50000,
  ),
  Event(
    name: 'Team Lunch',
    date: DateTime(2026, 3, 20),
    time: const TimeOfDay(hour: 12, minute: 0),
    location: 'Café Roma',
    description: 'Casual team lunch to celebrate project milestones.',
    attendees: 8,
    category: 'Meeting',
    budget: 300,
  ),
];

final List<Map<String, String>> _templates = [
  {
    'name': 'Birthday Party',
    'category': 'Birthday',
    'description':
        'A fun birthday celebration with cake, decorations, and games.',
  },
  {
    'name': 'Team Meeting',
    'category': 'Meeting',
    'description':
        'Regular team sync to discuss progress and blockers.',
  },
  {
    'name': 'Wedding Reception',
    'category': 'Wedding',
    'description':
        'Elegant wedding reception with dinner, toasts, and dancing.',
  },
];

const List<String> _categories = [
  'Wedding',
  'Birthday',
  'Conference',
  'Party',
  'Meeting',
];

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filter = 'All';
  final _now = DateTime(2026, 3, 22);

  List<Event> get _filtered {
    switch (_filter) {
      case 'Upcoming':
        return _events.where((e) => !e.date.isBefore(_now)).toList();
      case 'Past':
        return _events.where((e) => e.date.isBefore(_now)).toList();
      case 'Favorites':
        return _events.where((e) => e.favorite).toList();
      default:
        return _events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Planner'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'Templates') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TemplatesScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'Templates', child: Text('Templates')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children:
                  ['All', 'Upcoming', 'Past', 'Favorites'].map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No events found'))
                : ListView.builder(
                    itemCount: filtered.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      return Card(
                        child: ListTile(
                          title: Text(e.name),
                          subtitle: Text(
                            '${_fmtDate(e.date)} · ${e.location} · ${e.attendees} attendees',
                          ),
                          trailing: Chip(label: Text(e.category)),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailScreen(event: e),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Event>(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditScreen()),
          );
          if (result != null) {
            setState(() => _events.add(result));
          }
        },
        child: const Text('Add Event'),
      ),
    );
  }
}

// --- Detail Screen ---

class DetailScreen extends StatefulWidget {
  final Event event;
  const DetailScreen({super.key, required this.event});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Event get e => widget.event;

  void _showRsvp() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('RSVP',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Going'),
                leading: const Icon(Icons.check_circle),
                onTap: () {
                  setState(() => e.rsvp = 'Going');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Maybe'),
                leading: const Icon(Icons.help),
                onTap: () {
                  setState(() => e.rsvp = 'Maybe');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Not Going'),
                leading: const Icon(Icons.cancel),
                onTap: () {
                  setState(() => e.rsvp = 'Not Going');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(e.name,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _row(Icons.calendar_today, _fmtDate(e.date)),
          _row(Icons.access_time, e.time.format(context)),
          _row(Icons.location_on, e.location),
          _row(Icons.people, '${e.attendees} attendees'),
          _row(Icons.attach_money,
              'Budget: \$${e.budget.toStringAsFixed(0)}'),
          _row(Icons.category, e.category),
          if (e.rsvp != null)
            _row(Icons.rsvp, 'RSVP: ${e.rsvp}'),
          const SizedBox(height: 16),
          Text(e.description,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _showRsvp,
                  child: const Text('RSVP'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditScreen(event: e),
                      ),
                    );
                    setState(() {});
                  },
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

// --- Add/Edit Screen ---

class AddEditScreen extends StatefulWidget {
  final Event? event;
  const AddEditScreen({super.key, this.event});
  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _budgetCtrl;
  late DateTime _date;
  late TimeOfDay _time;
  late String _category;
  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _nameCtrl =
        TextEditingController(text: e?.name ?? '');
    _locationCtrl =
        TextEditingController(text: e?.location ?? '');
    _descCtrl =
        TextEditingController(text: e?.description ?? '');
    _budgetCtrl = TextEditingController(
        text: e != null ? e.budget.toStringAsFixed(0) : '');
    _date = e?.date ?? DateTime.now();
    _time = e?.time ?? const TimeOfDay(hour: 12, minute: 0);
    _category = e?.category ?? 'Party';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  void _save() {
    if (_nameCtrl.text.isEmpty) return;
    if (_isEdit) {
      final e = widget.event!;
      e.name = _nameCtrl.text;
      e.location = _locationCtrl.text;
      e.description = _descCtrl.text;
      e.budget = double.tryParse(_budgetCtrl.text) ?? 0;
      e.date = _date;
      e.time = _time;
      e.category = _category;
      Navigator.pop(context);
    } else {
      final ev = Event(
        name: _nameCtrl.text,
        date: _date,
        time: _time,
        location: _locationCtrl.text,
        description: _descCtrl.text,
        attendees: 0,
        category: _category,
        budget: double.tryParse(_budgetCtrl.text) ?? 0,
      );
      Navigator.pop(context, ev);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit Event' : 'Add Event')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Event Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _budgetCtrl,
            decoration: const InputDecoration(
              labelText: 'Budget',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _pickDate,
            child: Text('Date: ${_fmtDate(_date)}'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _pickTime,
            child: Text('Time: ${_time.format(context)}'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Event'),
          ),
        ],
      ),
    );
  }
}

// --- Templates Screen ---

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: ListView.builder(
        itemCount: _templates.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, i) {
          final t = _templates[i];
          return Card(
            child: ListTile(
              title: Text(t['name']!),
              subtitle: Text(t['description']!),
              trailing: Chip(label: Text(t['category']!)),
            ),
          );
        },
      ),
    );
  }
}

// --- Helpers ---

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}
