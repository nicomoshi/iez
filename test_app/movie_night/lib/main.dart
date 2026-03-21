import 'package:flutter/material.dart';

void main() {
  runApp(const MovieNightApp());
}

class Movie {
  String title;
  String director;
  String genre;
  int year;
  int rating;
  String review;
  bool watched;

  Movie({
    required this.title,
    required this.director,
    required this.genre,
    required this.year,
    required this.rating,
    required this.review,
    required this.watched,
  });

  String get starRating {
    return '★' * rating + '☆' * (5 - rating);
  }
}

class MovieNightApp extends StatelessWidget {
  const MovieNightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Night',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
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
  final List<String> _genres = [
    'All',
    'Action',
    'Comedy',
    'Drama',
    'Horror',
    'Sci-Fi',
    'Romance',
  ];

  String _selectedGenre = 'All';

  final List<Movie> _movies = [
    Movie(
      title: 'The Dark Knight',
      director: 'Christopher Nolan',
      genre: 'Action',
      year: 2008,
      rating: 5,
      review:
          'A masterpiece of superhero cinema with an iconic villain performance.',
      watched: true,
    ),
    Movie(
      title: 'The Grand Budapest Hotel',
      director: 'Wes Anderson',
      genre: 'Comedy',
      year: 2014,
      rating: 4,
      review: 'Quirky and visually stunning with a charming ensemble cast.',
      watched: true,
    ),
    Movie(
      title: 'The Shawshank Redemption',
      director: 'Frank Darabont',
      genre: 'Drama',
      year: 1994,
      rating: 5,
      review:
          'A timeless story of hope and perseverance behind prison walls.',
      watched: true,
    ),
    Movie(
      title: 'Hereditary',
      director: 'Ari Aster',
      genre: 'Horror',
      year: 2018,
      rating: 4,
      review:
          'A deeply unsettling family drama that descends into pure terror.',
      watched: false,
    ),
    Movie(
      title: 'Blade Runner 2049',
      director: 'Denis Villeneuve',
      genre: 'Sci-Fi',
      year: 2017,
      rating: 5,
      review:
          'A visually breathtaking sequel that honors the original while standing on its own.',
      watched: false,
    ),
    Movie(
      title: 'Before Sunrise',
      director: 'Richard Linklater',
      genre: 'Romance',
      year: 1995,
      rating: 4,
      review:
          'A beautifully simple film about connection and fleeting moments.',
      watched: true,
    ),
  ];

  List<Movie> get _filteredMovies {
    if (_selectedGenre == 'All') return _movies;
    return _movies.where((m) => m.genre == _selectedGenre).toList();
  }

  void _addMovie(Movie movie) {
    setState(() {
      _movies.add(movie);
    });
  }

  void _deleteMovie(Movie movie) {
    setState(() {
      _movies.remove(movie);
    });
  }

  void _toggleWatched(Movie movie) {
    setState(() {
      movie.watched = !movie.watched;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMovies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Night'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'stats') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WatchlistStatsScreen(movies: _movies),
                  ),
                );
              } else if (value == 'directors') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DirectorsScreen(movies: _movies),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats',
                child: Text('Watchlist Stats'),
              ),
              const PopupMenuItem(
                value: 'directors',
                child: Text('Directors'),
              ),
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
              children: _genres.map((genre) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(genre),
                    selected: _selectedGenre == genre,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGenre = genre;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No movies found'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final movie = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(movie.title),
                          subtitle: Text(movie.director),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                movie.starRating,
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (movie.watched) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                              ],
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                  movie: movie,
                                  onToggleWatched: () =>
                                      _toggleWatched(movie),
                                  onDelete: () => _deleteMovie(movie),
                                ),
                              ),
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
          final movie = await Navigator.push<Movie>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMovieScreen(),
            ),
          );
          if (movie != null) {
            _addMovie(movie);
          }
        },
        label: const Text('Add Movie'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final Movie movie;
  final VoidCallback onToggleWatched;
  final VoidCallback onDelete;

  const DetailScreen({
    super.key,
    required this.movie,
    required this.onToggleWatched,
    required this.onDelete,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movie.title,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              movie.director,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text(movie.genre)),
                const SizedBox(width: 12),
                Text(
                  '${movie.year}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              movie.starRating,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 16),
            Text(
              movie.review,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  movie.watched
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: movie.watched ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(movie.watched ? 'Watched' : 'Unwatched'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.onToggleWatched();
                    setState(() {});
                  },
                  child: const Text('Toggle Watched'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onDelete();
                    Navigator.pop(context);
                  },
                  child: const Text('Delete Movie'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _directorController = TextEditingController();
  final _yearController = TextEditingController();
  final _reviewController = TextEditingController();
  String _genre = 'Action';
  double _rating = 3;

  final List<String> _genres = [
    'Action',
    'Comedy',
    'Drama',
    'Horror',
    'Sci-Fi',
    'Romance',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _directorController.dispose();
    _yearController.dispose();
    _reviewController.dispose();
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Movie Title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _directorController,
                decoration: const InputDecoration(
                  labelText: 'Director',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a director';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a year';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _genre,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                ),
                items: _genres.map((genre) {
                  return DropdownMenuItem(
                    value: genre,
                    child: Text(genre),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _genre = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Rating: ${_rating.round()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final movie = Movie(
                      title: _titleController.text,
                      director: _directorController.text,
                      genre: _genre,
                      year: int.parse(_yearController.text),
                      rating: _rating.round(),
                      review: _reviewController.text,
                      watched: false,
                    );
                    Navigator.pop(context, movie);
                  }
                },
                child: const Text('Add Movie'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WatchlistStatsScreen extends StatelessWidget {
  final List<Movie> movies;

  const WatchlistStatsScreen({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    final total = movies.length;
    final watched = movies.where((m) => m.watched).length;
    final unwatched = total - watched;
    final avgRating = total > 0
        ? (movies.fold<int>(0, (sum, m) => sum + m.rating) / total)
            .toStringAsFixed(1)
        : '0.0';

    final genreCounts = <String, int>{};
    for (final movie in movies) {
      genreCounts[movie.genre] = (genreCounts[movie.genre] ?? 0) + 1;
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist Stats'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Total Movies'),
                    trailing:
                        Text('$total', style: theme.textTheme.titleMedium),
                  ),
                  ListTile(
                    title: const Text('Watched'),
                    trailing:
                        Text('$watched', style: theme.textTheme.titleMedium),
                  ),
                  ListTile(
                    title: const Text('Unwatched'),
                    trailing: Text('$unwatched',
                        style: theme.textTheme.titleMedium),
                  ),
                  ListTile(
                    title: const Text('Average Rating'),
                    trailing: Text(avgRating,
                        style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Genre Breakdown',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...genreCounts.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      trailing: Text('${entry.value}',
                          style: theme.textTheme.titleMedium),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DirectorsScreen extends StatelessWidget {
  final List<Movie> movies;

  const DirectorsScreen({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    final directorCounts = <String, int>{};
    for (final movie in movies) {
      directorCounts[movie.director] =
          (directorCounts[movie.director] ?? 0) + 1;
    }

    final directors = directorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directors'),
      ),
      body: ListView.builder(
        itemCount: directors.length,
        itemBuilder: (context, index) {
          final entry = directors[index];
          return ListTile(
            title: Text(entry.key),
            trailing: Text(
              '${entry.value} ${entry.value == 1 ? 'movie' : 'movies'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
      ),
    );
  }
}
