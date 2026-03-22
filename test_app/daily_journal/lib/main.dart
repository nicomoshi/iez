import 'package:flutter/material.dart';

void main() {
  runApp(const DailyJournalApp());
}

// --- Models ---

enum Mood { happy, neutral, sad }

String moodEmoji(Mood m) {
  switch (m) {
    case Mood.happy:
      return 'Happy';
    case Mood.neutral:
      return 'Neutral';
    case Mood.sad:
      return 'Sad';
  }
}

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final Mood mood;
  final DateTime date;
  final String tag;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.date,
    this.tag = 'Personal',
  });
}

// --- State ---

class JournalState extends ChangeNotifier {
  final List<JournalEntry> _entries = [
    JournalEntry(
      id: '1',
      title: 'March 20',
      content:
          'Had a wonderful morning walk in the park. The cherry blossoms are starting to bloom and the air was crisp and fresh.',
      mood: Mood.happy,
      date: DateTime(2026, 3, 20),
      tag: 'Personal',
    ),
    JournalEntry(
      id: '2',
      title: 'March 19',
      content:
          'Busy day at the office. Finished the quarterly report and had a productive team meeting about the new project.',
      mood: Mood.neutral,
      date: DateTime(2026, 3, 19),
      tag: 'Work',
    ),
    JournalEntry(
      id: '3',
      title: 'March 18',
      content:
          'Feeling a bit under the weather today. Stayed in and read a good book. Sometimes rest is the best medicine.',
      mood: Mood.sad,
      date: DateTime(2026, 3, 18),
      tag: 'Personal',
    ),
    JournalEntry(
      id: '4',
      title: 'March 17',
      content:
          'Explored a new coffee shop downtown. The latte art was amazing and I discovered a cozy reading corner.',
      mood: Mood.happy,
      date: DateTime(2026, 3, 17),
      tag: 'Travel',
    ),
    JournalEntry(
      id: '5',
      title: 'March 16',
      content:
          'Wrapped up the client presentation. Got positive feedback from the team. Celebrated with dinner out.',
      mood: Mood.happy,
      date: DateTime(2026, 3, 16),
      tag: 'Work',
    ),
  ];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  void addEntry(JournalEntry entry) {
    _entries.insert(0, entry);
    notifyListeners();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  int get happyCount => _entries.where((e) => e.mood == Mood.happy).length;
  int get neutralCount => _entries.where((e) => e.mood == Mood.neutral).length;
  int get sadCount => _entries.where((e) => e.mood == Mood.sad).length;
}

// --- App ---

class DailyJournalApp extends StatelessWidget {
  const DailyJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

// --- Home Page with Bottom Nav ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final JournalState _state = JournalState();
  String _selectedTag = 'All';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Journal'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchPage(state: _state),
                    ),
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
                      MaterialPageRoute(
                        builder: (_) => NewEntryPage(state: _state),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Entry'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: 'Entries',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.mood_outlined),
                selectedIcon: Icon(Icons.mood),
                label: 'Moods',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildEntriesTab();
      case 1:
        return _buildCalendarTab();
      case 2:
        return _buildMoodsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEntriesTab() {
    final filtered = _selectedTag == 'All'
        ? _state.entries
        : _state.entries.where((e) => e.tag == _selectedTag).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: ['All', 'Personal', 'Work', 'Travel'].map((tag) {
              final selected = _selectedTag == tag;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedTag = tag),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No entries found'))
              : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return ListTile(
                      title: Text(entry.title),
                      subtitle: Text(
                        entry.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(moodEmoji(entry.mood)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EntryDetailPage(entry: entry, state: _state),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarTab() {
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              monthNames[now.month - 1],
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(d,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox.shrink();
              final day = index - firstWeekday + 1;
              final isToday = day == now.day;
              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: isToday
                      ? BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isToday
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moods',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _moodRow('Happy', _state.happyCount, Colors.green),
          const SizedBox(height: 12),
          _moodRow('Neutral', _state.neutralCount, Colors.amber),
          const SizedBox(height: 12),
          _moodRow('Sad', _state.sadCount, Colors.blue),
          const SizedBox(height: 32),
          Text(
            'Mood Trend',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _state.entries.reversed.map((e) {
                double height;
                Color color;
                switch (e.mood) {
                  case Mood.happy:
                    height = 80;
                    color = Colors.green;
                  case Mood.neutral:
                    height = 50;
                    color = Colors.amber;
                  case Mood.sad:
                    height = 25;
                    color = Colors.blue;
                }
                return Container(
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Text('$count', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

// --- Entry Detail Page ---

class EntryDetailPage extends StatelessWidget {
  final JournalEntry entry;
  final JournalState state;

  const EntryDetailPage({
    super.key,
    required this.entry,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entry Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Chip(label: Text(entry.tag)),
            const SizedBox(height: 24),
            Text('Content',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(entry.content),
            const SizedBox(height: 24),
            Text('Mood', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(moodEmoji(entry.mood),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  state.deleteEntry(entry.id);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- New Entry Page ---

class NewEntryPage extends StatefulWidget {
  final JournalState state;

  const NewEntryPage({super.key, required this.state});

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Mood _selectedMood = Mood.happy;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Mood>(
              value: _selectedMood,
              decoration: const InputDecoration(
                labelText: 'Mood',
                border: OutlineInputBorder(),
              ),
              items: Mood.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(moodEmoji(m)),
                );
              }).toList(),
              onChanged: (m) {
                if (m != null) setState(() => _selectedMood = m);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_titleController.text.isEmpty) return;
                  widget.state.addEntry(JournalEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _titleController.text,
                    content: _contentController.text,
                    mood: _selectedMood,
                    date: DateTime.now(),
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatefulWidget {
  final JournalState state;

  const SearchPage({super.key, required this.state});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<JournalEntry> _results = [];

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = [];
      } else {
        _results = widget.state.entries
            .where((e) =>
                e.title.toLowerCase().contains(query.toLowerCase()) ||
                e.content.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Entries')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Type to search entries'
                          : 'No results found',
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final entry = _results[index];
                      return ListTile(
                        title: Text(entry.title),
                        subtitle: Text(
                          entry.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
