import 'package:flutter/material.dart';

void main() {
  runApp(const QuoteWallApp());
}

class Quote {
  final String text;
  final String author;
  final String source;
  final List<String> tags;

  const Quote({
    required this.text,
    required this.author,
    this.source = '',
    this.tags = const [],
  });
}

class QuoteWallApp extends StatelessWidget {
  const QuoteWallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuoteWall',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Quote> _quotes = [
    const Quote(
      text: 'The only way to do great work is to love what you do.',
      author: 'Steve Jobs',
      source: 'Stanford Commencement Speech',
      tags: ['Inspiration', 'Success'],
    ),
    const Quote(
      text: 'Be yourself; everyone else is taken.',
      author: 'Oscar Wilde',
      source: 'Attributed',
      tags: ['Life', 'Wisdom'],
    ),
    const Quote(
      text: 'In the middle of difficulty lies opportunity.',
      author: 'Albert Einstein',
      source: 'Letters',
      tags: ['Inspiration', 'Wisdom'],
    ),
    const Quote(
      text: 'Stay hungry, stay foolish.',
      author: 'Steve Jobs',
      source: 'Stanford Commencement Speech',
      tags: ['Inspiration', 'Life'],
    ),
  ];

  void _addQuote(Quote quote) {
    setState(() {
      _quotes.add(quote);
    });
  }

  void _deleteQuote(Quote quote) {
    setState(() {
      _quotes.remove(quote);
    });
  }

  Map<String, int> get _authorCounts {
    final counts = <String, int>{};
    for (final q in _quotes) {
      counts[q.author] = (counts[q.author] ?? 0) + 1;
    }
    return counts;
  }

  Set<String> get _allTags {
    final tags = <String>{};
    for (final q in _quotes) {
      tags.addAll(q.tags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _QuotesTab(
        quotes: _quotes,
        onAddQuote: _addQuote,
        onDeleteQuote: _deleteQuote,
      ),
      _AuthorsTab(authorCounts: _authorCounts),
      _TagsTab(tags: _allTags),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuoteWall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(quotes: _quotes),
                ),
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.format_quote), label: 'Quotes'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Authors'),
          NavigationDestination(icon: Icon(Icons.label), label: 'Tags'),
        ],
      ),
    );
  }
}

class _QuotesTab extends StatelessWidget {
  final List<Quote> quotes;
  final ValueChanged<Quote> onAddQuote;
  final ValueChanged<Quote> onDeleteQuote;

  const _QuotesTab({
    required this.quotes,
    required this.onAddQuote,
    required this.onDeleteQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: quotes.length,
        itemBuilder: (context, index) {
          final quote = quotes[index];
          return ListTile(
            title: Text(
              quote.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(quote.author),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuoteDetailPage(
                    quote: quote,
                    onDelete: () {
                      onDeleteQuote(quote);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Quote>(
            context,
            MaterialPageRoute(builder: (_) => const AddQuotePage()),
          );
          if (result != null) {
            onAddQuote(result);
          }
        },
        label: const Text('Add Quote'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _AuthorsTab extends StatelessWidget {
  final Map<String, int> authorCounts;

  const _AuthorsTab({required this.authorCounts});

  @override
  Widget build(BuildContext context) {
    final authors = authorCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Authors',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        ...authors.map((entry) => ListTile(
              title: Text(entry.key),
              subtitle: Text(
                '${entry.value} ${entry.value == 1 ? 'quote' : 'quotes'}',
              ),
              leading: const CircleAvatar(child: Icon(Icons.person)),
            )),
      ],
    );
  }
}

class _TagsTab extends StatelessWidget {
  final Set<String> tags;

  const _TagsTab({required this.tags});

  @override
  Widget build(BuildContext context) {
    final sorted = tags.toList()..sort();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Tags',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorted
                .map((tag) => Chip(label: Text(tag)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class QuoteDetailPage extends StatelessWidget {
  final Quote quote;
  final VoidCallback onDelete;

  const QuoteDetailPage({
    super.key,
    required this.quote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                quote.text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Author', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(quote.author, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text('Source', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            quote.source.isNotEmpty ? quote.source : 'Unknown',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Tags', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quote.tags.map((t) => Chip(label: Text(t))).toList(),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            label: const Text('Delete Quote'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class AddQuotePage extends StatefulWidget {
  const AddQuotePage({super.key});

  @override
  State<AddQuotePage> createState() => _AddQuotePageState();
}

class _AddQuotePageState extends State<AddQuotePage> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();
  final _authorController = TextEditingController();
  final _sourceController = TextEditingController();

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Quote')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _quoteController,
              decoration: const InputDecoration(
                labelText: 'Quote Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter a quote' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter an author' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    Quote(
                      text: _quoteController.text,
                      author: _authorController.text,
                      source: _sourceController.text,
                    ),
                  );
                }
              },
              child: const Text('Save Quote'),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<Quote> quotes;

  const SearchPage({super.key, required this.quotes});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query = '';

  List<Quote> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return widget.quotes
        .where((quote) =>
            quote.text.toLowerCase().contains(q) ||
            quote.author.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Quotes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
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
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final quote = _results[index];
                return ListTile(
                  title: Text(
                    quote.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(quote.author),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
