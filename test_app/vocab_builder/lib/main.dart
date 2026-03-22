import 'package:flutter/material.dart';

void main() {
  runApp(const VocabBuilderApp());
}

class VocabBuilderApp extends StatelessWidget {
  const VocabBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocabBuilder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class VocabWord {
  final String word;
  final String definition;
  final String example;
  final String partOfSpeech;

  const VocabWord({
    required this.word,
    required this.definition,
    this.example = '',
    this.partOfSpeech = 'Noun',
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<VocabWord> _words = [
    const VocabWord(
      word: 'Ephemeral',
      definition: 'Lasting for a very short time',
      example: 'The ephemeral beauty of cherry blossoms.',
      partOfSpeech: 'Adjective',
    ),
    const VocabWord(
      word: 'Ubiquitous',
      definition: 'Present everywhere',
      example: 'Smartphones have become ubiquitous in modern life.',
      partOfSpeech: 'Adjective',
    ),
    const VocabWord(
      word: 'Serendipity',
      definition: 'Happy accident',
      example: 'Finding that book was pure serendipity.',
      partOfSpeech: 'Noun',
    ),
    const VocabWord(
      word: 'Eloquent',
      definition: 'Fluent and persuasive',
      example: 'She gave an eloquent speech at the ceremony.',
      partOfSpeech: 'Adjective',
    ),
  ];

  void _addWord(VocabWord word) {
    setState(() {
      _words.add(word);
    });
  }

  void _deleteWord(VocabWord word) {
    setState(() {
      _words.removeWhere((w) => w.word == word.word);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      WordsTab(
        words: _words,
        onAdd: _addWord,
        onDelete: _deleteWord,
      ),
      const QuizTab(),
      const ProgressTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('VocabBuilder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchPage(words: _words)),
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Words',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

// --- Words Tab ---

class WordsTab extends StatelessWidget {
  final List<VocabWord> words;
  final void Function(VocabWord) onAdd;
  final void Function(VocabWord) onDelete;

  const WordsTab({
    super.key,
    required this.words,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: words.isEmpty
          ? const Center(child: Text('No words yet. Add some!'))
          : ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                return ListTile(
                  title: Text(word.word),
                  subtitle: Text(
                    word.definition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WordDetailPage(
                          word: word,
                          onDelete: onDelete,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<VocabWord>(
            context,
            MaterialPageRoute(builder: (_) => const AddWordPage()),
          );
          if (result != null) {
            onAdd(result);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Word'),
      ),
    );
  }
}

// --- Word Detail Page ---

class WordDetailPage extends StatelessWidget {
  final VocabWord word;
  final void Function(VocabWord) onDelete;

  const WordDetailPage({
    super.key,
    required this.word,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Definition',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              word.definition,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Example',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              word.example.isNotEmpty ? word.example : 'No example provided.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Part of Speech',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Chip(label: Text(word.partOfSpeech)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onDelete(word);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Word'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// --- Add Word Page ---

class AddWordPage extends StatefulWidget {
  const AddWordPage({super.key});

  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final _wordController = TextEditingController();
  final _definitionController = TextEditingController();
  final _exampleController = TextEditingController();
  String _selectedPartOfSpeech = 'Noun';

  final List<String> _partsOfSpeech = [
    'Noun',
    'Verb',
    'Adjective',
    'Adverb',
  ];

  @override
  void dispose() {
    _wordController.dispose();
    _definitionController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Word'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: 'Word',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _definitionController,
              decoration: const InputDecoration(
                labelText: 'Definition',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _exampleController,
              decoration: const InputDecoration(
                labelText: 'Example Sentence',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPartOfSpeech,
              decoration: const InputDecoration(
                labelText: 'Part of Speech',
                border: OutlineInputBorder(),
              ),
              items: _partsOfSpeech.map((pos) {
                return DropdownMenuItem(value: pos, child: Text(pos));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPartOfSpeech = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_wordController.text.isNotEmpty &&
                    _definitionController.text.isNotEmpty) {
                  Navigator.pop(
                    context,
                    VocabWord(
                      word: _wordController.text,
                      definition: _definitionController.text,
                      example: _exampleController.text,
                      partOfSpeech: _selectedPartOfSpeech,
                    ),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save Word'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Quiz Tab ---

class QuizTab extends StatelessWidget {
  const QuizTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quiz',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Start Quiz'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Daily Challenge'),
              subtitle: const Text('Test your knowledge with today\'s words'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department,
                  color: Colors.orange),
              title: const Text('Best Streak'),
              trailing: const Text(
                '5 days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Progress Tab ---

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Progress',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _StatCard(
            icon: Icons.school,
            iconColor: Colors.blue,
            label: 'Words Learned',
            value: '24',
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.star,
            iconColor: Colors.amber,
            label: 'Mastered',
            value: '12',
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.refresh,
            iconColor: Colors.red,
            label: 'Review Needed',
            value: '8',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
  final List<VocabWord> words;

  const SearchPage({super.key, required this.words});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<VocabWord> _results = [];

  @override
  void initState() {
    super.initState();
    _results = widget.words;
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = widget.words;
      } else {
        _results = widget.words
            .where((w) =>
                w.word.toLowerCase().contains(query.toLowerCase()) ||
                w.definition.toLowerCase().contains(query.toLowerCase()))
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
      appBar: AppBar(
        title: const Text('Search Words'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                ? const Center(child: Text('No results found.'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final word = _results[index];
                      return ListTile(
                        title: Text(word.word),
                        subtitle: Text(word.definition),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
