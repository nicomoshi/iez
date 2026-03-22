import 'package:flutter/material.dart';

void main() {
  runApp(const BookShelfApp());
}

class Book {
  final String title;
  final String author;
  final int pages;
  final String genre;
  final String status;
  final int currentPage;

  const Book({
    required this.title,
    required this.author,
    this.pages = 300,
    this.genre = 'Fiction',
    required this.status,
    this.currentPage = 0,
  });
}

class BookShelfApp extends StatelessWidget {
  const BookShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookShelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Book> _books = [
    const Book(title: 'Dune', author: 'Frank Herbert', pages: 412, genre: 'Fiction', status: 'reading', currentPage: 156),
    const Book(title: '1984', author: 'George Orwell', pages: 328, genre: 'Fiction', status: 'reading', currentPage: 89),
    const Book(title: 'Sapiens', author: 'Yuval Harari', pages: 443, genre: 'Non-Fiction', status: 'reading', currentPage: 210),
    const Book(title: 'The Hobbit', author: 'J.R.R. Tolkien', pages: 310, genre: 'Fiction', status: 'finished', currentPage: 310),
    const Book(title: 'Atomic Habits', author: 'James Clear', pages: 320, genre: 'Non-Fiction', status: 'finished', currentPage: 320),
    const Book(title: 'Project Hail Mary', author: 'Andy Weir', pages: 476, genre: 'Science', status: 'wishlist', currentPage: 0),
    const Book(title: 'Educated', author: 'Tara Westover', pages: 334, genre: 'Non-Fiction', status: 'wishlist', currentPage: 0),
  ];

  void _addBook(Book book) {
    setState(() {
      _books.add(book);
    });
  }

  void _deleteBook(Book book) {
    setState(() {
      _books.removeWhere((b) => b.title == book.title && b.author == book.author);
    });
  }

  @override
  Widget build(BuildContext context) {
    final readingBooks = _books.where((b) => b.status == 'reading').toList();
    final finishedBooks = _books.where((b) => b.status == 'finished').toList();
    final wishlistBooks = _books.where((b) => b.status == 'wishlist').toList();

    final pages = <Widget>[
      ReadingTab(
        books: readingBooks,
        onTapBook: (book) => _openDetail(book),
        onAddBook: () => _openAddBook(),
      ),
      FinishedTab(
        books: finishedBooks,
        onTapBook: (book) => _openDetail(book),
      ),
      WishlistTab(
        books: wishlistBooks,
        onTapBook: (book) => _openDetail(book),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookShelf'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchPage(books: _books)),
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
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Reading'),
          NavigationDestination(icon: Icon(Icons.check_circle), label: 'Finished'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Wishlist'),
        ],
      ),
    );
  }

  void _openDetail(Book book) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
    );
    if (deleted == true) {
      _deleteBook(book);
    }
  }

  void _openAddBook() async {
    final book = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => const AddBookPage()),
    );
    if (book != null) {
      _addBook(book);
    }
  }
}

class ReadingTab extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book> onTapBook;
  final VoidCallback onAddBook;

  const ReadingTab({
    super.key,
    required this.books,
    required this.onTapBook,
    required this.onAddBook,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return ListTile(
            title: Text(book.title),
            subtitle: Text(book.author),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTapBook(book),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddBook,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
    );
  }
}

class FinishedTab extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book> onTapBook;

  const FinishedTab({super.key, required this.books, required this.onTapBook});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Finished', style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.title),
                subtitle: Text(book.author),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTapBook(book),
              );
            },
          ),
        ),
      ],
    );
  }
}

class WishlistTab extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book> onTapBook;

  const WishlistTab({super.key, required this.books, required this.onTapBook});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Wishlist', style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.title),
                subtitle: Text(book.author),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTapBook(book),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BookDetailPage extends StatelessWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text('Author', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(book.author, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('Pages', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${book.pages} pages', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('Progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Page ${book.currentPage} of ${book.pages}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: book.pages > 0 ? book.currentPage / book.pages : 0,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete),
                label: const Text('Delete Book'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  String _selectedGenre = 'Fiction';

  final _genres = ['Fiction', 'Non-Fiction', 'Science', 'History'];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Pages',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              decoration: const InputDecoration(
                labelText: 'Genre',
                border: OutlineInputBorder(),
              ),
              items: _genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedGenre = v);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBook,
                child: const Text('Save Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBook() {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty) return;
    final pages = int.tryParse(_pagesController.text) ?? 300;
    Navigator.pop(
      context,
      Book(
        title: _titleController.text,
        author: _authorController.text,
        pages: pages,
        genre: _selectedGenre,
        status: 'reading',
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<Book> books;

  const SearchPage({super.key, required this.books});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final _filters = ['All', 'Fiction', 'Non-Fiction', 'Science'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> get _filteredBooks {
    var books = widget.books;
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      books = books.where((b) =>
          b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query)).toList();
    }
    if (_selectedFilter != 'All') {
      books = books.where((b) => b.genre == _selectedFilter).toList();
    }
    return books;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: _filters.map((f) {
                return FilterChip(
                  label: Text(f),
                  selected: _selectedFilter == f,
                  onSelected: (_) => setState(() => _selectedFilter = f),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                final book = _filteredBooks[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text('${book.author} - ${book.genre}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
