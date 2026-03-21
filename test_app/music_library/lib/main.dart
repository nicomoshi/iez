import 'package:flutter/material.dart';

void main() {
  runApp(const MusicLibraryApp());
}

// --- Data Models ---

class Song {
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String genre;

  const Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.genre,
  });
}

class Album {
  final String name;
  final String artist;
  final int year;
  final int songCount;

  const Album({
    required this.name,
    required this.artist,
    required this.year,
    required this.songCount,
  });
}

class Playlist {
  final String name;
  final int songCount;
  final int totalMinutes;

  const Playlist({
    required this.name,
    required this.songCount,
    required this.totalMinutes,
  });
}

// --- Data ---

const List<Song> allSongs = [
  Song(title: 'Bohemian Rhapsody', artist: 'Queen', album: 'A Night at the Opera', duration: '5:55', genre: 'Rock'),
  Song(title: 'Billie Jean', artist: 'Michael Jackson', album: 'Thriller', duration: '4:54', genre: 'Pop'),
  Song(title: 'Hotel California', artist: 'Eagles', album: 'Hotel California', duration: '6:30', genre: 'Rock'),
  Song(title: 'Imagine', artist: 'John Lennon', album: 'Imagine', duration: '3:07', genre: 'Pop'),
  Song(title: 'Smells Like Teen Spirit', artist: 'Nirvana', album: 'Nevermind', duration: '5:01', genre: 'Grunge'),
  Song(title: 'Sweet Child O Mine', artist: 'Guns N Roses', album: 'Appetite', duration: '5:56', genre: 'Rock'),
];

const List<Album> allAlbums = [
  Album(name: 'A Night at the Opera', artist: 'Queen', year: 1975, songCount: 6),
  Album(name: 'Thriller', artist: 'Michael Jackson', year: 1982, songCount: 9),
  Album(name: 'Nevermind', artist: 'Nirvana', year: 1991, songCount: 12),
];

final List<Playlist> allPlaylists = [
  const Playlist(name: 'Road Trip', songCount: 4, totalMinutes: 22),
  const Playlist(name: 'Workout', songCount: 3, totalMinutes: 15),
];

// --- App ---

class MusicLibraryApp extends StatelessWidget {
  const MusicLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Library',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const SongsTab(),
    const AlbumsTab(),
    const PlaylistsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'equalizer') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EqualizerScreen()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'equalizer',
                child: Text('Equalizer'),
              ),
            ],
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePlaylistScreen()));
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Songs'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Albums'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Playlists'),
        ],
      ),
    );
  }
}

// --- Songs Tab ---

class SongsTab extends StatelessWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: allSongs.length,
      itemBuilder: (context, index) {
        final song = allSongs[index];
        return ListTile(
          title: Text(song.title),
          subtitle: Text(song.artist),
          trailing: Text(song.duration),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)));
          },
        );
      },
    );
  }
}

// --- Albums Tab ---

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: allAlbums.length,
      itemBuilder: (context, index) {
        final album = allAlbums[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album)));
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.album, size: 64, color: Colors.deepPurple.shade200),
                  const SizedBox(height: 8),
                  Text(album.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(album.artist, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text('${album.year} · ${album.songCount} songs', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Playlists Tab ---

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: allPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = allPlaylists[index];
        return ListTile(
          leading: const Icon(Icons.playlist_play),
          title: Text(playlist.name),
          subtitle: Text('${playlist.songCount} songs · ${playlist.totalMinutes} min'),
        );
      },
    );
  }
}

// --- Song Detail Screen ---

class SongDetailScreen extends StatelessWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song Details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(song.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(song.artist, style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            Text('Album: ${song.album}'),
            const SizedBox(height: 8),
            Text('Duration: ${song.duration}'),
            const SizedBox(height: 8),
            Text('Genre: ${song.genre}'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${song.title} added to playlist')),
                );
              },
              child: const Text('Add to Playlist'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Album Detail Screen ---

class AlbumDetailScreen extends StatelessWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final tracks = List.generate(album.songCount, (i) => 'Track ${i + 1}');

    return Scaffold(
      appBar: AppBar(title: const Text('Album Details')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(album.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(album.artist, style: TextStyle(fontSize: 18, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text('${album.year} · ${album.songCount} songs', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text('${index + 1}', style: TextStyle(color: Colors.grey.shade500)),
                  title: Text(tracks[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Create Playlist Screen ---

class CreatePlaylistScreen extends StatelessWidget {
  const CreatePlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Playlist')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist saved')),
                );
                Navigator.pop(context);
              },
              child: const Text('Save Playlist'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Equalizer Screen ---

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  String _selectedPreset = 'Flat';
  final List<String> _presets = ['Flat', 'Rock', 'Pop', 'Jazz', 'Classical'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _presets.map((preset) {
                return ChoiceChip(
                  label: Text(preset),
                  selected: _selectedPreset == preset,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPreset = preset);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
