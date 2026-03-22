import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SleepTrackerApp());
}

class SleepEntry {
  final DateTime date;
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  final String quality;

  SleepEntry({
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    required this.quality,
  });

  String get durationString {
    int bedMinutes = bedtime.hour * 60 + bedtime.minute;
    int wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    if (wakeMinutes <= bedMinutes) wakeMinutes += 24 * 60;
    int total = wakeMinutes - bedMinutes;
    int h = total ~/ 60;
    int m = total % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  double get durationHours {
    int bedMinutes = bedtime.hour * 60 + bedtime.minute;
    int wakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    if (wakeMinutes <= bedMinutes) wakeMinutes += 24 * 60;
    return (wakeMinutes - bedMinutes) / 60.0;
  }

  String get bedtimeString {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, bedtime.hour, bedtime.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String get dateTitle => DateFormat('MMMM d').format(date);
}

class SleepTrackerApp extends StatefulWidget {
  const SleepTrackerApp({super.key});

  @override
  State<SleepTrackerApp> createState() => _SleepTrackerAppState();
}

class _SleepTrackerAppState extends State<SleepTrackerApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: _darkMode ? Brightness.dark : Brightness.light,
      ),
      home: HomePage(
        darkMode: _darkMode,
        onDarkModeChanged: (v) => setState(() => _darkMode = v),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const HomePage({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _sleepReminders = true;
  bool _trackNaps = false;

  final List<SleepEntry> _entries = [
    SleepEntry(
      date: DateTime(2026, 3, 20),
      bedtime: const TimeOfDay(hour: 23, minute: 0),
      wakeTime: const TimeOfDay(hour: 6, minute: 30),
      quality: 'Good',
    ),
    SleepEntry(
      date: DateTime(2026, 3, 19),
      bedtime: const TimeOfDay(hour: 22, minute: 30),
      wakeTime: const TimeOfDay(hour: 7, minute: 0),
      quality: 'Excellent',
    ),
    SleepEntry(
      date: DateTime(2026, 3, 18),
      bedtime: const TimeOfDay(hour: 0, minute: 15),
      wakeTime: const TimeOfDay(hour: 6, minute: 45),
      quality: 'Fair',
    ),
    SleepEntry(
      date: DateTime(2026, 3, 17),
      bedtime: const TimeOfDay(hour: 23, minute: 45),
      wakeTime: const TimeOfDay(hour: 7, minute: 15),
      quality: 'Good',
    ),
    SleepEntry(
      date: DateTime(2026, 3, 16),
      bedtime: const TimeOfDay(hour: 22, minute: 0),
      wakeTime: const TimeOfDay(hour: 6, minute: 0),
      quality: 'Excellent',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchPage(entries: _entries)),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bedtime), label: 'Log'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildLogTab();
      case 1:
        return _buildStatsTab();
      case 2:
        return _buildSettingsTab();
      default:
        return _buildLogTab();
    }
  }

  Widget _buildLogTab() {
    if (_entries.isEmpty) {
      return const Center(child: Text('No sleep entries yet'));
    }
    return ListView.builder(
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return ListTile(
          title: Text(entry.dateTitle),
          subtitle: Text('${entry.durationString} · Slept at ${entry.bedtimeString}'),
          trailing: Chip(label: Text(entry.quality)),
          onTap: () async {
            final deleted = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => SleepDetailPage(entry: entry),
              ),
            );
            if (deleted == true) {
              setState(() => _entries.removeAt(index));
            }
          },
        );
      },
    );
  }

  Widget _buildStatsTab() {
    double avg = 0;
    double best = 0;
    String bestDate = '';
    if (_entries.isNotEmpty) {
      double total = 0;
      for (final e in _entries) {
        final h = e.durationHours;
        total += h;
        if (h > best) {
          best = h;
          bestDate = e.dateTitle;
        }
      }
      avg = total / _entries.length;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Stats', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.nights_stay),
            title: const Text('Average Sleep'),
            subtitle: Text('${avg.toStringAsFixed(1)} hours per night'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Best Night'),
            subtitle: Text('${best.toStringAsFixed(1)} hours on $bestDate'),
          ),
        ),
        const SizedBox(height: 16),
        Text('Weekly Summary', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_entries.length} nights logged'),
                const SizedBox(height: 4),
                Text('Total: ${(_entries.fold<double>(0, (s, e) => s + e.durationHours)).toStringAsFixed(1)} hours'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Sleep Reminders'),
          subtitle: const Text('Get notified at bedtime'),
          value: _sleepReminders,
          onChanged: (v) => setState(() => _sleepReminders = v),
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme'),
          value: widget.darkMode,
          onChanged: widget.onDarkModeChanged,
        ),
        SwitchListTile(
          title: const Text('Track Naps'),
          subtitle: const Text('Log daytime naps'),
          value: _trackNaps,
          onChanged: (v) => setState(() => _trackNaps = v),
        ),
      ],
    );
  }

  void _addEntry() async {
    final result = await Navigator.push<SleepEntry>(
      context,
      MaterialPageRoute(builder: (_) => const AddEntryPage()),
    );
    if (result != null) {
      setState(() => _entries.insert(0, result));
    }
  }
}

class SleepDetailPage extends StatelessWidget {
  final SleepEntry entry;

  const SleepDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(entry.dateTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Text('Duration', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.durationString, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Bedtime: ${entry.bedtimeString}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Quality', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(entry.quality, style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Entry'),
          ),
        ],
      ),
    );
  }
}

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  String _quality = 'Good';

  final _qualities = ['Excellent', 'Good', 'Fair', 'Poor'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: DateFormat('MMMM d, yyyy').format(_date),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Bedtime',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: _bedtime.format(context),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _bedtime,
                );
                if (picked != null) setState(() => _bedtime = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Wake Time',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              controller: TextEditingController(
                text: _wakeTime.format(context),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _wakeTime,
                );
                if (picked != null) setState(() => _wakeTime = picked);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Quality',
                border: OutlineInputBorder(),
              ),
              value: _quality,
              items: _qualities
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _quality = v);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveEntry,
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    Navigator.pop(
      context,
      SleepEntry(
        date: _date,
        bedtime: _bedtime,
        wakeTime: _wakeTime,
        quality: _quality,
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<SleepEntry> entries;

  const SearchPage({super.key, required this.entries});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.entries
        .where((e) =>
            e.dateTitle.toLowerCase().contains(_query.toLowerCase()) ||
            e.quality.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search Entries')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final entry = filtered[index];
                return ListTile(
                  title: Text(entry.dateTitle),
                  subtitle: Text('${entry.durationString} · ${entry.quality}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
