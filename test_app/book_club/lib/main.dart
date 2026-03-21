import 'package:flutter/material.dart';

void main() {
  runApp(const BookClubApp());
}

// --- Data Model ---

enum Genre { fiction, nonFiction, mystery, sciFi, biography }

String genreLabel(Genre g) {
  switch (g) {
    case Genre.fiction:
      return 'Fiction';
    case Genre.nonFiction:
      return 'Non-Fiction';
    case Genre.mystery:
      return 'Mystery';
    case Genre.sciFi:
      return 'Sci-Fi';
    case Genre.biography:
      return 'Biography';
  }
}

class Book {
  String title;
  String author;
  Genre genre;
  int pages;
  int currentPage;
  int rating;
  String review;
  bool isFinished;

  Book({
    required this.title,
    required this.author,
    required this.genre,
    required this.pages,
    this.currentPage = 0,
    this.rating = 3,
    this.review = '',
    this.isFinished = false,
  });

  double get progress => pages > 0 ? currentPage / pages : 0.0;
  int get progressPercent => (progress * 100).round();
}

// --- App ---

class BookClubApp extends StatelessWidget {
  const BookClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- State ---

final List<Book> _books = [
  Book(
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
    genre: Genre.fiction,
    pages: 180,
    currentPage: 180,
    rating: 5,
    review: 'A masterpiece of American literature.',
    isFinished: true,
  ),
  Book(
    title: 'Dune',
    author: 'Frank Herbert',
    genre: Genre.sciFi,
    pages: 412,
    currentPage: 250,
    rating: 4,
    review: 'Epic world-building and political intrigue.',
  ),
  Book(
    title: 'Sapiens',
    author: 'Yuval Noah Harari',
    genre: Genre.nonFiction,
    pages: 443,
    currentPage: 100,
    rating: 4,
    review: 'Fascinating history of humankind.',
  ),
  Book(
    title: 'Gone Girl',
    author: 'Gillian Flynn',
    genre: Genre.mystery,
    pages: 432,
    currentPage: 432,
    rating: 4,
    review: 'Twisted and gripping thriller.',
    isFinished: true,
  ),
  Book(
    title: 'Steve Jobs',
    author: 'Walter Isaacson',
    genre: Genre.biography,
    pages: 656,
    currentPage: 320,
    rating: 3,
    review: 'Detailed portrait of a tech visionary.',
  ),
  Book(
    title: 'Neuromancer',
    author: 'William Gibson',
    genre: Genre.sciFi,
    pages: 271,
    currentPage: 50,
    rating: 3,
    review: 'The birth of cyberpunk.',
  ),
];

// --- HomeScreen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedGenre = 'All';

  List<Book> get _filteredBooks {
    if (_selectedGenre == 'All') return _books;
    return _books.where((b) => genreLabel(b.genre) == _selectedGenre).toList();
  }

  String _starsString(int rating) {
    return List.generate(5, (i) => i < rating ? '\u2605' : '\u2606').join();
  }

  @override
  Widget build(BuildContext context) {
    final genres = ['All', 'Fiction', 'Non-Fiction', 'Mystery', 'Sci-Fi', 'Biography'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Club'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Genres') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GenresScreen()));
              } else if (value == 'Reading Stats') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingStatsScreen()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'Genres', child: Text('Genres')),
              const PopupMenuItem(value: 'Reading Stats', child: Text('Reading Stats')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: genres.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(g),
                    selected: _selectedGenre == g,
                    onSelected: (_) => setState(() => _selectedGenre = g),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filteredBooks.isEmpty
                ? const Center(child: Text('No books found.'))
                : ListView.builder(
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(book.title),
                          subtitle: Text(book.author),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${book.progressPercent}%'),
                              Text(
                                _starsString(book.rating),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookScreen()),
          );
          setState(() {});
        },
        label: const Text('Add Book'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- DetailScreen ---

class DetailScreen extends StatefulWidget {
  final Book book;
  const DetailScreen({super.key, required this.book});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String _starsString(int rating) {
    return List.generate(5, (i) => i < rating ? '\u2605' : '\u2606').join();
  }

  void _updateProgress() {
    final controller = TextEditingController(text: widget.book.currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Current Page'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? widget.book.currentPage;
              setState(() {
                widget.book.currentPage = val.clamp(0, widget.book.pages);
                if (widget.book.currentPage >= widget.book.pages) {
                  widget.book.isFinished = true;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _markComplete() {
    setState(() {
      widget.book.currentPage = widget.book.pages;
      widget.book.isFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(book.author, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Chip(label: Text(genreLabel(book.genre))),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: book.progress),
            const SizedBox(height: 8),
            Text('${book.currentPage} of ${book.pages} pages read'),
            const SizedBox(height: 16),
            Text(
              _starsString(book.rating),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            if (book.review.isNotEmpty) ...[
              Text('Review', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(book.review),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProgress,
                    child: const Text('Update Progress'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: book.isFinished ? null : _markComplete,
                    child: const Text('Mark Complete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- AddBookScreen ---

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();
  Genre _genre = Genre.fiction;
  double _rating = 3;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pagesCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _books.add(Book(
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
      genre: _genre,
      pages: int.tryParse(_pagesCtrl.text.trim()) ?? 100,
      rating: _rating.round(),
      review: _reviewCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Book Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _authorCtrl,
                decoration: const InputDecoration(labelText: 'Author'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pagesCtrl,
                decoration: const InputDecoration(labelText: 'Total Pages'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Genre>(
                value: _genre,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: Genre.values.map((g) {
                  return DropdownMenuItem(value: g, child: Text(genreLabel(g)));
                }).toList(),
                onChanged: (v) => setState(() => _genre = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reviewCtrl,
                decoration: const InputDecoration(labelText: 'Review'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text('Rating: ${_rating.round()}'),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.round().toString(),
                onChanged: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Add Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- GenresScreen ---

class GenresScreen extends StatelessWidget {
  const GenresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genres')),
      body: ListView(
        children: Genre.values.map((g) {
          final count = _books.where((b) => b.genre == g).length;
          return ListTile(
            title: Text(genreLabel(g)),
            trailing: Text('$count book${count == 1 ? '' : 's'}'),
          );
        }).toList(),
      ),
    );
  }
}

// --- ReadingStatsScreen ---

class ReadingStatsScreen extends StatelessWidget {
  const ReadingStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final totalBooks = _books.length;
    final finishedCount = _books.where((b) => b.isFinished).length;
    final totalPagesRead = _books.fold<int>(0, (sum, b) => sum + b.currentPage);
    final avgRating = _books.isEmpty
        ? 0.0
        : _books.fold<int>(0, (sum, b) => sum + b.rating) / _books.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Reading Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCard(label: 'Total Books', value: '$totalBooks'),
            _StatCard(label: 'Finished', value: '$finishedCount'),
            _StatCard(label: 'Total Pages Read', value: '$totalPagesRead'),
            _StatCard(label: 'Average Rating', value: avgRating.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
