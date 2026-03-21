import 'package:flutter/material.dart';

void main() => runApp(const MusicDiaryApp());

// --- Data Model ---

enum Genre { rock, pop, jazz, classical, hiphop, electronic, folk }

extension GenreExt on Genre {
  String get label {
    switch (this) {
      case Genre.rock: return 'Rock';
      case Genre.pop: return 'Pop';
      case Genre.jazz: return 'Jazz';
      case Genre.classical: return 'Classical';
      case Genre.hiphop: return 'Hip-Hop';
      case Genre.electronic: return 'Electronic';
      case Genre.folk: return 'Folk';
    }
  }
}

class Album {
  final String id;
  final String title;
  final String artist;
  final Genre genre;
  final int year;
  final int rating;
  final String thoughts;
  final DateTime listenedDate;
  bool isLiked;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.year,
    required this.rating,
    required this.thoughts,
    required this.listenedDate,
    this.isLiked = false,
  });

  String get stars => '★' * rating + '☆' * (5 - rating);
}

// --- App State ---

class DiaryStore extends ChangeNotifier {
  final List<Album> _albums = _seedAlbums();

  List<Album> get albums => List.unmodifiable(_albums);
  List<Album> get liked => _albums.where((a) => a.isLiked).toList();

  void add(Album a) {
    _albums.insert(0, a);
    notifyListeners();
  }

  void remove(String id) {
    _albums.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void toggleLike(String id) {
    final a = _albums.firstWhere((a) => a.id == id);
    a.isLiked = !a.isLiked;
    notifyListeners();
  }

  static List<Album> _seedAlbums() {
    return [
      Album(id: '1', title: 'OK Computer', artist: 'Radiohead', genre: Genre.rock,
          year: 1997, rating: 5, thoughts: 'A masterpiece of alternative rock.', listenedDate: DateTime(2026, 3, 20), isLiked: true),
      Album(id: '2', title: 'Kind of Blue', artist: 'Miles Davis', genre: Genre.jazz,
          year: 1959, rating: 5, thoughts: 'The quintessential jazz album.', listenedDate: DateTime(2026, 3, 18), isLiked: true),
      Album(id: '3', title: 'Random Access Memories', artist: 'Daft Punk', genre: Genre.electronic,
          year: 2013, rating: 4, thoughts: 'Incredible production and grooves.', listenedDate: DateTime(2026, 3, 15)),
      Album(id: '4', title: 'folklore', artist: 'Taylor Swift', genre: Genre.folk,
          year: 2020, rating: 4, thoughts: 'Surprisingly intimate and poetic.', listenedDate: DateTime(2026, 3, 12)),
      Album(id: '5', title: 'To Pimp a Butterfly', artist: 'Kendrick Lamar', genre: Genre.hiphop,
          year: 2015, rating: 5, thoughts: 'A cultural landmark in hip-hop.', listenedDate: DateTime(2026, 3, 10), isLiked: true),
      Album(id: '6', title: 'Goldberg Variations', artist: 'Glenn Gould', genre: Genre.classical,
          year: 1981, rating: 5, thoughts: 'Bach interpreted with genius precision.', listenedDate: DateTime(2026, 3, 8)),
    ];
  }
}

final DiaryStore _globalStore = DiaryStore();

// --- App Root ---

class MusicDiaryApp extends StatelessWidget {
  const MusicDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Diary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
      home: MainScreen(store: _globalStore),
    );
  }
}

// --- Main Screen ---

class MainScreen extends StatefulWidget {
  final DiaryStore store;
  const MainScreen({super.key, required this.store});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = [
      AlbumListPage(store: widget.store),
      LikedPage(store: widget.store),
      StatsPage(store: widget.store),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.album), label: 'Albums'),
          NavigationDestination(icon: Icon(Icons.thumb_up), label: 'Liked'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

// --- Album List Page ---

class AlbumListPage extends StatefulWidget {
  final DiaryStore store;
  const AlbumListPage({super.key, required this.store});

  @override
  State<AlbumListPage> createState() => _AlbumListPageState();
}

class _AlbumListPageState extends State<AlbumListPage> {
  String _genreFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final genres = ['All', ...Genre.values.map((g) => g.label)];
    final albums = _genreFilter == 'All'
        ? widget.store.albums
        : widget.store.albums.where((a) => a.genre.label == _genreFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Diary'),
        actions: [
          IconButton(tooltip: 'Search', icon: const Icon(Icons.search), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(store: widget.store)));
          }),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: genres.map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(label: Text(g), selected: _genreFilter == g,
                    onSelected: (_) => setState(() => _genreFilter = g)),
              )).toList(),
            ),
          ),
          Expanded(
            child: albums.isEmpty
                ? const Center(child: Text('No albums found.'))
                : ListView.builder(
                    itemCount: albums.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final a = albums[index];
                      return Card(
                        child: ListTile(
                          title: Text(a.title),
                          subtitle: Text('${a.artist} • ${a.year}'),
                          trailing: Text(a.stars, style: const TextStyle(fontSize: 12)),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AlbumDetailPage(album: a, store: widget.store))),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => AddAlbumPage(store: widget.store))),
        label: const Text('Add Album'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- Liked Page ---

class LikedPage extends StatelessWidget {
  final DiaryStore store;
  const LikedPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final liked = store.liked;
    return Scaffold(
      appBar: AppBar(title: const Text('Liked Albums')),
      body: liked.isEmpty
          ? const Center(child: Text('No liked albums yet.'))
          : ListView.builder(
              itemCount: liked.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final a = liked[index];
                return Card(
                  child: ListTile(
                    title: Text(a.title),
                    subtitle: Text(a.artist),
                    trailing: const Icon(Icons.thumb_up, color: Colors.purple),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AlbumDetailPage(album: a, store: store))),
                  ),
                );
              },
            ),
    );
  }
}

