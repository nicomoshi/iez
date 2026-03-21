import 'package:flutter/material.dart';

void main() => runApp(const QuoteBookApp());

class QuoteBookApp extends StatelessWidget {
  const QuoteBookApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quote Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const QuoteListPage(),
    );
  }
}

class Quote {
  final String text;
  final String author;
  final String category;
  bool isFavorite;
  Quote({required this.text, required this.author, required this.category, this.isFavorite = false});
}

class QuoteListPage extends StatefulWidget {
  const QuoteListPage({super.key});
  @override
  State<QuoteListPage> createState() => _QuoteListPageState();
}

class _QuoteListPageState extends State<QuoteListPage> {
  String _selectedCategory = 'All';
  final List<Quote> _quotes = [
    Quote(text: 'The only way to do great work is to love what you do.', author: 'Steve Jobs', category: 'Motivation'),
    Quote(text: 'Innovation distinguishes between a leader and a follower.', author: 'Steve Jobs', category: 'Innovation'),
    Quote(text: 'Stay hungry, stay foolish.', author: 'Steve Jobs', category: 'Motivation'),
    Quote(text: 'Life is what happens when you are busy making other plans.', author: 'John Lennon', category: 'Life'),
    Quote(text: 'The future belongs to those who believe in the beauty of their dreams.', author: 'Eleanor Roosevelt', category: 'Motivation'),
    Quote(text: 'It is during our darkest moments that we must focus to see the light.', author: 'Aristotle', category: 'Wisdom'),
    Quote(text: 'The only thing we have to fear is fear itself.', author: 'Franklin Roosevelt', category: 'Wisdom'),
    Quote(text: 'In the middle of difficulty lies opportunity.', author: 'Albert Einstein', category: 'Innovation'),
  ];

  List<String> get _categories => ['All', ...{..._quotes.map((q) => q.category)}];
  List<Quote> get _filteredQuotes =>
      _selectedCategory == 'All' ? _quotes : _quotes.where((q) => q.category == _selectedCategory).toList();
  List<Quote> get _favorites => _quotes.where((q) => q.isFavorite).toList();

  void _addQuote(String text, String author, String category) {
    setState(() => _quotes.add(Quote(text: text, author: author, category: category)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FavoritesPage(favorites: _favorites, onToggle: (q) {
                  setState(() => q.isFavorite = !q.isFavorite);
                }))),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(c),
                  selected: _selectedCategory == c,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredQuotes.length,
              itemBuilder: (_, i) {
                final q = _filteredQuotes[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(q.text, style: const TextStyle(fontStyle: FontStyle.italic)),
                    subtitle: Text('— ${q.author}  •  ${q.category}'),
                    trailing: IconButton(
                      icon: Icon(q.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: q.isFavorite ? Colors.red : null),
                      tooltip: q.isFavorite ? 'Unfavorite' : 'Favorite',
                      onPressed: () => setState(() => q.isFavorite = !q.isFavorite),
                    ),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => QuoteDetailPage(quote: q, onToggle: () {
                          setState(() => q.isFavorite = !q.isFavorite);
                        }))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Quote',
        onPressed: () async {
          final result = await Navigator.push<Map<String, String>>(context,
              MaterialPageRoute(builder: (_) => const AddQuotePage()));
          if (result != null) {
            _addQuote(result['text']!, result['author']!, result['category']!);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class QuoteDetailPage extends StatelessWidget {
  final Quote quote;
  final VoidCallback onToggle;
  const QuoteDetailPage({super.key, required this.quote, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Detail')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${quote.text}"',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            Text('— ${quote.author}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Chip(label: Text(quote.category)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onToggle,
                icon: Icon(quote.isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(quote.isFavorite ? 'Unfavorite' : 'Add to Favorites'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final List<Quote> favorites;
  final ValueChanged<Quote> onToggle;
  const FavoritesPage({super.key, required this.favorites, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (_, i) {
                final q = favorites[i];
                return ListTile(
                  title: Text(q.text, style: const TextStyle(fontStyle: FontStyle.italic)),
                  subtitle: Text('— ${q.author}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    tooltip: 'Remove',
                    onPressed: () => onToggle(q),
                  ),
                );
              },
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
  final _textCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  String _category = 'Motivation';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Quote')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(labelText: 'Quote text', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorCtrl,
              decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Motivation', 'Innovation', 'Life', 'Wisdom'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_textCtrl.text.isNotEmpty && _authorCtrl.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'text': _textCtrl.text,
                      'author': _authorCtrl.text,
                      'category': _category,
                    });
                  }
                },
                child: const Text('Save Quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
