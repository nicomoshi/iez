import 'package:flutter/material.dart';

void main() {
  runApp(const BookLibraryApp());
}

class Book {
  String title;
  String author;
  int rating;
  String shelf;
  String genre;
  int pages;
  String synopsis;

  Book({
    required this.title,
    required this.author,
    required this.rating,
    required this.shelf,
    required this.genre,
    required this.pages,
    required this.synopsis,
  });
}

class BookLibraryApp extends StatelessWidget {
  const BookLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Library',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Book> _books = [
    Book(
      title: 'Dune',
      author: 'Frank Herbert',
      rating: 5,
      shelf: 'Completed',
      genre: 'Sci-Fi',
      pages: 412,
      synopsis:
          'A science fiction masterpiece about politics, religion, and ecology on the desert planet Arrakis.',
    ),
    Book(
      title: '1984',
      author: 'George Orwell',
      rating: 4,
      shelf: 'Completed',
      genre: 'Dystopian',
      pages: 328,
      synopsis:
          'A dystopian novel set in a totalitarian society under constant surveillance.',
    ),
    Book(
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      rating: 5,
      shelf: 'Reading',
      genre: 'Sci-Fi',
      pages: 476,
      synopsis:
          'An astronaut wakes up alone on a spaceship with no memory, tasked with saving Earth.',
    ),
    Book(
      title: 'Atomic Habits',
      author: 'James Clear',
      rating: 4,
      shelf: 'Completed',
      genre: 'Self-Help',
      pages: 320,
      synopsis:
          'A practical guide to building good habits and breaking bad ones.',
    ),
    Book(
      title: 'The Hobbit',
      author: 'J.R.R. Tolkien',
      rating: 5,
      shelf: 'Favorites',
      genre: 'Fantasy',
      pages: 310,
      synopsis:
          'Bilbo Baggins embarks on an unexpected journey with a group of dwarves to reclaim their homeland.',
    ),
    Book(
      title: 'Clean Code',
      author: 'Robert Martin',
      rating: 3,
      shelf: 'Want to Read',
      genre: 'Technical',
      pages: 464,
      synopsis:
          'A handbook of agile software craftsmanship with principles for writing clean code.',
    ),
    Book(
      title: 'Sapiens',
      author: 'Yuval Harari',
      rating: 4,
      shelf: 'Reading',
      genre: 'History',
      pages: 443,
      synopsis:
          'A brief history of humankind from the Stone Age to the present.',
    ),
    Book(
      title: 'Neuromancer',
      author: 'William Gibson',
      rating: 4,
      shelf: 'Want to Read',
      genre: 'Sci-Fi',
      pages: 271,
      synopsis:
          'A washed-up hacker is hired for one last job in this pioneering cyberpunk novel.',
    ),
  ];

  String _selectedShelf = 'All';
  String _searchQuery = '';
  bool _showSearch = false;

  final List<String> _shelves = [
    'All',
    'Reading',
    'Completed',
    'Want to Read',
    'Favorites',
  ];

  List<Book> get _filteredBooks {
    var books = _books.toList();
    if (_selectedShelf != 'All') {
      books = books.where((b) => b.shelf == _selectedShelf).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      books = books
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q))
          .toList();
    }
    return books;
  }

  String _ratingStars(int rating) {
    return '${'★' * rating}${'☆' * (5 - rating)}';
  }

  void _openDetail(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          book: book,
          onMoveToShelf: (shelf) {
            setState(() => book.shelf = shelf);
          },
          onEdit: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditScreen(book: book),
              ),
            );
            setState(() {});
          },
        ),
      ),
    );
    setState(() {});
  }

  void _addBook() async {
    final newBook = Book(
      title: '',
      author: '',
      rating: 3,
      shelf: 'Want to Read',
      genre: '',
      pages: 0,
      synopsis: '',
    );
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditScreen(book: newBook, isNew: true),
      ),
    );
    if (saved == true) {
      setState(() => _books.add(newBook));
    }
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatsScreen(books: _books),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Book Library'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchQuery = '';
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'stats') _openStats();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'stats', child: Text('Stats')),
            ],
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
              children: _shelves.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(s),
                    selected: _selectedShelf == s,
                    onSelected: (_) => setState(() => _selectedShelf = s),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No books found'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final book = filtered[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(book.title),
                          subtitle: Text(
                            '${book.author}  ${_ratingStars(book.rating)}',
                          ),
                          trailing: Chip(label: Text(book.shelf)),
                          onTap: () => _openDetail(book),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        child: const Text('Add Book'),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final Book book;
  final ValueChanged<String> onMoveToShelf;
  final VoidCallback onEdit;

  const DetailScreen({
    super.key,
    required this.book,
    required this.onMoveToShelf,
    required this.onEdit,
  });

  String _ratingStars(int rating) {
    return '${'★' * rating}${'☆' * (5 - rating)}';
  }

  void _showShelfSheet(BuildContext context) {
    final shelves = ['Reading', 'Completed', 'Want to Read', 'Favorites'];
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Move to Shelf',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...shelves.map((s) => ListTile(
                title: Text(s),
                trailing: book.shelf == s ? const Icon(Icons.check) : null,
                onTap: () {
                  onMoveToShelf(s);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('by ${book.author}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Rating: ${_ratingStars(book.rating)}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Shelf: ${book.shelf}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Pages: ${book.pages}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Genre: ${book.genre}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Synopsis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(book.synopsis, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showShelfSheet(context),
                  child: const Text('Move to Shelf'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditScreen extends StatefulWidget {
  final Book book;
  final bool isNew;

  const EditScreen({super.key, required this.book, this.isNew = false});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _pagesCtrl;
  late TextEditingController _genreCtrl;
  late TextEditingController _synopsisCtrl;
  late String _shelf;
  late double _rating;

  final List<String> _shelves = [
    'Reading',
    'Completed',
    'Want to Read',
    'Favorites',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.book.title);
    _authorCtrl = TextEditingController(text: widget.book.author);
    _pagesCtrl = TextEditingController(text: widget.book.pages.toString());
    _genreCtrl = TextEditingController(text: widget.book.genre);
    _synopsisCtrl = TextEditingController(text: widget.book.synopsis);
    _shelf = widget.book.shelf;
    _rating = widget.book.rating.toDouble();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pagesCtrl.dispose();
    _genreCtrl.dispose();
    _synopsisCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.book.title = _titleCtrl.text;
    widget.book.author = _authorCtrl.text;
    widget.book.pages = int.tryParse(_pagesCtrl.text) ?? 0;
    widget.book.genre = _genreCtrl.text;
    widget.book.synopsis = _synopsisCtrl.text;
    widget.book.shelf = _shelf;
    widget.book.rating = _rating.round();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Add Book' : 'Edit Book'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorCtrl,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pagesCtrl,
              decoration: const InputDecoration(labelText: 'Pages'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genreCtrl,
              decoration: const InputDecoration(labelText: 'Genre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _synopsisCtrl,
              decoration: const InputDecoration(labelText: 'Synopsis'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _shelf,
              decoration: const InputDecoration(labelText: 'Shelf'),
              items: _shelves
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _shelf = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Rating: ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.round().toString(),
                    onChanged: (v) => setState(() => _rating = v),
                  ),
                ),
                Text('${_rating.round()}/5'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  final List<Book> books;

  const StatsScreen({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    final totalBooks = books.length;
    final totalPages = books.fold<int>(0, (sum, b) => sum + b.pages);
    final avgRating = books.isEmpty
        ? 0.0
        : books.fold<int>(0, (sum, b) => sum + b.rating) / books.length;

    final shelfCounts = <String, int>{};
    for (final b in books) {
      shelfCounts[b.shelf] = (shelfCounts[b.shelf] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Books: $totalBooks',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Total Pages: $totalPages',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Average Rating: ${avgRating.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            const Text('Books per Shelf',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...shelfCounts.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 16)),
                )),
          ],
        ),
      ),
    );
  }
}