// --- Stats Page ---

class StatsPage extends StatelessWidget {
  final DiaryStore store;
  const StatsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final albums = store.albums;
    final total = albums.length;
    final liked = albums.where((a) => a.isLiked).length;
    final avgRating = total > 0
        ? (albums.fold<int>(0, (s, a) => s + a.rating) / total).toStringAsFixed(1)
        : '0.0';

    final genreCounts = <String, int>{};
    for (final a in albums) {
      genreCounts[a.genre.label] = (genreCounts[a.genre.label] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(title: const Text('Total Albums'), trailing: Text('$total')),
          ListTile(title: const Text('Liked'), trailing: Text('$liked')),
          ListTile(title: const Text('Average Rating'), trailing: Text(avgRating)),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('By Genre', style: Theme.of(context).textTheme.titleMedium),
          ),
          ...genreCounts.entries.map((e) => ListTile(title: Text(e.key), trailing: Text('${e.value}'))),
        ],
      ),
    );
  }
}

// --- Search Page ---

class SearchPage extends StatefulWidget {
  final DiaryStore store;
  const SearchPage({super.key, required this.store});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  List<Album> _results = [];

  void _search(String q) {
    setState(() {
      if (q.isEmpty) { _results = []; return; }
      final lq = q.toLowerCase();
      _results = widget.store.albums.where((a) =>
          a.title.toLowerCase().contains(lq) || a.artist.toLowerCase().contains(lq)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Albums')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Search', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Type to search albums.'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final a = _results[i];
                      return ListTile(title: Text(a.title), subtitle: Text(a.artist),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AlbumDetailPage(album: a, store: widget.store))));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Album Detail Page ---

class AlbumDetailPage extends StatelessWidget {
  final Album album;
  final DiaryStore store;
  const AlbumDetailPage({super.key, required this.album, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Album Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(album.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(album.artist, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Chip(label: Text(album.genre.label)),
              const SizedBox(width: 8),
              Text('${album.year}', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            Text(album.stars, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 16),
            Text('Thoughts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(album.thoughts),
            const SizedBox(height: 16),
            Text('Listened: ${album.listenedDate.month}/${album.listenedDate.day}/${album.listenedDate.year}'),
            const SizedBox(height: 24),
            Row(children: [
              ElevatedButton.icon(
                onPressed: () { store.toggleLike(album.id); Navigator.pop(context); },
                icon: Icon(album.isLiked ? Icons.thumb_down : Icons.thumb_up),
                label: Text(album.isLiked ? 'Unlike' : 'Like'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () { store.remove(album.id); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError),
                child: const Text('Delete'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// --- Add Album Page ---

class AddAlbumPage extends StatefulWidget {
  final DiaryStore store;
  const AddAlbumPage({super.key, required this.store});

  @override
  State<AddAlbumPage> createState() => _AddAlbumPageState();
}

class _AddAlbumPageState extends State<AddAlbumPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _artistCtl = TextEditingController();
  final _yearCtl = TextEditingController();
  final _thoughtsCtl = TextEditingController();
  Genre _genre = Genre.rock;
  double _rating = 3;

  @override
  void dispose() {
    _titleCtl.dispose(); _artistCtl.dispose(); _yearCtl.dispose(); _thoughtsCtl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.add(Album(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtl.text.trim(),
      artist: _artistCtl.text.trim(),
      genre: _genre,
      year: int.tryParse(_yearCtl.text.trim()) ?? 2026,
      rating: _rating.round(),
      thoughts: _thoughtsCtl.text.trim(),
      listenedDate: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Album')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _titleCtl,
                  decoration: const InputDecoration(labelText: 'Album Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _artistCtl,
                  decoration: const InputDecoration(labelText: 'Artist'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _yearCtl,
                  decoration: const InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<Genre>(
                value: _genre,
                decoration: const InputDecoration(labelText: 'Genre'),
                items: Genre.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                onChanged: (v) { if (v != null) setState(() => _genre = v); },
              ),
              const SizedBox(height: 12),
              Text('Rating: ${_rating.round()}', style: Theme.of(context).textTheme.titleMedium),
              Slider(value: _rating, min: 1, max: 5, divisions: 4, label: _rating.round().toString(),
                  onChanged: (v) => setState(() => _rating = v)),
              const SizedBox(height: 12),
              TextFormField(controller: _thoughtsCtl,
                  decoration: const InputDecoration(labelText: 'Thoughts'), maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                  child: ElevatedButton(onPressed: _save, child: const Text('Save Album'))),
            ],
          ),
        ),
      ),
    );
  }
}
