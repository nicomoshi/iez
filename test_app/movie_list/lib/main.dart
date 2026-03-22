import 'package:flutter/material.dart';

void main() {
  runApp(const MovieListApp());
}

class Movie {
  final String title;
  final String genre;
  final int year;
  final double rating;
  final String notes;
  final bool watched;

  const Movie({
    required this.title,
    required this.genre,
    required this.year,
    this.rating = 0.0,
    this.notes = '',
    this.watched = false,
  });

  Movie copyWith({
    String? title,
    String? genre,
    int? year,
    double? rating,
    String? notes,
    bool? watched,
  }) {
    return Movie(
      title: title ?? this.title,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      watched: watched ?? this.watched,
    );
  }
}

class MovieListApp extends StatelessWidget {
  const MovieListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieList',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
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

  final List<Movie> _watchlist = [
    const Movie(title: 'Inception', genre: 'Sci-Fi', year: 2010, rating: 4.5),
    const Movie(title: 'The Matrix', genre: 'Sci-Fi', year: 1999, rating: 4.0),
    const Movie(
        title: 'Parasite', genre: 'Thriller', year: 2019, rating: 4.8),
    const Movie(
        title: 'Spirited Away', genre: 'Animation', year: 2001, rating: 4.7),
  ];

  final List<Movie> _watched = [
    const Movie(
        title: 'The Godfather',
        genre: 'Drama',
        year: 1972,
        rating: 5.0,
        watched: true),
    const Movie(
        title: 'Pulp Fiction',
        genre: 'Drama',
        year: 1994,
        rating: 4.5,
        watched: true),
  ];

  String _activeFilter = 'All';

  List<Movie> get _filteredWatchlist {
    if (_activeFilter == 'All') return _watchlist;
    return _watchlist.where((m) => m.genre == _activeFilter).toList();
  }

  void _addMovie(Movie movie) {
    setState(() {
      _watchlist.add(movie);
    });
  }

  void _deleteMovie(Movie movie) {
    setState(() {
      _watchlist.removeWhere((m) => m.title == movie.title);
      _watched.removeWhere((m) => m.title == movie.title);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieList'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(
                    movies: [..._watchlist, ..._watched],
                    onDelete: _deleteMovie,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final movie = await Navigator.push<Movie>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMoviePage()),
                );
                if (movie != null) _addMovie(movie);
              },
              label: const Text('Add Movie'),
              icon: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            label: 'Watched',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildWatchlistTab();
      case 1:
        return _buildWatchedTab();
      case 2:
        return _buildDiscoverTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWatchlistTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: ['All', 'Sci-Fi', 'Thriller', 'Animation']
                .map((filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: _activeFilter == filter,
                        onSelected: (selected) {
                          setState(() {
                            _activeFilter = selected ? filter : 'All';
                          });
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: _filteredWatchlist.isEmpty
              ? const Center(child: Text('No movies found'))
              : ListView.builder(
                  itemCount: _filteredWatchlist.length,
                  itemBuilder: (context, index) {
                    final movie = _filteredWatchlist[index];
                    return ListTile(
                      title: Text(movie.title),
                      subtitle: Text('${movie.genre} - ${movie.year}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final deleted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovieDetailPage(movie: movie),
                          ),
                        );
                        if (deleted == true) _deleteMovie(movie);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWatchedTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Watched',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _watched.length,
            itemBuilder: (context, index) {
              final movie = _watched[index];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(movie.title),
                subtitle: Text('${movie.genre} - ${movie.year}'),
                onTap: () async {
                  final deleted = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailPage(movie: movie),
                    ),
                  );
                  if (deleted == true) _deleteMovie(movie);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Discover',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Trending',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _discoverCard('Oppenheimer', '2023'),
                _discoverCard('Barbie', '2023'),
                _discoverCard('Dune: Part Two', '2024'),
                _discoverCard('Poor Things', '2023'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Top Rated',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _discoverCard('The Shawshank Redemption', '1994'),
                _discoverCard('Schindler\'s List', '1993'),
                _discoverCard('12 Angry Men', '1957'),
                _discoverCard('The Dark Knight', '2008'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _discoverCard(String title, String year) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 140,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(),
              const Icon(Icons.movie, size: 40, color: Colors.deepPurple),
              const Spacer(),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              Text(year, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class MovieDetailPage extends StatelessWidget {
  final Movie movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movie.title,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _detailRow('Genre', movie.genre),
            const Divider(),
            _detailRow('Year', movie.year.toString()),
            const Divider(),
            _detailRow('Rating', '${movie.rating}/5.0'),
            const Divider(),
            _detailRow(
                'Notes', movie.notes.isEmpty ? 'No notes' : movie.notes),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Movie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class AddMoviePage extends StatefulWidget {
  const AddMoviePage({super.key});

  @override
  State<AddMoviePage> createState() => _AddMoviePageState();
}

class _AddMoviePageState extends State<AddMoviePage> {
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  String _selectedGenre = 'Sci-Fi';
  double _rating = 3.0;

  final List<String> _genres = [
    'Sci-Fi',
    'Thriller',
    'Animation',
    'Drama',
    'Comedy',
    'Horror',
    'Action',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Movie'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Movie Title',
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
              items: _genres
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedGenre = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text('Rating: ${_rating.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 16)),
            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 10,
              label: _rating.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _rating = value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.isEmpty) return;
                  final movie = Movie(
                    title: _titleController.text,
                    genre: _selectedGenre,
                    year: int.tryParse(_yearController.text) ??
                        DateTime.now().year,
                    rating: _rating,
                  );
                  Navigator.pop(context, movie);
                },
                child: const Text('Save Movie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie) onDelete;

  const SearchPage(
      {super.key, required this.movies, required this.onDelete});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<Movie> _results = [];

  @override
  void initState() {
    super.initState();
    _results = widget.movies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = widget.movies;
      } else {
        _results = widget.movies
            .where(
                (m) => m.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Movies'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Movies',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final movie = _results[index];
                return ListTile(
                  title: Text(movie.title),
                  subtitle: Text('${movie.genre} - ${movie.year}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
