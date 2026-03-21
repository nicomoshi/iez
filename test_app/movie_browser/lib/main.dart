import 'package:flutter/material.dart';

void main() => runApp(const MovieBrowserApp());

class MovieBrowserApp extends StatelessWidget {
  const MovieBrowserApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const MovieHome(),
    );
  }
}

class Movie {
  final String title;
  final String genre;
  final int year;
  final double rating;
  final String director;
  final String synopsis;
  bool inWatchlist;
  Movie({
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    required this.director,
    required this.synopsis,
    this.inWatchlist = false,
  });
}

final List<Movie> _allMovies = [
  Movie(title: 'The Matrix', genre: 'Sci-Fi', year: 1999, rating: 8.7, director: 'Wachowskis', synopsis: 'A hacker discovers reality is a simulation.'),
  Movie(title: 'Inception', genre: 'Sci-Fi', year: 2010, rating: 8.8, director: 'Christopher Nolan', synopsis: 'A thief enters dreams to plant ideas.'),
  Movie(title: 'The Shawshank Redemption', genre: 'Drama', year: 1994, rating: 9.3, director: 'Frank Darabont', synopsis: 'Two imprisoned men bond over years.'),
  Movie(title: 'Pulp Fiction', genre: 'Crime', year: 1994, rating: 8.9, director: 'Quentin Tarantino', synopsis: 'Interwoven tales of crime in LA.'),
  Movie(title: 'The Dark Knight', genre: 'Action', year: 2008, rating: 9.0, director: 'Christopher Nolan', synopsis: 'Batman faces the Joker in Gotham.'),
  Movie(title: 'Forrest Gump', genre: 'Drama', year: 1994, rating: 8.8, director: 'Robert Zemeckis', synopsis: 'A simple man witnesses historic events.'),
  Movie(title: 'Spirited Away', genre: 'Animation', year: 2001, rating: 8.6, director: 'Hayao Miyazaki', synopsis: 'A girl enters a spirit world.'),
  Movie(title: 'Parasite', genre: 'Thriller', year: 2019, rating: 8.5, director: 'Bong Joon-ho', synopsis: 'A poor family infiltrates a rich household.'),
];

class MovieHome extends StatefulWidget {
  const MovieHome({super.key});
  @override
  State<MovieHome> createState() => _MovieHomeState();
}

class _MovieHomeState extends State<MovieHome> {
  String _searchQuery = '';
  String _genreFilter = 'All';
  String _sortBy = 'Title';

  List<Movie> get _filtered {
    var list = _allMovies.where((m) {
      final matchesSearch = m.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGenre = _genreFilter == 'All' || m.genre == _genreFilter;
      return matchesSearch && matchesGenre;
    }).toList();
    switch (_sortBy) {
      case 'Rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Year':
        list.sort((a, b) => b.year.compareTo(a.year));
        break;
      default:
        list.sort((a, b) => a.title.compareTo(b.title));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final genres = ['All', ...{..._allMovies.map((m) => m.genre)}..remove('All')];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'Watchlist',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => WatchlistPage(
                  movies: _allMovies.where((m) => m.inWatchlist).toList(),
                ))),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => ['Title', 'Rating', 'Year'].map((s) =>
                PopupMenuItem(value: s, child: Text('Sort by $s'))).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search movies',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: genres.map((g) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: FilterChip(
                  label: Text(g),
                  selected: _genreFilter == g,
                  onSelected: (_) => setState(() => _genreFilter = g),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No movies found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final movie = _filtered[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(movie.rating.toString())),
                        title: Text(movie.title),
                        subtitle: Text('${movie.genre} · ${movie.year}'),
                        trailing: IconButton(
                          icon: Icon(movie.inWatchlist ? Icons.bookmark : Icons.bookmark_border),
                          tooltip: movie.inWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
                          onPressed: () => setState(() => movie.inWatchlist = !movie.inWatchlist),
                        ),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie))),
                      );
                    },
                  ),
          ),
        ],
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
      appBar: AppBar(title: Text(movie.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(movie.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(movie.genre)),
                const SizedBox(width: 8),
                Chip(label: Text('${movie.year}')),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                  label: Text(movie.rating.toString()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Directed by ${movie.director}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(movie.synopsis, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class WatchlistPage extends StatelessWidget {
  final List<Movie> movies;
  const WatchlistPage({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Watchlist')),
      body: movies.isEmpty
          ? const Center(child: Text('No movies in watchlist'))
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (_, i) {
                final m = movies[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(m.rating.toString())),
                  title: Text(m.title),
                  subtitle: Text('${m.genre} · ${m.year}'),
                );
              },
            ),
    );
  }
}
