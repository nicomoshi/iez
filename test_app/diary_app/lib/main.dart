import 'package:flutter/material.dart';

void main() {
  runApp(const DiaryApp());
}

// --- Data ---

enum Mood { happy, neutral, sad, excited, anxious }

extension MoodExt on Mood {
  String get emoji {
    switch (this) {
      case Mood.happy: return '😊';
      case Mood.neutral: return '😐';
      case Mood.sad: return '😢';
      case Mood.excited: return '🎉';
      case Mood.anxious: return '😰';
    }
  }
  String get label {
    switch (this) {
      case Mood.happy: return 'Happy';
      case Mood.neutral: return 'Neutral';
      case Mood.sad: return 'Sad';
      case Mood.excited: return 'Excited';
      case Mood.anxious: return 'Anxious';
    }
  }
}

class DiaryEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final Mood mood;
  final List<String> tags;
  final bool isFavorite;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.mood,
    this.tags = const [],
    this.isFavorite = false,
  });

  DiaryEntry copyWith({
    String? title,
    String? content,
    Mood? mood,
    List<String>? tags,
    bool? isFavorite,
  }) => DiaryEntry(
    id: id,
    date: date,
    title: title ?? this.title,
    content: content ?? this.content,
    mood: mood ?? this.mood,
    tags: tags ?? this.tags,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}

// --- State ---

class DiaryState extends ChangeNotifier {
  final List<DiaryEntry> _entries = [
    DiaryEntry(
      id: '1',
      date: DateTime.now().subtract(const Duration(days: 2)),
      title: 'Great morning run',
      content: 'Ran 5km in the park today. The weather was perfect and I felt energized afterwards.',
      mood: Mood.happy,
      tags: ['exercise', 'outdoor'],
    ),
    DiaryEntry(
      id: '2',
      date: DateTime.now().subtract(const Duration(days: 1)),
      title: 'Busy work day',
      content: 'Had back-to-back meetings all day. Managed to finish the project proposal though.',
      mood: Mood.neutral,
      tags: ['work'],
    ),
    DiaryEntry(
      id: '3',
      date: DateTime.now(),
      title: 'Weekend plans',
      content: 'Planning a hike with friends this Saturday. Need to pack snacks and water.',
      mood: Mood.excited,
      tags: ['social', 'outdoor'],
    ),
  ];

  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  List<DiaryEntry> get favorites => _entries.where((e) => e.isFavorite).toList();
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<DiaryEntry> get filteredEntries {
    if (_searchQuery.isEmpty) return entries;
    final q = _searchQuery.toLowerCase();
    return _entries.where((e) =>
      e.title.toLowerCase().contains(q) ||
      e.content.toLowerCase().contains(q) ||
      e.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  void setSearch(String q) { _searchQuery = q; notifyListeners(); }

  void addEntry(DiaryEntry entry) {
    _entries.insert(0, entry);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _entries[idx] = _entries[idx].copyWith(isFavorite: !_entries[idx].isFavorite);
      notifyListeners();
    }
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

// --- App ---

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaryApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const DiaryHome(),
    );
  }
}

class DiaryHome extends StatefulWidget {
  const DiaryHome({super.key});
  @override
  State<DiaryHome> createState() => _DiaryHomeState();
}

class _DiaryHomeState extends State<DiaryHome> {
  final _state = DiaryState();
  int _tab = 0;
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Search entries...', border: InputBorder.none),
                    onChanged: _state.setSearch,
                  )
                : Text(_tab == 0 ? 'My Diary' : _tab == 1 ? 'Favorites' : 'Stats'),
            actions: [
              if (_tab == 0)
                IconButton(
                  tooltip: _isSearching ? 'Close Search' : 'Search',
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _state.setSearch('');
                  }),
                ),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: _tab == 0
              ? FloatingActionButton(
                  tooltip: 'New Entry',
                  onPressed: () => _showNewEntryDialog(),
                  child: const Icon(Icons.edit),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() { _tab = i; _isSearching = false; _state.setSearch(''); }),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.book), label: 'Entries'),
              NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
              NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Stats'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0: return _buildEntriesList(_state.filteredEntries);
      case 1: return _buildEntriesList(_state.favorites);
      case 2: return _buildStatsTab();
      default: return const SizedBox();
    }
  }

  Widget _buildEntriesList(List<DiaryEntry> entries) {
    if (entries.isEmpty) {
      return Center(child: Text(_tab == 1 ? 'No favorites yet' : 'No entries found'));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: Key(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _state.deleteEntry(entry.id),
          child: ListTile(
            leading: Text(entry.mood.emoji, style: const TextStyle(fontSize: 28)),
            title: Text(entry.title),
            subtitle: Text(
              '${entry.date.day}/${entry.date.month}/${entry.date.year} • ${entry.tags.join(", ")}',
            ),
            trailing: IconButton(
              tooltip: 'Toggle Favorite',
              icon: Icon(entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: entry.isFavorite ? Colors.red : null),
              onPressed: () => _state.toggleFavorite(entry.id),
            ),
            onTap: () => _openEntry(entry),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    final moodCounts = <Mood, int>{};
    for (var e in _state.entries) {
      moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
    }
    final tagCounts = <String, int>{};
    for (var e in _state.entries) {
      for (var t in e.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mood Distribution', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ...Mood.values.map((m) {
            final count = moodCounts[m] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${m.emoji} ${m.label}', style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  Text('$count', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Text('Top Tags', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagCounts.entries.map((e) => Chip(
              label: Text('${e.key} (${e.value})'),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Text('Total entries: ${_state.entries.length}',
            style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  void _showNewEntryDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    Mood selectedMood = Mood.neutral;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New Entry', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(labelText: 'How was your day?'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagCtrl,
                decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
              ),
              const SizedBox(height: 16),
              Text('Mood:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: Mood.values.map((m) => GestureDetector(
                  onTap: () => setSheetState(() => selectedMood = m),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedMood == m ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(m.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    _state.addEntry(DiaryEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: DateTime.now(),
                      title: titleCtrl.text,
                      content: contentCtrl.text,
                      mood: selectedMood,
                      tags: tagCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEntry(DiaryEntry entry) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntryDetailScreen(entry: entry, state: _state),
    ));
  }
}

// --- Entry Detail ---

class EntryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;
  final DiaryState state;

  const EntryDetailScreen({super.key, required this.entry, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry'),
        actions: [
          IconButton(
            tooltip: 'Delete Entry',
            icon: const Icon(Icons.delete),
            onPressed: () {
              state.deleteEntry(entry.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.mood.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: Theme.of(context).textTheme.headlineSmall),
                      Text('${entry.date.day}/${entry.date.month}/${entry.date.year}',
                        style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(entry.content, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            if (entry.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.tags.map((t) => Chip(label: Text(t))).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
